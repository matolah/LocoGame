// Created by Mateus Lino

import Foundation

public enum GameWorkerKind {
    case host
    case participant
}

public protocol GameWorkerProtocol {
    init(connectionManager: ConnectionManagerProtocol, kind: GameWorkerKind, data: Data?) throws
    func dataReceived(_ data: Data)
}
