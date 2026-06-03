import Foundation
import ObjectiveC.runtime

/// Bridges to `+[LookInsideServer isLicensed]` purely via the ObjC runtime
/// so this Example does not depend on any public header from
/// `LookInsideServer.xcframework` — the framework ships header-stripped and
/// only its binary is linked.
enum LookInsideServerRuntime {
    static var isLicensed: Bool {
        guard let serverClass = NSClassFromString("LookInsideServer") else {
            return false
        }
        let selector = NSSelectorFromString("isLicensed")
        guard let method = class_getClassMethod(serverClass, selector) else {
            return false
        }
        typealias IsLicensedGetter = @convention(c) (AnyClass, Selector) -> Bool
        let implementation = unsafeBitCast(method_getImplementation(method), to: IsLicensedGetter.self)
        return implementation(serverClass, selector)
    }
}
