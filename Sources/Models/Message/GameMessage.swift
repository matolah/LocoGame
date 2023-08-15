// Created by Mateus Lino

import Foundation

public enum GameMessage: Codable {
    case startedGame(Data)
    case workerDataReceived(Data)
}
