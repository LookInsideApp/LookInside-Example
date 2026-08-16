import AppKit

/// Owns the single window and its toolbar.
final class MainWindowController: NSWindowController {
    private let rootSplitViewController = RootSplitViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "LookInside AppKit"
        window.titlebarAppearsTransparent = false
        window.contentMinSize = NSSize(width: 820, height: 520)
        window.setFrameAutosaveName("LookInsideExampleAppKitMainWindow")

        super.init(window: window)

        window.contentViewController = rootSplitViewController
        window.center()

        let toolbar = NSToolbar(identifier: "LookInsideExampleAppKitToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NSToolbarItem.Identifier {
    static let toggleSidebar = NSToolbarItem.Identifier("ToggleSidebar")
    static let refreshLicenseState = NSToolbarItem.Identifier("RefreshLicenseState")
}

extension MainWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace, .refreshLicenseState]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .toggleSidebar:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Sidebar"
            item.image = NSImage(systemSymbolName: "sidebar.leading", accessibilityDescription: "Toggle Sidebar")
            item.target = rootSplitViewController
            item.action = #selector(NSSplitViewController.toggleSidebar(_:))
            return item

        case .refreshLicenseState:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Refresh"
            item.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh licence state")
            item.target = rootSplitViewController
            item.action = #selector(RootSplitViewController.refreshLicenseState(_:))
            return item

        default:
            return nil
        }
    }
}
