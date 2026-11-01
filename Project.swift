import Foundation
import ProjectDescription

let targetName = "LookInsideExample"
let uiKitTargetName = "LookInsideExampleUIKit"
let appKitTargetName = "LookInsideExampleAppKit"
let tvTargetName = "LookInsideExampleTV"
let tvUIKitTargetName = "LookInsideExampleTVUIKit"
let watchTargetName = "LookInsideExampleWatch"
let watchKitTargetName = "LookInsideExampleWatchKit"
let localServerPath = Environment.lookinsideServerPath.getString(default: "")
    .trimmingCharacters(in: .whitespacesAndNewlines)

let usesLocalServer = !localServerPath.isEmpty
let localServerPackagePath: ProjectDescription.Path = localServerPath.hasPrefix("/")
    ? .path(localServerPath)
    : .relativeToManifest(localServerPath)
let serverPackage: Package = usesLocalServer
    ? .local(path: localServerPackagePath)
    : .remote(
        url: "https://github.com/LookInsideApp/LookInside-Release.git",
        requirement: .upToNextMajor(from: "1.0.0")
    )
let serverProduct = usesLocalServer ? "LookinServer" : "LookInsideServer"

/// The watch apps cannot build a local Server from its sources: the watchOS
/// SDK marks UIKit unavailable, and only the unlocked copy of it that the
/// Server's packaging script makes compiles the Server. So against a local
/// Server they link the XCFramework that script leaves in the Server's build
/// folder (`make server-watch-framework`), and against the published SDK its
/// binary, like every other app.
let localWatchServerFrameworkRelativePath = "build/LookInsideServer.xcframework"
let localWatchServerFrameworkFullPath = URL(
    fileURLWithPath: localWatchServerFrameworkRelativePath,
    relativeTo: URL(fileURLWithPath: localServerPath, isDirectory: true, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
).standardizedFileURL.path
let localWatchServerFrameworkExists = FileManager.default.fileExists(atPath: localWatchServerFrameworkFullPath)
let watchServerDependencies: [TargetDependency] = if !usesLocalServer {
    [.package(product: "LookInsideServer")]
} else if localWatchServerFrameworkExists {
    [.xcframework(path: .path(localWatchServerFrameworkFullPath))]
} else {
    []
}

/// Without the framework a watch app would build and run but never be
/// inspectable, so its build fails and says what to run.
let watchServerScripts: [TargetScript] = usesLocalServer && !localWatchServerFrameworkExists
    ? [
        .pre(
            script: "echo \"error: Run 'make server-watch-framework', then 'make generate': the watch apps link the local Server as \(localWatchServerFrameworkFullPath).\" >&2; exit 1",
            name: "Require the local watchOS Server framework",
            basedOnDependencyAnalysis: false
        ),
    ]
    : []
let configurations: [Configuration] = [
    .debug(name: "Debug", xcconfig: "Configuration/Development.xcconfig"),
    .release(name: "Release", xcconfig: "Configuration/Release.xcconfig"),
]
let xcconfigManagedSettings: Set<String> = [
    "CODE_SIGN_IDENTITY",
    "CODE_SIGN_STYLE",
    "CODE_SIGNING_ALLOWED",
    "CODE_SIGNING_REQUIRED",
    "CODE_SIGNING_SUPPORTED",
    "DEBUG_INFORMATION_FORMAT",
    "DEVELOPMENT_TEAM",
    "ENABLE_NS_ASSERTIONS",
    "ENABLE_TESTABILITY",
    "ENABLE_USER_SCRIPT_SANDBOXING",
    "IPHONEOS_DEPLOYMENT_TARGET",
    "ONLY_ACTIVE_ARCH",
    "PROVISIONING_PROFILE_SPECIFIER",
    "SDKROOT",
    "SUPPORTS_MACCATALYST",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
    "SWIFT_COMPILATION_MODE",
    "SWIFT_OPTIMIZATION_LEVEL",
    "SWIFT_VERSION",
    "TARGETED_DEVICE_FAMILY",
]

let project = Project(
    name: targetName,
    organizationName: "LookInside",
    // The WatchKit app's storyboard is its only resource; WatchKit loads it
    // by name, so no generated accessors under Derived/.
    options: .options(disableBundleAccessors: true, disableSynthesizedResourceAccessors: true),
    packages: [
        serverPackage,
    ],
    settings: .settings(
        configurations: configurations,
        defaultSettings: .recommended(excluding: xcconfigManagedSettings),
        defaultConfiguration: "Debug"
    ),
    targets: [
        .target(
            name: targetName,
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            productName: targetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_BUNDLE_ID)",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleApp/Info.plist"),
            sources: [
                "Sources/LookInsideExampleApp/**/*.swift",
                "Sources/DemoShared/LookInsideServerRuntime.swift",
            ],
            dependencies: [
                .package(product: serverProduct),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
        .target(
            name: uiKitTargetName,
            destinations: [.iPhone, .iPad],
            product: .app,
            productName: uiKitTargetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_UIKIT_BUNDLE_ID)",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleUIKit/Info.plist"),
            sources: [
                "Sources/LookInsideExampleUIKit/**/*.swift",
                "Sources/DemoShared/**/*.swift",
            ],
            dependencies: [
                .package(product: serverProduct),
            ],
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
        .target(
            name: appKitTargetName,
            destinations: [.mac],
            product: .app,
            productName: appKitTargetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_APPKIT_BUNDLE_ID)",
            // Matches the minimum the prebuilt LookInsideServer.framework is
            // built for; anything lower links with a version warning.
            deploymentTargets: .macOS("14.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleAppKit/Info.plist"),
            sources: [
                "Sources/LookInsideExampleAppKit/**/*.swift",
                "Sources/DemoShared/**/*.swift",
            ],
            dependencies: [
                .package(product: serverProduct),
            ],
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/../Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
        .target(
            name: tvTargetName,
            destinations: [.appleTv],
            product: .app,
            productName: tvTargetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_TV_BUNDLE_ID)",
            deploymentTargets: .tvOS("17.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleTV/Info.plist"),
            sources: [
                "Sources/LookInsideExampleTV/**/*.swift",
                "Sources/DemoShared/**/*.swift",
            ],
            dependencies: [
                .package(product: serverProduct),
            ],
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
        .target(
            name: tvUIKitTargetName,
            destinations: [.appleTv],
            product: .app,
            productName: tvUIKitTargetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_TV_UIKIT_BUNDLE_ID)",
            deploymentTargets: .tvOS("17.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleTVUIKit/Info.plist"),
            sources: [
                "Sources/LookInsideExampleTVUIKit/**/*.swift",
                "Sources/DemoShared/**/*.swift",
            ],
            dependencies: [
                .package(product: serverProduct),
            ],
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
        .target(
            name: watchTargetName,
            destinations: [.appleWatch],
            product: .app,
            productName: watchTargetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_WATCH_BUNDLE_ID)",
            // The Server's watchOS minimum; it only listens from watchOS 26 on.
            deploymentTargets: .watchOS("10.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleWatch/Info.plist"),
            sources: [
                "Sources/LookInsideExampleWatch/**/*.swift",
                "Sources/DemoShared/**/*.swift",
            ],
            scripts: watchServerScripts,
            dependencies: watchServerDependencies,
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
        .target(
            name: watchKitTargetName,
            destinations: [.appleWatch],
            product: .app,
            productName: watchKitTargetName,
            bundleId: "$(LOOKINSIDE_EXAMPLE_WATCHKIT_BUNDLE_ID)",
            deploymentTargets: .watchOS("10.0"),
            infoPlist: .file(path: "Sources/LookInsideExampleWatchKit/Info.plist"),
            sources: [
                "Sources/LookInsideExampleWatchKit/**/*.swift",
                "Sources/DemoShared/**/*.swift",
            ],
            resources: [
                "Sources/LookInsideExampleWatchKit/Interface.storyboard",
            ],
            scripts: watchServerScripts,
            dependencies: watchServerDependencies,
            settings: .settings(
                base: [
                    "LD_RUNPATH_SEARCH_PATHS": [
                        "$(inherited)",
                        "@executable_path/Frameworks",
                    ],
                ],
                configurations: configurations,
                defaultSettings: .recommended(excluding: xcconfigManagedSettings)
            )
        ),
    ],
    schemes: [
        .scheme(
            name: targetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(targetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(targetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: uiKitTargetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(uiKitTargetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(uiKitTargetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: appKitTargetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(appKitTargetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(appKitTargetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: tvTargetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(tvTargetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(tvTargetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: tvUIKitTargetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(tvUIKitTargetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(tvUIKitTargetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: watchTargetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(watchTargetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(watchTargetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
        .scheme(
            name: watchKitTargetName,
            shared: true,
            buildAction: .buildAction(targets: [.target(watchKitTargetName)]),
            runAction: .runAction(configuration: "Debug", executable: .target(watchKitTargetName)),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ],
    additionalFiles: [
        "Configuration/Base.xcconfig",
    ]
)
