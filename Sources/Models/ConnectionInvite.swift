// Created by Mateus Lino

import Foundation

public struct ConnectionInvite {
    public let deviceName: String
    public let confirmationHandler: () -> Void
    public let cancelHandler: () -> Void

    public init(deviceName: String, confirmationHandler: @escaping () -> Void, cancelHandler: @escaping () -> Void) {
        self.deviceName = deviceName
        self.confirmationHandler = confirmationHandler
        self.cancelHandler = cancelHandler
    }
}
