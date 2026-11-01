import WatchKit

// A storyboard watch app has no SwiftUI App type to start it: WatchKit loads
// Interface.storyboard by itself and reports the launch to the delegate.
exit(WKApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, NSStringFromClass(ExtensionDelegate.self)))
