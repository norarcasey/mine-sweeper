import Foundation
import MineSweeperKit

/// The fastest win at each difficulty, in whole seconds, kept between launches.
/// Only the best is kept: no history, no averages (MINE-23).
///
/// Not a rule, so it lives in the app and not in MineSweeperKit; the component
/// keeps no times.
struct BestTimes {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The best time at `difficulty`, or nil before its first win.
    func seconds(for difficulty: Difficulty) -> Int? {
        defaults.object(forKey: Self.key(difficulty)) as? Int
    }

    /// Keeps `seconds` if it beats the best at `difficulty`, or there is none
    /// yet. True when it did: the win set a new best. A tie is not a new best.
    @discardableResult
    func record(_ seconds: Int, for difficulty: Difficulty) -> Bool {
        if let best = self.seconds(for: difficulty), best <= seconds {
            return false
        }
        defaults.set(seconds, forKey: Self.key(difficulty))
        return true
    }

    private static func key(_ difficulty: Difficulty) -> String {
        "bestTime.\(difficulty.name)"
    }
}
