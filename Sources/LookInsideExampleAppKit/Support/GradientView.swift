import AppKit

/// A gradient rectangle with its own corner radius.
///
/// The gradient lives in a `CAGradientLayer` **sublayer** rather than on the
/// view's backing layer on purpose: AppKit re-syncs `cornerRadius`,
/// `masksToBounds`, `opacity` and the shadow properties from view ivars onto
/// the backing layer whenever it rebuilds the layer tree, so those settings
/// would silently reset. Nothing touches a sublayer we added ourselves.
class GradientView: NSView {
    let gradientLayer = CAGradientLayer()

    private var sourceColors: [NSColor] = []

    var cornerRadius: CGFloat {
        didSet {
            gradientLayer.cornerRadius = cornerRadius
            needsLayout = true
        }
    }

    init(cornerRadius: CGFloat = 0) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.masksToBounds = true
        layer?.addSublayer(gradientLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColors(_ colors: [NSColor]) {
        sourceColors = colors
        applySourceColors()
    }

    /// System colours are dynamic; `cgColor` snapshots whichever appearance is
    /// current, so resolve them explicitly and redo it when the appearance
    /// changes.
    private func applySourceColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            gradientLayer.colors = sourceColors.map(\.cgColor)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applySourceColors()
        reapplySublayerColorsForCurrentAppearance()
    }

    /// Subclasses re-resolve any additional sublayer colours here.
    func reapplySublayerColorsForCurrentAppearance() {}

    override func layout() {
        super.layout()
        // Sublayers do not follow the view's resize, and their implicit
        // animations would lag a live window resize by a frame.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        layoutGradientSublayers()
        CATransaction.commit()
    }

    /// Subclasses position their own sublayers here, inside the same
    /// no-implicit-animation transaction.
    func layoutGradientSublayers() {}
}
