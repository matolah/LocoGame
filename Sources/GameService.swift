// Created by Mateus Lino

import Combine
import Foundation
import MultipeerConnectivity

public protocol GameServiceProtocol {
    var connectedPeers: [Peer] { get }
    var outputSubject: PassthroughSubject<GameOutput, Never> { get }
    func browseSessions()
    func hostSession()
    func invite(peer: MCPeerID)
    func leaveSession()
    func send(message: PeerMessage) throws
    func send(message: GameMessage) throws
    func startGame(withData data: Data?) throws
}

public enum GameOutput {
    case hostsChanged([MCPeerID])
    case inviteReceived(ConnectionInvite)
    case peerMessageReceived(PeerMessage)
}

open class GameService: ObservableObject, GameServiceProtocol {
    private let connectionManager: ConnectionManagerProtocol
    private let gameWorkerBuilder: GameWorkerBuilderProtocol

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()

    open private(set) var gameWorker: GameWorkerProtocol?

    public let outputSubject = PassthroughSubject<GameOutput, Never>()

    public var connectedPeers: [Peer] {
        return connectionManager.connectedPeers
    }

    @Published public var hasStartedGame = false

    public init(connectionManager: ConnectionManagerProtocol, gameWorkerBuilder: GameWorkerBuilderProtocol) {
        self.connectionManager = connectionManager
        self.gameWorkerBuilder = gameWorkerBuilder

        connectionManager.outputSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] output in
                guard let self else {
                    return
                }

                switch output {
                case .dataReceived(let data):
                    guard let gameMessage = try? decoder.decode(GameMessage.self, from: data) else {
                        return
                    }

                    switch gameMessage {
                    case .startedGame(let data):
                        self.hasStartedGame = true

                        try? initializeWorker(using: connectionManager, kind: .participant, data: data)
                    case .workerDataReceived(let data):
                        self.gameWorker?.dataReceived(data)
                    }
                case .hostsChanged(let hosts):
                    self.outputSubject.send(.hostsChanged(hosts))
                case .inviteReceived(let invite):
                    self.outputSubject.send(.inviteReceived(invite))
                case .messageReceived(let peerMessage):
                    self.outputSubject.send(.peerMessageReceived(peerMessage))
                }
            }
            .store(in: &cancellables)
    }

    private func initializeWorker(
        using connectionManager: ConnectionManagerProtocol,
        kind: GameWorkerKind,
        data: Data?
    ) throws {
        let gameWorker = try gameWorkerBuilder.gameWorker(
            ofKind: kind,
            from: data,
            connectionManager: connectionManager
        )
        self.gameWorker = gameWorker
    }

    public func browseSessions() {
        connectionManager.browseSessions()
    }

    public func hostSession() {
        connectionManager.hostSession()
    }

    public func invite(peer: MCPeerID) {
        connectionManager.invite(peer: peer)
    }

    public func leaveSession() {
        connectionManager.leaveSession()
    }

    public func send(message: PeerMessage) throws {
        try connectionManager.send(message: message)
    }

    public func send(message: GameMessage) throws {
        guard let data = try? JSONEncoder().encode(message) else {
            return
        }

        try connectionManager.send(data: data)
    }

    public func startGame(withData data: Data?) throws {
        hasStartedGame = true

        try initializeWorker(using: connectionManager, kind: .host, data: data)
    }
}
