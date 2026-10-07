import AppKit

/// Owns the single window and its toolbar.
final class MainWindowController: NSWindowController {
    private let rootSplitViewController = RootSplitViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // The title tracks the selected screen; the root split view controller
        // keeps it in sync.
        window.title = DemoDestination.welcome.title
        window.titlebarAppearsTransparent = false
        window.contentMinSize = NSSize(width: 860, height: 560)

        super.init(window: window)

        // Assigning a content view controller resizes the window to the
        // controller's fitting size, so the default size is applied after it,
        // and a saved frame (if any) is restored last.
        window.contentViewController = rootSplitViewController
        window.setContentSize(NSSize(width: 1100, height: 740))
        window.center()
        window.setFrameAutosaveName("LookInsideExampleAppKitWindow")

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

extension MainWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    /// Every item is a system-provided one: the sidebar toggle, the separator
    /// that keeps the title aligned with the detail pane, and a flexible
    /// space. AppKit builds those itself.
    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier _: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        nil
    }
}
