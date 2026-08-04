import SwiftUI

@main
struct IconCreatorApp: App {
    init() {
        // Skip runtime services (the Nova API network server) when the app is
        // launched as an XCTest host — unit tests must not bind sockets or start
        // background servers, which destabilizes the test host process.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            NovaAPIServer.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
