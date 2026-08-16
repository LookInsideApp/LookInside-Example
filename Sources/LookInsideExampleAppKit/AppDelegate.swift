import AppKit

@main
@MainActor
enum App {
    static func main() {
        NSApplication.shared.delegate = AppDelegate.shared
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()

    private var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        print("[LookInsideExampleAppKit] launched; LookInsideServer.isLicensed=\(LookInsideServerRuntime.isLicensed)")

        // No nib, no storyboard: the menu bar is built in code, otherwise the
        // app ships without even a Quit command.
        NSApplication.shared.mainMenu = MainMenuBuilder.makeMainMenu()

        let windowController = MainWindowController()
        windowController.showWindow(nil)
        mainWindowController = windowController

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }
}
