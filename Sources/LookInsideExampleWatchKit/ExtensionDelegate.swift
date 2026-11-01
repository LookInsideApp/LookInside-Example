import WatchKit

/// The app's delegate. Nothing to set up: the Server starts on its own when
/// the app becomes active, and the storyboard builds the interface.
final class ExtensionDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {}
}
