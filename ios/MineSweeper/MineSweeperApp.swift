import MineSweeperKit
import SwiftUI

@main
struct MineSweeperApp: App {
    @State private var model = GameModel(difficulty: .beginner, seed: Self.launchSeed)

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }

    /// `-seed N` on the launch arguments fixes where each game's mines go, so
    /// the UI tests can play a known board. Debug builds only.
    private static var launchSeed: UInt64? {
        #if DEBUG
            guard let value = UserDefaults.standard.string(forKey: "seed") else { return nil }
            return UInt64(value)
        #else
            return nil
        #endif
    }
}
