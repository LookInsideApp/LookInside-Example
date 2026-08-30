# LookInside-Example

Ready-to-run demo apps for trying LookInside on iOS and macOS.

Three apps live here, and they all show the same three screens — Music, Feed, and Chat — built three different ways. Run one, open LookInside on your Mac, and inspect the live UI. Because the screens match, you can load the SwiftUI app and the native app side by side and compare exactly what each hierarchy looks like in the inspector.

The two native apps additionally ship a Controls screen: a gallery of the stock UIKit / AppKit controls — buttons, text inputs, sliders, steppers, progress indicators, pickers, and a card drawn by a bare `CALayer` sublayer — so there is a rich, varied hierarchy to point the inspector at.

| App | Platform | Built with |
| --- | -------- | ---------- |
| `LookInsideExample` | iOS + macOS | SwiftUI |
| `LookInsideExampleUIKit` | iOS | UIKit only — no `import SwiftUI` |
| `LookInsideExampleAppKit` | macOS | AppKit only — no `import SwiftUI` |

The two native apps are written the long way on purpose: hand-built view controllers, Auto Layout constraints, Core Animation layers, view-based table views, and a code-built menu bar on the Mac. That is the shape most real apps have, and the shape the inspector was built for.

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

You can also open `LookInsideExample.xcodeproj` in Xcode, pick a scheme, and press Run.

## Build only

```bash
make build-sim      # SwiftUI app, iOS Simulator
make build-mac      # SwiftUI app, Mac
make build-uikit    # UIKit app
make build-appkit   # AppKit app
make build-all      # all three
```

Run `make help` for the full target list.

## What is inside

| Path | What it is |
| ---- | ---------- |
| `Sources/LookInsideExampleApp/` | The SwiftUI app |
| `Sources/LookInsideExampleUIKit/` | The pure-UIKit iOS app |
| `Sources/LookInsideExampleAppKit/` | The pure-AppKit macOS app |
| `Sources/DemoShared/` | Demo fixtures shared by the native apps, plus the server runtime bridge |
| `LookInsideExample.xcodeproj` | The Xcode project |
| `Project.swift` | Tuist project setup |
| `Configuration/` | Build settings |

LookInside continues the work of [`LookinServer`](https://github.com/QMUI/LookinServer), the original iOS view debugger runtime.
