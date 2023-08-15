// Created by Mateus Lino

import Foundation

public protocol GameWorkerBuilderProtocol {
    func gameWorker(
        ofKind kind: GameWorkerKind,
        from data: Data?,
        connectionManager: ConnectionManagerProtocol
    ) throws -> GameWorkerProtocol
}
