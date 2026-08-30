import UIKit

/// A gallery of the stock UIKit controls, grouped into cards. Every control
/// here exists to give the inspector an interesting hierarchy to walk:
/// configuration-based buttons, text inputs with side views, the value
/// controls, async spinners, pickers, and a card whose gradient lives in a
/// bare CALayer sublayer rather than in any view.
final class ControlsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView(axis: .vertical, spacing: 16)

    private let stepper = UIStepper()
    private let stepperValueLabel = UILabel(
        text: "5",
        font: .monospacedDigitSystemFont(ofSize: 15, weight: .medium),
        color: DemoPalette.primaryLabel
    )
    private let slider = UISlider()
    private let sliderValueLabel = UILabel(
        text: "40%",
        font: .monospacedDigitSystemFont(ofSize: 13, weight: .regular),
        color: DemoPalette.secondaryLabel
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Controls"
        view.backgroundColor = DemoPalette.groupedBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        scrollView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            contentStackView.widthAnchor.constraint(
                lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -40
            ),
            contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth)
                .withPriority(.defaultHigh),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
                .withPriority(.defaultHigh - 1),
        ])

        contentStackView.addArrangedSubview(makeButtonsCard())
        contentStackView.addArrangedSubview(makeTextInputCard())
        contentStackView.addArrangedSubview(makeTogglesAndSlidersCard())
        contentStackView.addArrangedSubview(makeProgressCard())
        contentStackView.addArrangedSubview(makePickersCard())
        contentStackView.addArrangedSubview(makeLayersCard())
    }

    // MARK: - Cards

    private func makeCard(title: String, contentViews: [UIView]) -> UIView {
        let card = CardView()
        let titleLabel = UILabel(
            text: title,
            font: .systemFont(ofSize: 13, weight: .semibold),
            color: DemoPalette.secondaryLabel
        )
        let stackView = UIStackView(axis: .vertical, spacing: 14, arrangedSubviews: [titleLabel] + contentViews)
        stackView.setCustomSpacing(10, after: titleLabel)
        card.addSubview(stackView)
        stackView.pinEdges(to: card, insets: UIEdgeInsets(top: 14, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeRow(caption: String, control: UIView) -> UIView {
        let captionLabel = UILabel(
            text: caption,
            font: .systemFont(ofSize: 15),
            color: DemoPalette.primaryLabel
        )
        captionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        control.setContentHuggingPriority(.required, for: .horizontal)
        return UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [captionLabel, control]
        )
    }

    private func makeButtonsCard() -> UIView {
        let filledButton = UIButton(configuration: .filled())
        filledButton.configuration?.title = "Filled"
        let tintedButton = UIButton(configuration: .tinted())
        tintedButton.configuration?.title = "Tinted"
        let grayButton = UIButton(configuration: .gray())
        grayButton.configuration?.title = "Gray"
        let borderedButton = UIButton(configuration: .bordered())
        borderedButton.configuration?.title = "Bordered"
        let buttonRow = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .center,
            arrangedSubviews: [filledButton, tintedButton, grayButton, borderedButton, UIView()]
        )

        let menuButton = UIButton(configuration: .bordered())
        menuButton.configuration?.title = "Sort by"
        menuButton.configuration?.image = UIImage(systemName: "chevron.up.chevron.down")
        menuButton.configuration?.imagePlacement = .trailing
        menuButton.configuration?.imagePadding = 6
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.changesSelectionAsPrimaryAction = true
        menuButton.menu = UIMenu(children: [
            UIAction(title: "Name") { _ in },
            UIAction(title: "Date added") { _ in },
            UIAction(title: "Play count") { _ in },
        ])

        let symbolButton = UIButton(type: .system)
        symbolButton.translatesAutoresizingMaskIntoConstraints = false
        symbolButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        symbolButton.tintColor = .systemPink

        let pullDownRow = UIStackView(
            axis: .horizontal,
            spacing: 10,
            alignment: .center,
            arrangedSubviews: [menuButton, symbolButton, UIView()]
        )

        let segmentedControl = UISegmentedControl(items: ["Day", "Week", "Month", "Year"])
        segmentedControl.selectedSegmentIndex = 1

        return makeCard(title: "BUTTONS", contentViews: [buttonRow, pullDownRow, segmentedControl])
    }

    private func makeTextInputCard() -> UIView {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Name"
        let personImageView = UIImageView(image: UIImage(systemName: "person.circle"))
        personImageView.tintColor = DemoPalette.secondaryLabel
        personImageView.contentMode = .center
        personImageView.frame = CGRect(x: 0, y: 0, width: 28, height: 22)
        textField.leftView = personImageView
        textField.leftViewMode = .always

        let secureTextField = UITextField()
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        secureTextField.borderStyle = .roundedRect
        secureTextField.placeholder = "Password"
        secureTextField.isSecureTextEntry = true

        let searchTextField = UISearchTextField()
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.placeholder = "Search library"

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = DemoPalette.primaryLabel
        textView.backgroundColor = DemoPalette.groupedBackground
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        textView.text = "A UITextView with a couple of lines of content, so the text container and its fragment layers have something to show in the inspector."

        return makeCard(title: "TEXT INPUT", contentViews: [textField, secureTextField, searchTextField, textView])
    }

    private func makeTogglesAndSlidersCard() -> UIView {
        let switchControl = UISwitch()
        switchControl.isOn = true

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValueImage = UIImage(systemName: "speaker.fill")
        slider.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
        slider.value = 0.4
        slider.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        let sliderRow = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [slider, sliderValueLabel]
        )
        sliderValueLabel.setContentHuggingPriority(.required, for: .horizontal)

        stepper.value = 5
        stepper.minimumValue = 0
        stepper.maximumValue = 10
        stepper.addTarget(self, action: #selector(stepperValueDidChange), for: .valueChanged)
        let stepperControlRow = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [stepperValueLabel, stepper]
        )

        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = 5
        pageControl.currentPage = 2
        pageControl.pageIndicatorTintColor = DemoPalette.separator
        pageControl.currentPageIndicatorTintColor = DemoPalette.accent

        return makeCard(title: "TOGGLES & SLIDERS", contentViews: [
            makeRow(caption: "Notifications", control: switchControl),
            sliderRow,
            makeRow(caption: "Copies", control: stepperControlRow),
            pageControl,
        ])
    }

    private func makeProgressCard() -> UIView {
        let determinateProgressView = UIProgressView(progressViewStyle: .default)
        determinateProgressView.translatesAutoresizingMaskIntoConstraints = false
        determinateProgressView.progress = 0.65

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.startAnimating()

        return makeCard(title: "PROGRESS", contentViews: [
            determinateProgressView,
            makeRow(caption: "Syncing…", control: activityIndicatorView),
        ])
    }

    private func makePickersCard() -> UIView {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact

        let colorWell = UIColorWell()
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.selectedColor = .systemIndigo
        colorWell.supportsAlpha = false

        return makeCard(title: "PICKERS", contentViews: [
            makeRow(caption: "Reminder", control: datePicker),
            makeRow(caption: "Accent color", control: colorWell),
        ])
    }

    private func makeLayersCard() -> UIView {
        // The gradient is a bare CALayer sublayer with no view of its own —
        // an orphan layer in the inspector's hierarchy.
        let gradientContainerView = GradientCardView()
        gradientContainerView.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            .applying(UIImage.SymbolConfiguration.preferringMulticolor())
        let symbolNames = ["cloud.sun.rain.fill", "thermometer.sun.fill", "wind", "moon.stars.fill"]
        let symbolImageViews: [UIView] = symbolNames.map { symbolName in
            let imageView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: symbolConfiguration))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .center
            return imageView
        }
        let symbolRow = UIStackView(
            axis: .horizontal,
            spacing: 0,
            distribution: .fillEqually,
            arrangedSubviews: symbolImageViews
        )

        return makeCard(title: "IMAGES & LAYERS", contentViews: [gradientContainerView, symbolRow])
    }

    // MARK: - Actions

    @objc
    private func sliderValueDidChange() {
        sliderValueLabel.text = "\(Int((slider.value * 100).rounded()))%"
    }

    @objc
    private func stepperValueDidChange() {
        stepperValueLabel.text = "\(Int(stepper.value))"
    }
}

/// A rounded card whose gradient lives in a plain CALayer sublayer.
private final class GradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        gradientLayer.colors = [UIColor.systemIndigo.cgColor, UIColor.systemTeal.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 12
        layer.addSublayer(gradientLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
