import UIKit

/// A gallery of the stock UIKit controls, grouped into form sections. Every control
/// here exists to give the inspector an interesting hierarchy to walk:
/// configuration-based buttons, text inputs with side views, the value
/// controls, async spinners, pickers, and a card whose gradient lives in a
/// bare CALayer sublayer rather than in any view.
final class ControlsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView(axis: .vertical, spacing: 28)

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
            // Both just under required: above every control's content
            // hugging, so the column fills the width rather than shrinking to
            // the narrowest control.
            contentStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth)
                .withPriority(.required - 1),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
                .withPriority(.required - 2),
        ])

        contentStackView.addArrangedSubview(makeButtonsSection())
        contentStackView.addArrangedSubview(makeTextInputSection())
        contentStackView.addArrangedSubview(makeTogglesAndSlidersSection())
        contentStackView.addArrangedSubview(makeProgressSection())
        contentStackView.addArrangedSubview(makePickersSection())
        contentStackView.addArrangedSubview(makeLayersSection())
    }

    // MARK: - Sections

    private func makeButtonsSection() -> UIView {
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
            button.configuration?.titleLineBreakMode = .byTruncatingTail
        }

        // Two rows of two, so the titles never wrap on a narrow phone.
        let buttonGridStackView = UIStackView(axis: .vertical, spacing: 10, arrangedSubviews: [
            UIStackView(axis: .horizontal, spacing: 10, distribution: .fillEqually, arrangedSubviews: [filledButton, tintedButton]),
            UIStackView(axis: .horizontal, spacing: 10, distribution: .fillEqually, arrangedSubviews: [grayButton, borderedButton]),
        ])

        let menuButton = UIButton(configuration: .plain())
        menuButton.configuration?.contentInsets = .zero
        menuButton.configuration?.indicator = .popup
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.changesSelectionAsPrimaryAction = true
        menuButton.menu = UIMenu(children: [
            UIAction(title: "Name", state: .on) { _ in },
            UIAction(title: "Date Added") { _ in },
            UIAction(title: "Play Count") { _ in },
        ])

        let symbolButton = UIButton(type: .system)
        symbolButton.translatesAutoresizingMaskIntoConstraints = false
        symbolButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        symbolButton.tintColor = .systemPink

        let segmentedControl = UISegmentedControl(items: ["Day", "Week", "Month", "Year"])
        segmentedControl.selectedSegmentIndex = 1

        return FormSectionView(title: "Buttons", rows: [
            FormContentRowView(contentView: buttonGridStackView),
            FormRowView(title: "Sort by", accessory: menuButton),
            FormRowView(title: "Favorite", accessory: symbolButton),
            FormContentRowView(contentView: segmentedControl),
        ])
    }

    private func makeTextInputSection() -> UIView {
        let textField = makeFormTextField(placeholder: "Name", symbolName: "person")
        let secureTextField = makeFormTextField(placeholder: "Password", symbolName: "lock")
        secureTextField.isSecureTextEntry = true

        let searchTextField = UISearchTextField()
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.placeholder = "Search library"

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = DemoPalette.primaryLabel
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.text = "Notes live in a UITextView, so the inspector can show its text container and fragment layers."

        return FormSectionView(title: "Text Input", rows: [
            FormContentRowView(contentView: textField),
            FormContentRowView(contentView: secureTextField),
            FormContentRowView(contentView: searchTextField, insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)),
            FormContentRowView(contentView: textView),
        ])
    }

    /// A borderless field with a leading symbol in its `leftView`.
    private func makeFormTextField(placeholder: String, symbolName: String) -> UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .none
        textField.placeholder = placeholder
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        // The side view sizes from its frame only when it has no intrinsic
        // size, so the symbol sits in a fixed-width container.
        let symbolImageView = UIImageView(image: UIImage(systemName: symbolName))
        symbolImageView.tintColor = DemoPalette.secondaryLabel
        symbolImageView.contentMode = .center
        symbolImageView.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let leftContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 22))
        leftContainerView.addSubview(symbolImageView)
        textField.leftView = leftContainerView
        textField.leftViewMode = .always
        textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        return textField
    }

    private func makeTogglesAndSlidersSection() -> UIView {
        let switchControl = UISwitch()
        switchControl.isOn = true

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValueImage = UIImage(systemName: "speaker.fill")
        slider.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
        slider.tintColor = DemoPalette.accent
        slider.value = 0.4
        slider.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        sliderValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        sliderValueLabel.textAlignment = .right
        sliderValueLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let sliderRowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [slider, sliderValueLabel]
        )

        stepper.value = 5
        stepper.minimumValue = 0
        stepper.maximumValue = 10
        stepper.addTarget(self, action: #selector(stepperValueDidChange), for: .valueChanged)
        let stepperControlStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .center,
            arrangedSubviews: [stepperValueLabel, stepper]
        )

        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = 5
        pageControl.currentPage = 2
        pageControl.pageIndicatorTintColor = DemoPalette.tertiaryLabel
        pageControl.currentPageIndicatorTintColor = DemoPalette.accent

        return FormSectionView(title: "Toggles and Sliders", rows: [
            FormRowView(title: "Notifications", accessory: switchControl),
            FormContentRowView(contentView: sliderRowStackView),
            FormRowView(title: "Copies", accessory: stepperControlStackView),
            FormRowView(title: "Page", accessory: pageControl),
        ])
    }

    private func makeProgressSection() -> UIView {
        let determinateProgressView = UIProgressView(progressViewStyle: .default)
        determinateProgressView.translatesAutoresizingMaskIntoConstraints = false
        determinateProgressView.progress = 0.65
        determinateProgressView.widthAnchor.constraint(equalToConstant: 140).isActive = true

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.startAnimating()

        return FormSectionView(title: "Progress", rows: [
            FormRowView(title: "Download", accessory: determinateProgressView),
            FormRowView(title: "Syncing", accessory: activityIndicatorView),
        ])
    }

    private func makePickersSection() -> UIView {
        let datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact

        let colorWell = UIColorWell()
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.selectedColor = .systemIndigo
        colorWell.supportsAlpha = false

        return FormSectionView(title: "Pickers", rows: [
            FormRowView(title: "Reminder", accessory: datePicker),
            FormRowView(title: "Accent color", accessory: colorWell),
        ])
    }

    private func makeLayersSection() -> UIView {
        // The gradient is a bare CALayer sublayer with no view of its own —
        // an orphan layer in the inspector's hierarchy.
        let gradientContainerView = GradientCardView()
        gradientContainerView.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
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
        let symbolRowStackView = UIStackView(
            axis: .horizontal,
            spacing: 0,
            distribution: .fillEqually,
            arrangedSubviews: symbolImageViews
        )

        return FormSectionView(title: "Images and Layers", rows: [
            FormContentRowView(contentView: gradientContainerView),
            FormContentRowView(contentView: symbolRowStackView),
        ])
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
