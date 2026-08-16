import Foundation

/// A platform-independent colour name used by the demo data.
///
/// The shared model layer stays free of UIKit and AppKit so both native
/// example apps can compile the exact same fixtures; each app maps these
/// cases onto `UIColor` / `NSColor` in its own `Support` folder.
enum DemoTint: String, CaseIterable, Hashable {
    case blue
    case purple
    case pink
    case orange
    case green
    case teal
    case indigo
    case mint
    case cyan
    case black

    static func deterministicTint(for seed: String) -> DemoTint {
        let scalarSum = seed.unicodeScalars.reduce(0) { partialSum, scalar in
            partialSum &+ Int(scalar.value)
        }
        let selectable = DemoTint.allCases.filter { $0 != .black }
        return selectable[scalarSum % selectable.count]
    }
}
