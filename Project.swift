import Foundation
import ProjectDescription

let targetName = "LookInsideExample"
let uiKitTargetName = "LookInsideExampleUIKit"
let appKitTargetName = "LookInsideExampleAppKit"
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
        requirement: .upToNextMajor(from: "0.2.0")
    )
let serverProduct = usesLocalServer ? "LookinServer" : "LookInsideServer"
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
    ],
    additionalFiles: [
        "Configuration/Base.xcconfig",
    ]
)
