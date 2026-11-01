import UIKit

extension DemoTint {
    /// The dark-appearance system colours; watchOS's UIColor offers none of
    /// the `system…` ones.
    var uiColor: UIColor {
        switch self {
        case .blue: UIColor(red: 10 / 255, green: 132 / 255, blue: 1, alpha: 1)
        case .purple: UIColor(red: 191 / 255, green: 90 / 255, blue: 242 / 255, alpha: 1)
        case .pink: UIColor(red: 1, green: 55 / 255, blue: 95 / 255, alpha: 1)
        case .orange: UIColor(red: 1, green: 159 / 255, blue: 10 / 255, alpha: 1)
        case .green: UIColor(red: 48 / 255, green: 209 / 255, blue: 88 / 255, alpha: 1)
        case .teal: UIColor(red: 64 / 255, green: 200 / 255, blue: 224 / 255, alpha: 1)
        case .indigo: UIColor(red: 94 / 255, green: 92 / 255, blue: 230 / 255, alpha: 1)
        case .mint: UIColor(red: 99 / 255, green: 230 / 255, blue: 226 / 255, alpha: 1)
        case .cyan: UIColor(red: 100 / 255, green: 210 / 255, blue: 1, alpha: 1)
        case .black: .black
        }
    }
}

extension Notification.Name {
    /// Posted by the server whenever its license state changes.
    static let lookInsideServerLicenseStateDidChange = Notification.Name("LookInsideServerLicenseStateDidChangeNotification")
}
