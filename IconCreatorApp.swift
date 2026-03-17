import SwiftUI

@main
struct IconCreatorApp: App {
    init() {
        NovaAPIServer.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
