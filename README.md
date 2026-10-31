# LookInside-Example

Ready-to-run demo apps for trying LookInside on iOS, tvOS, and macOS.

Five apps live here. Each opens on a Welcome screen with the setup steps and the live license state, then shows a set of demos. Run one, open LookInside on your Mac, and inspect the live UI.

The iOS and macOS apps show the same three demos — Music, Feed, and Chat — built three different ways. Because the screens match, you can load the SwiftUI app and the native app side by side and compare exactly what each hierarchy looks like in the inspector.

The two Apple TV apps do the same for tvOS: Music and Feed, rebuilt for the remote — rows of focusable cards that scroll sideways — once in SwiftUI and once in UIKit. Chat is left out; nobody types on a TV.

The native apps additionally ship a Controls screen: a gallery of the stock UIKit / AppKit controls — buttons, text inputs, sliders, steppers, progress indicators, pickers, and a card drawn by a bare `CALayer` sublayer — so there is a rich, varied hierarchy to point the inspector at. The tvOS version holds the controls tvOS has.

| App | Platform | Built with |
| --- | -------- | ---------- |
| `LookInsideExample` | iOS + macOS | SwiftUI |
| `LookInsideExampleUIKit` | iOS | UIKit only — no `import SwiftUI` |
| `LookInsideExampleAppKit` | macOS | AppKit only — no `import SwiftUI` |
| `LookInsideExampleTV` | tvOS | SwiftUI |
| `LookInsideExampleTVUIKit` | tvOS | UIKit and TVUIKit only — no `import SwiftUI` |

The native apps are written the long way on purpose: hand-built view controllers, Auto Layout constraints, Core Animation layers, view-based table views, and a code-built menu bar on the Mac. That is the shape most real apps have, and the shape the inspector was built for. The tvOS UIKit app adds compositional collection views and TVUIKit's media item and monogram cells, the building blocks of most Apple TV apps.

## Run it

SwiftUI app:

```bash
make run       # iOS Simulator
make run-mac   # this Mac
```

UIKit app (iOS Simulator):

```bash
make run-uikit
```

AppKit app (this Mac):

```bash
make run-appkit
```

Apple TV apps (Apple TV Simulator):

```bash
make run-tv         # SwiftUI
make run-tv-uikit   # UIKit
```

They use the `Apple TV 4K (3rd generation)` simulator; pick another with `TV_SIMULATOR_NAME="Apple TV" make run-tv`. The tvOS simulator runtime is a separate download in Xcode › Settings › Components.

You can also open `LookInsideExample.xcodeproj` in Xcode, pick a scheme, and press Run.

LookInside finds a running app on its own: over TCP loopback in the iOS and Apple TV Simulators and on this Mac (ports 47164–47169), or over USB on a connected device (ports 47175–47179). The tvOS apps have been checked in the Apple TV Simulator only; an Apple TV has no USB port for LookInside to reach it through.

## Build only

```bash
make build-sim        # SwiftUI app, iOS Simulator
make build-mac        # SwiftUI app, Mac
make build-uikit      # UIKit app
make build-appkit     # AppKit app
make build-tv         # SwiftUI app, Apple TV Simulator
make build-tv-uikit   # UIKit app, Apple TV Simulator
make build-all        # all five
```

Run `make help` for the full target list.

## What is inside

| Path | What it is |
| ---- | ---------- |
| `Sources/LookInsideExampleApp/` | The SwiftUI iOS and macOS app |
| `Sources/LookInsideExampleUIKit/` | The pure-UIKit iOS app |
| `Sources/LookInsideExampleAppKit/` | The pure-AppKit macOS app |
| `Sources/LookInsideExampleTV/` | The SwiftUI tvOS app |
| `Sources/LookInsideExampleTVUIKit/` | The pure-UIKit tvOS app |
| `Sources/DemoShared/` | Demo fixtures shared by the native apps and the tvOS apps, plus the server runtime bridge |
| `LookInsideExample.xcodeproj` | The Xcode project |
| `Project.swift` | Tuist project setup |
| `Configuration/` | Build settings |

LookInside continues the work of [`LookinServer`](https://github.com/QMUI/LookinServer), the original iOS view debugger runtime.

## Sponsor

This project is sponsored by [AirBuild](https://air.build/).
