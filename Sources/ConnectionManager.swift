// Created by Mateus Lino

import Combine
import MultipeerConnectivity

public protocol ConnectionManagerProtocol {
    var currentPeer: Peer { get }
    var connectedPeers: [Peer] { get }
    var isHosting: Bool { get }
    var outputSubject: PassthroughSubject<ConnectionOutput, Never> { get }
    func browseSessions()
    func hostSession()
    func invite(peer: MCPeerID)
    func leaveSession()
    func send(data: Data) throws
    func send(data: Data, to peer: Peer) throws
    func send(message: PeerMessage) throws
}

public enum ConnectionOutput {
    case dataReceived(Data)
    case hostsChanged([MCPeerID])
    case inviteReceived(ConnectionInvite)
    case messageReceived(PeerMessage)
}

fileprivate enum DiscoveryInfoKey: String {
    case peer
}

public final class ConnectionManager:
    NSObject,
    MCNearbyServiceAdvertiserDelegate,
    MCNearbyServiceBrowserDelegate,
    MCSessionDelegate,
    ConnectionManagerProtocol
{
    private let serviceName: String
    private let currentPeerID: MCPeerID

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public var isHosting = false

    public let currentPeer: Peer
    public var peers = [MCPeerID: Peer]()
    private var inSessionPeers: [MCPeerID: Peer] {
        return peers
            .filter { peer in
                return peer.value.state == .inSession
            }
    }
    public var connectedPeers: [Peer] {
        return inSessionPeers
            .filter { peer in
                return session.connectedPeers.contains(peer.key)
            }
            .map(\.value)
    }

    public let outputSubject = PassthroughSubject<ConnectionOutput, Never>()

    private(set) lazy var session: MCSession = {
        let session = MCSession(peer: currentPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    private lazy var nearbyServiceBrowser: MCNearbyServiceBrowser = {
        let nearbyServiceBrowser = MCNearbyServiceBrowser(peer: currentPeerID, serviceType: serviceName)
        nearbyServiceBrowser.delegate = self
        return nearbyServiceBrowser
    }()

    private lazy var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser = {
        guard let data = try? JSONEncoder().encode(currentPeer) else {
            fatalError("No data for current peer available")
        }
        let dataString = String(decoding: data, as: UTF8.self)
        let nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: currentPeerID,
            discoveryInfo: [DiscoveryInfoKey.peer.rawValue: dataString],
            serviceType: serviceName
        )
        nearbyServiceAdvertiser.delegate = self
        return nearbyServiceAdvertiser
    }()

    public init(serviceName: String, currentPeerID: MCPeerID, currentPeer: Peer) {
        self.serviceName = serviceName
        self.currentPeerID = currentPeerID
        self.currentPeer = currentPeer
    }

    public func browseSessions() {
        nearbyServiceBrowser.startBrowsingForPeers()
    }

    public func hostSession() {
        leaveSession()

        isHosting = true

        nearbyServiceAdvertiser.startAdvertisingPeer()
    }

    public func invite(peer: MCPeerID) {
        guard let data = try? encoder.encode(currentPeer) else {
            return
        }

        nearbyServiceBrowser.invitePeer(peer, to: session, withContext: data, timeout: 120)
    }

    public func leaveSession() {
        let peerMessage: PeerMessage
        if isHosting {
            peerMessage = .sessionEnded
        } else {
            peerMessage = .refreshPeers
        }
        try? sendData(from: peerMessage)

        peers.removeAll()
        isHosting = false

        nearbyServiceAdvertiser.stopAdvertisingPeer()

        nearbyServiceBrowser.stopBrowsingForPeers()
    }

    private func sendData(from message: PeerMessage) throws {
        guard let data = try? encoder.encode(message) else {
            return
        }

        try send(data: data)
    }

    public func send(data: Data) throws {
        guard !inSessionPeers.isEmpty else {
            return
        }
        
        try send(data: data, to: inSessionPeers.map(\.key))
    }

    private func send(data: Data, to peers: [MCPeerID]) throws {
        try session.send(data, toPeers: peers, with: .reliable)
    }

    public func send(data: Data, to peer: Peer) throws {
        let connectedPeer = peers.first { tuple in
            return tuple.value == peer
        }
        guard let peerID = connectedPeer?.key else {
            return
        }
        try send(data: data, to: [peerID])
    }

    public func send(message: PeerMessage) throws {
        guard let data = try? encoder.encode(message) else {
            return
        }

        try send(data: data)
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = try? decoder.decode(PeerMessage.self, from: data) {
            outputSubject.send(.messageReceived(message))
        } else {
            outputSubject.send(.dataReceived(data))
        }
    }

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            guard let peer = peers[peerID] else {
                return
            }

            peer.state = .inSession

            let message = PeerMessage.refreshPeers
            try? sendData(from: message)

            outputSubject.send(.messageReceived(.joinedSession))
        case .connecting:
            break
        case .notConnected:
            break
        @unknown default:
            print("Unknown state: \(state)")
        }
    }

    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}

    public func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let invite = ConnectionInvite(
            deviceName: peerID.displayName
        ) { [invitationHandler, unowned self] in
            invitationHandler(true, self.session)
            guard let context, let peer = try? decoder.decode(Peer.self, from: context) else {
                return
            }

            peer.state = .inSession
            self.peers[peerID] = peer
        } cancelHandler: { [invitationHandler, unowned self] in
            invitationHandler(false, self.session)
        }
        outputSubject.send(.inviteReceived(invite))
    }

    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if peers[peerID] == nil {
            guard let info, let peerString = info[DiscoveryInfoKey.peer.rawValue]?.utf8 else {
                return
            }
            let data = Data(peerString)
            guard let peer = try? decoder.decode(Peer.self, from: data) else {
                return
            }
            peer.state = .discovered
            peers[peerID] = peer

            sendHostsChange()
        }
    }

    private func sendHostsChange() {
        outputSubject.send(.hostsChanged(peers.map(\.key)))
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard peers.removeValue(forKey: peerID) != nil else {
            return
        }

        sendHostsChange()
    }
}
