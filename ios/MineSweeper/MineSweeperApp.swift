import MineSweeperKit
import SwiftUI

@main
struct MineSweeperApp: App {
    @State private var model = GameModel(difficulty: .beginner, seed: Self.launchSeed, bestTimes: Self.bestTimes)

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }

    /// A seeded launch is a test, so it keeps its best times apart from real
    /// play and starts each launch with none: a test's win never sets the best
    /// on the phone, and the store screenshots show the same thing every run.
    private static var bestTimes: BestTimes {
        guard launchSeed != nil, let defaults = UserDefaults(suiteName: "seeded") else { return BestTimes() }
        defaults.removePersistentDomain(forName: "seeded")
        return BestTimes(defaults: defaults)
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
