import UIKit

/// A gallery of the UIKit controls tvOS has, in panels two to a row.
///
/// tvOS has no switch, slider, stepper, date picker or colour well. The
/// screen scrolls only when focus moves, so every row of panels holds at
/// least one control that can take focus — otherwise the rows below it could
/// never be scrolled into view.
final class ControlsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let pageControl = UIPageControl()
    private let gradientCardView = GradientCardView()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        let contentStackView = UIStackView(axis: .vertical, spacing: 40, arrangedSubviews: [
            makePanelRow(makeButtonsPanel(), makeSelectionPanel()),
            makePanelRow(makeTextInputPanel(), makeProgressPanel()),
            makePanelRow(makeLayersPanel(), makeTextPanel()),
        ])
        scrollView.addSubview(contentStackView)

        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            contentStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    private func makePanelRow(_ leadingPanel: UIView, _ trailingPanel: UIView) -> UIView {
        UIStackView(
            axis: .horizontal,
            spacing: 40,
            alignment: .top,
            distribution: .fillEqually,
            arrangedSubviews: [leadingPanel, trailingPanel]
        )
    }

    // MARK: - Panels

    private func makeButtonsPanel() -> UIView {
        let filledButton = UIButton(configuration: .filled())
        filledButton.configuration?.title = "Filled"
        let tintedButton = UIButton(configuration: .tinted())
        tintedButton.configuration?.title = "Tinted"
        let grayButton = UIButton(configuration: .gray())
        grayButton.configuration?.title = "Gray"
        let borderedButton = UIButton(configuration: .bordered())
        borderedButton.configuration?.title = "Bordered"
        for button in [filledButton, tintedButton, grayButton, borderedButton] {
            button.configuration?.cornerStyle = .capsule
        }

        let symbolButton = UIButton(configuration: .bordered())
        symbolButton.configuration?.image = UIImage(systemName: "heart.fill")
        symbolButton.configuration?.baseForegroundColor = .systemPink
        symbolButton.configuration?.cornerStyle = .capsule

        return PanelView(title: "Buttons", rows: [
            UIStackView(axis: .horizontal, spacing: 24, distribution: .fillEqually, arrangedSubviews: [filledButton, tintedButton]),
            UIStackView(axis: .horizontal, spacing: 24, distribution: .fillEqually, arrangedSubviews: [grayButton, borderedButton]),
            PanelRowView(title: "Favorite", accessory: symbolButton),
        ])
    }

    private func makeSelectionPanel() -> UIView {
        let segmentedControl = UISegmentedControl(items: ["Day", "Week", "Month", "Year"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 1

        var menuButtonConfiguration = UIButton.Configuration.bordered()
        menuButtonConfiguration.indicator = .popup
        let menuButton = UIButton(configuration: menuButtonConfiguration)
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.changesSelectionAsPrimaryAction = true
        menuButton.menu = UIMenu(children: [
            UIAction(title: "Name", state: .on) { _ in },
            UIAction(title: "Date Added") { _ in },
            UIAction(title: "Play Count") { _ in },
        ])

        return PanelView(title: "Selection", rows: [
            segmentedControl,
            PanelRowView(title: "Sort by", accessory: menuButton),
        ])
    }

    private func makeTextInputPanel() -> UIView {
        let nameTextField = UITextField()
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.placeholder = "Name"

        let passwordTextField = UITextField()
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true

        return PanelView(
            title: "Text Input",
            footer: "Pressing a field opens the full-screen keyboard.",
            rows: [nameTextField, passwordTextField]
        )
    }

    private func makeProgressPanel() -> UIView {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0.4

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.startAnimating()

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = 5
        pageControl.currentPage = 2
        pageControl.pageIndicatorTintColor = DemoPalette.tertiaryLabel
        pageControl.currentPageIndicatorTintColor = DemoPalette.accent

        var advanceButtonConfiguration = UIButton.Configuration.tinted()
        advanceButtonConfiguration.title = "Advance"
        advanceButtonConfiguration.image = UIImage(systemName: "forward.end.fill")
        advanceButtonConfiguration.imagePadding = 12
        advanceButtonConfiguration.cornerStyle = .capsule
        let advanceButton = UIButton(configuration: advanceButtonConfiguration, primaryAction: UIAction { [weak self] _ in
            self?.advanceProgress()
        })

        return PanelView(title: "Progress", rows: [
            progressView,
            PanelRowView(title: "Syncing", accessory: activityIndicatorView),
            PanelRowView(title: "Page", accessory: pageControl),
            PanelRowView(title: "Step the bar and the page", accessory: advanceButton),
        ])
    }

    private func makeLayersPanel() -> UIView {
        gradientCardView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
            .applying(UIImage.SymbolConfiguration.preferringMulticolor())
        let symbolNames = ["sun.max.fill", "thermometer.sun.fill", "flame.fill", "leaf.fill"]
        let symbolImageViews: [UIView] = symbolNames.map { symbolName in
            let imageView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: symbolConfiguration))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .center
            // Tints the layers a symbol leaves uncoloured in multicolor mode.
            imageView.tintColor = .systemIndigo
            return imageView
        }
        let symbolRowStackView = UIStackView(axis: .horizontal, distribution: .fillEqually, arrangedSubviews: symbolImageViews)

        var animateButtonConfiguration = UIButton.Configuration.tinted()
        animateButtonConfiguration.title = "Animate"
        animateButtonConfiguration.image = UIImage(systemName: "sparkles")
        animateButtonConfiguration.imagePadding = 12
        animateButtonConfiguration.cornerStyle = .capsule
        let animateButton = UIButton(configuration: animateButtonConfiguration, primaryAction: UIAction { [weak self] _ in
            self?.gradientCardView.toggleColorAnimation()
        })

        return PanelView(title: "Images and Layers", rows: [
            gradientCardView,
            symbolRowStackView,
            PanelRowView(title: "Cycle the gradient colours", accessory: animateButton),
        ])
    }

    private func makeTextPanel() -> UIView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = DemoPalette.primaryLabel
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.text = "Notes live in a UITextView, so the inspector can show its text container and the layers TextKit draws into."

        return PanelView(title: "Text", rows: [textView])
    }

    // MARK: - Actions

    private func advanceProgress() {
        let nextProgress = progressView.progress + 0.2
        progressView.setProgress(nextProgress > 1.01 ? 0 : nextProgress, animated: true)
        pageControl.currentPage = (pageControl.currentPage + 1) % pageControl.numberOfPages
    }
}

/// A rounded card whose gradient lives in a bare `CALayer` sublayer — a layer
/// with no view of its own in the inspector's hierarchy.
private final class GradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()
    private static let colorAnimationKey = "gradientColors"

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        gradientLayer.colors = [UIColor.systemIndigo.cgColor, UIColor.systemTeal.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 18
        gradientLayer.cornerCurve = .continuous
        layer.addSublayer(gradientLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggleColorAnimation() {
        if gradientLayer.animation(forKey: Self.colorAnimationKey) != nil {
            gradientLayer.removeAnimation(forKey: Self.colorAnimationKey)
            return
        }
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.toValue = [UIColor.systemPink.cgColor, UIColor.systemOrange.cgColor]
        colorAnimation.duration = 1.4
        colorAnimation.autoreverses = true
        colorAnimation.repeatCount = .greatestFiniteMagnitude
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(colorAnimation, forKey: Self.colorAnimationKey)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
}
