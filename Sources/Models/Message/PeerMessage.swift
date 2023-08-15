// Created by Mateus Lino

import Foundation

public enum PeerMessage: Codable {
    case joinedSession
    case refreshPeers
    case sessionEnded
}
