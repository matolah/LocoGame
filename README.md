<a name="readme-top"></a>

<div align="center">
  <h3 align="center">LocoGame</h3>

  <p align="center">
    <a href="https://github.com/matolah/taksi-br/taksi-swift/issues">Report Bug</a>
    ·
    <a href="https://github.com/matolah/taksi-br/taksi-swift/issues">Request Feature</a>
  </p>
</div>

LocoGame is a Swift package for managing game sessions between nearby devices.
- [About](#about)
- [Installation](#installation)
- [License](#license)
- [Contact](#contact)

## About

LocoGame simplifies the creation and management of game sessions between nearby devices. It is built on top of [Apple's MultipeerConnectivity framework](https://developer.apple.com/documentation/multipeerconnectivity).

### How it works

LocoGame's core components are:

- `Peer`: a model that contains the information of peers found nearby. It's a friendlier version of `MCPeerID`.
- `PeerMessage`: an enum with all the core messages sent between peers to manage the `MCSession`.
- `ConnectionManager`: manages all the communication between peers. Its main job is to create and maintain `Peer`s from `MCPeerID`s.

`ConnectionManager` has its behavior extended by `GameService`, whose responsibility is to convert the multi-peer session to a game session. Peers can host or join sessions and send `GameMessage`s to one another.

When a game session is created in the `GameService`, a `gameWorker` instance is initialized by `gameWorkerBuilder`. Workers are responsible for encapsulating the business logic of the game mode(s).

## Installation

LocoGame is available for installation via SPM:

```swift
dependencies: [
    .package(name: "LocoGame", url: "https://github.com/matolah/LocoGame", .upToNextMajor(from: "1.0.0")),
],
.target(
    name: "MyApp",
    dependencies: [
      .product(name: "LocoGame", package: "LocoGame")
  ]
)
```

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## Contributors

[@_matolah](https://twitter.com/_matolah)
