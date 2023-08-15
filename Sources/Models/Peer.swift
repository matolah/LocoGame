// Created by Mateus Lino

import Foundation

public final class Peer: Codable, Equatable {
    public enum State: Codable {
        case discovered
        case inSession
        case undiscovered
    }

    public let id: UUID
    public let displayName: String
    public var state: State

    public init(id: UUID, displayName: String, state: State) {
        self.id = id
        self.displayName = displayName
        self.state = state
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func == (lhs: Peer, rhs: Peer) -> Bool {
        return lhs.id == rhs.id
    }
}
