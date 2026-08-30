import AppKit

/// A gallery of the stock AppKit controls, grouped into cards. Every control
/// here exists to give the inspector an interesting hierarchy to walk: the
/// cell-based controls (buttons, sliders, steppers), field editors and token
/// fields, determinate and indeterminate progress, pickers, and a card whose
/// gradient lives in a bare CALayer sublayer rather than in any view.
final class ControlsViewController: NSViewController {
    private let slider = NSSlider()
    private let sliderValueLabel = NSTextField.demoLabel(
        "40%",
        font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular),
        color: DemoPalette.secondaryLabel,
        alignment: .right
    )
    private let stepper = NSStepper()
    private let stepperValueField = NSTextField.demoLabel(
        "5",
        font: .monospacedDigitSystemFont(ofSize: 13, weight: .medium),
        color: DemoPalette.primaryLabel,
        alignment: .right
    )

    override func loadView() {
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view = containerView

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 20,
            alignment: .leading,
            views: [
                makeButtonsCard(),
                makeTextInputCard(),
                makeTogglesAndSlidersCard(),
                makeProgressCard(),
                makePickersCard(),
                makeLayersCard(),
            ]
        )
        for card in columnStackView.arrangedSubviews {
            card.widthAnchor.constraint(equalTo: columnStackView.widthAnchor).isActive = true
        }
        documentView.addSubview(columnStackView)
        containerView.addSubview(scrollView)
        scrollView.pinEdges(to: containerView)

        let clipView = scrollView.contentView
        let preferredWidthConstraint = columnStackView.widthAnchor.constraint(
            equalTo: documentView.widthAnchor,
            constant: -48
        )
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: clipView.widthAnchor),

            columnStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 24),
            columnStackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -24),
            columnStackView.centerXAnchor.constraint(equalTo: documentView.centerXAnchor),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: documentView.leadingAnchor, constant: 24),
            columnStackView.widthAnchor.constraint(lessThanOrEqualToConstant: DemoMetrics.contentMaximumWidth),
            preferredWidthConstraint,
        ])
    }

    // MARK: - Cards

    private func makeCard(title: String, contentViews: [NSView]) -> NSView {
        let card = CardBoxView()
        let titleLabel = NSTextField.demoLabel(
            title,
            font: .systemFont(ofSize: 11, weight: .semibold),
            color: DemoPalette.secondaryLabel
        )
        let stackView = NSStackView(
            orientation: .vertical,
            spacing: 12,
            alignment: .leading,
            views: [titleLabel] + contentViews
        )
        stackView.setCustomSpacing(10, after: titleLabel)
        card.addSubview(stackView)
        stackView.pinEdges(to: card, insets: NSEdgeInsets(top: 12, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeRow(caption: String, control: NSView) -> NSView {
        let captionLabel = NSTextField.demoLabel(
            caption,
            font: .preferredFont(forTextStyle: .body),
            color: DemoPalette.primaryLabel
        )
        return NSStackView(
            orientation: .horizontal,
            spacing: 12,
            alignment: .centerY,
            views: [captionLabel, control]
        )
    }

    private func makeButtonsCard() -> NSView {
        let pushButton = NSButton(title: "Play", target: nil, action: nil)
        pushButton.translatesAutoresizingMaskIntoConstraints = false
        pushButton.bezelStyle = .rounded
        pushButton.keyEquivalent = "\r"

        let imageButton = NSButton(
            title: "Share",
            image: NSImage.demoSymbol("square.and.arrow.up", pointSize: 12) ?? NSImage(),
            target: nil,
            action: nil
        )
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.bezelStyle = .rounded
        imageButton.imagePosition = .imageLeading

        let popUpButton = NSPopUpButton()
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        popUpButton.addItems(withTitles: ["Name", "Date added", "Play count"])

        let buttonRow = NSStackView(
            orientation: .horizontal,
            spacing: 10,
            alignment: .centerY,
            views: [pushButton, imageButton, popUpButton, NSView.flexibleSpacer()]
        )

        let firstCheckbox = NSButton(checkboxWithTitle: "Shuffle", target: nil, action: nil)
        firstCheckbox.translatesAutoresizingMaskIntoConstraints = false
        firstCheckbox.state = .on
        let secondCheckbox = NSButton(checkboxWithTitle: "Repeat", target: nil, action: nil)
        secondCheckbox.translatesAutoresizingMaskIntoConstraints = false
        let checkboxRow = NSStackView(
            orientation: .horizontal,
            spacing: 16,
            alignment: .centerY,
            views: [firstCheckbox, secondCheckbox, NSView.flexibleSpacer()]
        )

        // Radio buttons group by sharing a target/action pair.
        let radioTitles = ["Small", "Medium", "Large"]
        let radioButtons: [NSButton] = radioTitles.enumerated().map { index, title in
            let radioButton = NSButton(radioButtonWithTitle: title, target: self, action: #selector(radioButtonDidChange))
            radioButton.translatesAutoresizingMaskIntoConstraints = false
            radioButton.state = index == 1 ? .on : .off
            return radioButton
        }
        let radioRow = NSStackView(
            orientation: .horizontal,
            spacing: 16,
            alignment: .centerY,
            views: radioButtons + [NSView.flexibleSpacer()]
        )

        let segmentedControl = NSSegmentedControl(
            labels: ["Day", "Week", "Month", "Year"],
            trackingMode: .selectOne,
            target: nil,
            action: nil
        )
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegment = 1

        return makeCard(title: "BUTTONS", contentViews: [buttonRow, checkboxRow, radioRow, segmentedControl])
    }

    private func makeTextInputCard() -> NSView {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = "Name"

        let secureTextField = NSSecureTextField()
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        secureTextField.placeholderString = "Password"

        let searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search library"

        let comboBox = NSComboBox()
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        comboBox.addItems(withObjectValues: ["Lossless", "High", "Standard", "Data saver"])
        comboBox.placeholderString = "Quality"

        let tokenField = NSTokenField()
        tokenField.translatesAutoresizingMaskIntoConstraints = false
        tokenField.objectValue = ["design", "debug", "layers"]

        let scrollableTextView = NSTextView.scrollableTextView()
        scrollableTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollableTextView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        if let textView = scrollableTextView.documentView as? NSTextView {
            textView.font = .preferredFont(forTextStyle: .body)
            textView.textColor = DemoPalette.primaryLabel
            textView.drawsBackground = false
            textView.string = "An NSTextView with a couple of lines of content, so the layout manager's text fragments have something to show in the inspector."
        }
        scrollableTextView.drawsBackground = false

        for fullWidthField in [textField, secureTextField, searchField, comboBox, tokenField] {
            fullWidthField.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true
        }

        return makeCard(title: "TEXT INPUT", contentViews: [
            textField, secureTextField, searchField, comboBox, tokenField, scrollableTextView,
        ])
    }

    private func makeTogglesAndSlidersCard() -> NSView {
        let switchControl = NSSwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.state = .on

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = 0.4
        slider.target = self
        slider.action = #selector(sliderValueDidChange)
        slider.widthAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
        sliderValueLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let sliderRow = NSStackView(
            orientation: .horizontal,
            spacing: 12,
            alignment: .centerY,
            views: [slider, sliderValueLabel]
        )

        let tickMarkSlider = NSSlider()
        tickMarkSlider.translatesAutoresizingMaskIntoConstraints = false
        tickMarkSlider.minValue = 0
        tickMarkSlider.maxValue = 10
        tickMarkSlider.doubleValue = 6
        tickMarkSlider.numberOfTickMarks = 11
        tickMarkSlider.allowsTickMarkValuesOnly = true
        tickMarkSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true

        let circularSlider = NSSlider()
        circularSlider.translatesAutoresizingMaskIntoConstraints = false
        circularSlider.sliderType = .circular
        circularSlider.minValue = 0
        circularSlider.maxValue = 360
        circularSlider.doubleValue = 120

        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.minValue = 0
        stepper.maxValue = 10
        stepper.integerValue = 5
        stepper.target = self
        stepper.action = #selector(stepperValueDidChange)
        let stepperControlRow = NSStackView(
            orientation: .horizontal,
            spacing: 8,
            alignment: .centerY,
            views: [stepperValueField, stepper]
        )

        let ratingIndicator = NSLevelIndicator()
        ratingIndicator.translatesAutoresizingMaskIntoConstraints = false
        ratingIndicator.levelIndicatorStyle = .rating
        ratingIndicator.minValue = 0
        ratingIndicator.maxValue = 5
        ratingIndicator.doubleValue = 3
        ratingIndicator.isEditable = true

        return makeCard(title: "TOGGLES & SLIDERS", contentViews: [
            makeRow(caption: "Notifications", control: switchControl),
            sliderRow,
            tickMarkSlider,
            makeRow(caption: "Rotation", control: circularSlider),
            makeRow(caption: "Copies", control: stepperControlRow),
            makeRow(caption: "Rating", control: ratingIndicator),
        ])
    }

    private func makeProgressCard() -> NSView {
        let determinateProgressIndicator = NSProgressIndicator()
        determinateProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        determinateProgressIndicator.isIndeterminate = false
        determinateProgressIndicator.minValue = 0
        determinateProgressIndicator.maxValue = 1
        determinateProgressIndicator.doubleValue = 0.65
        determinateProgressIndicator.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true

        let spinningProgressIndicator = NSProgressIndicator()
        spinningProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        spinningProgressIndicator.style = .spinning
        spinningProgressIndicator.controlSize = .small
        spinningProgressIndicator.startAnimation(nil)

        return makeCard(title: "PROGRESS", contentViews: [
            determinateProgressIndicator,
            makeRow(caption: "Syncing…", control: spinningProgressIndicator),
        ])
    }

    private func makePickersCard() -> NSView {
        let datePicker = NSDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = [.yearMonthDay, .hourMinute]
        datePicker.dateValue = Date()

        let colorWell = NSColorWell()
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.color = .systemIndigo
        NSLayoutConstraint.activate([
            colorWell.widthAnchor.constraint(equalToConstant: 44),
            colorWell.heightAnchor.constraint(equalToConstant: 24),
        ])

        let pathControl = NSPathControl()
        pathControl.translatesAutoresizingMaskIntoConstraints = false
        pathControl.url = URL(fileURLWithPath: "/Applications/Utilities")
        pathControl.pathStyle = .standard

        return makeCard(title: "PICKERS", contentViews: [
            makeRow(caption: "Reminder", control: datePicker),
            makeRow(caption: "Accent color", control: colorWell),
            pathControl,
        ])
    }

    private func makeLayersCard() -> NSView {
        // The gradient is a bare CALayer sublayer with no view of its own —
        // an orphan layer in the inspector's hierarchy.
        let gradientView = GradientView(cornerRadius: 12)
        gradientView.setColors([.systemIndigo, .systemTeal])
        gradientView.heightAnchor.constraint(equalToConstant: 72).isActive = true
        gradientView.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true

        let symbolNames = ["cloud.sun.rain.fill", "thermometer.sun.fill", "wind", "moon.stars.fill"]
        let symbolImageViews: [NSView] = symbolNames.map { symbolName in
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = NSImage.demoSymbol(symbolName, pointSize: 24)
            imageView.contentTintColor = DemoPalette.accent
            return imageView
        }
        let symbolRow = NSStackView(
            orientation: .horizontal,
            spacing: 24,
            alignment: .centerY,
            views: symbolImageViews + [NSView.flexibleSpacer()]
        )

        return makeCard(title: "IMAGES & LAYERS", contentViews: [gradientView, symbolRow])
    }

    // MARK: - Actions

    @objc
    private func sliderValueDidChange() {
        sliderValueLabel.stringValue = "\(Int((slider.doubleValue * 100).rounded()))%"
    }

    @objc
    private func stepperValueDidChange() {
        stepperValueField.stringValue = "\(stepper.integerValue)"
    }

    @objc
    private func radioButtonDidChange() {}
}
