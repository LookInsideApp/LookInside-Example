import AppKit

/// A gallery of the stock AppKit controls, grouped into form sections. Every control
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

        let columnStackView = NSStackView(
            orientation: .vertical,
            spacing: 24,
            alignment: .leading,
            views: [
                makeButtonsSection(),
                makeTextInputSection(),
                makeTogglesAndSlidersSection(),
                makeProgressSection(),
                makePickersSection(),
                makeLayersSection(),
            ]
        )
        for sectionView in columnStackView.arrangedSubviews {
            sectionView.widthAnchor.constraint(equalTo: columnStackView.widthAnchor).isActive = true
        }
        NSScrollView.installCenteredColumn(columnStackView, in: containerView)
    }

    // MARK: - Sections

    private func makeButtonsSection() -> NSView {
        let pushButton = NSButton(title: "Play", target: nil, action: nil)
        pushButton.translatesAutoresizingMaskIntoConstraints = false
        pushButton.bezelStyle = .push
        pushButton.keyEquivalent = "\r"

        let imageButton = NSButton(
            title: "Share",
            image: NSImage.demoSymbol("square.and.arrow.up", pointSize: 12) ?? NSImage(),
            target: nil,
            action: nil
        )
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.bezelStyle = .push
        imageButton.imagePosition = .imageLeading

        let popUpButton = NSPopUpButton()
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        popUpButton.addItems(withTitles: ["Name", "Date Added", "Play Count"])

        let firstCheckbox = NSButton(checkboxWithTitle: "Shuffle", target: nil, action: nil)
        firstCheckbox.translatesAutoresizingMaskIntoConstraints = false
        firstCheckbox.state = .on
        let secondCheckbox = NSButton(checkboxWithTitle: "Repeat", target: nil, action: nil)
        secondCheckbox.translatesAutoresizingMaskIntoConstraints = false

        // Radio buttons group by sharing a target/action pair.
        let radioTitles = ["Small", "Medium", "Large"]
        let radioButtons: [NSView] = radioTitles.enumerated().map { index, title in
            let radioButton = NSButton(radioButtonWithTitle: title, target: self, action: #selector(radioButtonDidChange))
            radioButton.translatesAutoresizingMaskIntoConstraints = false
            radioButton.state = index == 1 ? .on : .off
            return radioButton
        }

        let segmentedControl = NSSegmentedControl(
            labels: ["Day", "Week", "Month", "Year"],
            trackingMode: .selectOne,
            target: nil,
            action: nil
        )
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegment = 1

        return FormSectionView(title: "Buttons", rows: [
            FormRowView(title: "Push buttons", accessory: NSStackView.controlRow([imageButton, pushButton])),
            FormRowView(title: "Sort by", accessory: popUpButton),
            FormRowView(title: "Playback", accessory: NSStackView.controlRow([firstCheckbox, secondCheckbox], spacing: 16)),
            FormRowView(title: "Text size", accessory: NSStackView.controlRow(radioButtons, spacing: 14)),
            FormRowView(title: "Range", accessory: segmentedControl),
        ])
    }

    private func makeTextInputSection() -> NSView {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = "Full name"

        let secureTextField = NSSecureTextField()
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        secureTextField.placeholderString = "Required"

        let searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search library"

        let comboBox = NSComboBox()
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        comboBox.addItems(withObjectValues: ["Lossless", "High", "Standard", "Data Saver"])
        comboBox.stringValue = "High"

        let tokenField = NSTokenField()
        tokenField.translatesAutoresizingMaskIntoConstraints = false
        tokenField.objectValue = ["design", "debug", "layers"]

        for trailingField in [textField, secureTextField, searchField, comboBox] {
            trailingField.widthAnchor.constraint(equalToConstant: 240).isActive = true
        }
        tokenField.widthAnchor.constraint(equalToConstant: 280).isActive = true

        let scrollableTextView = NSTextView.scrollableTextView()
        scrollableTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollableTextView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        scrollableTextView.drawsBackground = false
        scrollableTextView.applyDemoScrollerStyle()
        if let textView = scrollableTextView.documentView as? NSTextView {
            textView.font = .preferredFont(forTextStyle: .body)
            textView.textColor = DemoPalette.primaryLabel
            textView.drawsBackground = false
            textView.textContainerInset = .zero
            textView.textContainer?.lineFragmentPadding = 0
            textView.string = "Notes live in an NSTextView, so the inspector can show its text container and layout fragments."
        }

        return FormSectionView(title: "Text Input", rows: [
            FormRowView(title: "Name", accessory: textField),
            FormRowView(title: "Password", accessory: secureTextField),
            FormRowView(title: "Search", accessory: searchField),
            FormRowView(title: "Quality", accessory: comboBox),
            FormRowView(title: "Tags", accessory: tokenField),
            FormContentRowView(contentView: scrollableTextView),
        ])
    }

    private func makeTogglesAndSlidersSection() -> NSView {
        let switchControl = NSSwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.state = .on
        switchControl.controlSize = .small

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = 0.4
        slider.target = self
        slider.action = #selector(sliderValueDidChange)
        slider.widthAnchor.constraint(equalToConstant: 196).isActive = true
        sliderValueLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true

        let tickMarkSlider = NSSlider()
        tickMarkSlider.translatesAutoresizingMaskIntoConstraints = false
        tickMarkSlider.minValue = 0
        tickMarkSlider.maxValue = 10
        tickMarkSlider.doubleValue = 6
        tickMarkSlider.numberOfTickMarks = 11
        tickMarkSlider.allowsTickMarkValuesOnly = true
        tickMarkSlider.widthAnchor.constraint(equalToConstant: 240).isActive = true

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

        let ratingIndicator = NSLevelIndicator()
        ratingIndicator.translatesAutoresizingMaskIntoConstraints = false
        ratingIndicator.levelIndicatorStyle = .rating
        ratingIndicator.minValue = 0
        ratingIndicator.maxValue = 5
        ratingIndicator.doubleValue = 3
        ratingIndicator.isEditable = true

        return FormSectionView(title: "Toggles and Sliders", rows: [
            FormRowView(title: "Notifications", accessory: switchControl),
            FormRowView(title: "Volume", accessory: NSStackView.controlRow([slider, sliderValueLabel])),
            FormRowView(title: "Steps", accessory: tickMarkSlider),
            FormRowView(title: "Rotation", accessory: circularSlider),
            FormRowView(title: "Copies", accessory: NSStackView.controlRow([stepperValueField, stepper], spacing: 6)),
            FormRowView(title: "Rating", accessory: ratingIndicator),
        ])
    }

    private func makeProgressSection() -> NSView {
        let determinateProgressIndicator = NSProgressIndicator()
        determinateProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        determinateProgressIndicator.isIndeterminate = false
        determinateProgressIndicator.minValue = 0
        determinateProgressIndicator.maxValue = 1
        determinateProgressIndicator.doubleValue = 0.65
        determinateProgressIndicator.widthAnchor.constraint(equalToConstant: 240).isActive = true

        let spinningProgressIndicator = NSProgressIndicator()
        spinningProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        spinningProgressIndicator.style = .spinning
        spinningProgressIndicator.controlSize = .small
        spinningProgressIndicator.startAnimation(nil)

        return FormSectionView(title: "Progress", rows: [
            FormRowView(title: "Download", accessory: determinateProgressIndicator),
            FormRowView(title: "Syncing", accessory: spinningProgressIndicator),
        ])
    }

    private func makePickersSection() -> NSView {
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
        pathControl.backgroundColor = .clear

        return FormSectionView(title: "Pickers", rows: [
            FormRowView(title: "Reminder", accessory: datePicker),
            FormRowView(title: "Accent color", accessory: colorWell),
            FormRowView(title: "Location", accessory: pathControl),
        ])
    }

    private func makeLayersSection() -> NSView {
        // The gradient is a bare CALayer sublayer with no view of its own —
        // an orphan layer in the inspector's hierarchy.
        let gradientView = GradientView(cornerRadius: 10)
        gradientView.setColors([.systemIndigo, .systemTeal])
        gradientView.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let symbolNames = ["sun.max.fill", "thermometer.sun.fill", "flame.fill", "leaf.fill"]
        let symbolImageViews: [NSView] = symbolNames.map { symbolName in
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = NSImage.demoSymbol(symbolName, pointSize: 22)
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 22, weight: .regular)
                .applying(.preferringMulticolor())
            // Tints the layers a symbol leaves uncoloured in multicolor mode.
            imageView.contentTintColor = .systemIndigo
            return imageView
        }
        let symbolRowStackView = NSStackView(
            orientation: .horizontal,
            spacing: 0,
            alignment: .centerY,
            distribution: .fillEqually,
            views: symbolImageViews
        )

        return FormSectionView(title: "Images and Layers", rows: [
            FormContentRowView(contentView: gradientView),
            FormContentRowView(contentView: symbolRowStackView),
        ])
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
