import UIKit

/// The inline composer at the top of the feed.
///
/// Uses a real `UITextView` that grows with its content and reports height
/// changes back so the collection view can re-measure the self-sizing cell.
final class ComposerCell: UICollectionViewCell {
    static let reuseIdentifier = "ComposerCell"

    private let cardView = CardView()
    private let avatarBadgeView = AvatarBadgeView(initials: "Y", tint: .blue, diameter: 38)
    private let textView = UITextView()
    private let placeholderLabel = UILabel(text: "Share something with your friends...", font: .preferredFont(forTextStyle: .body), color: DemoPalette.tertiaryLabel, numberOfLines: 2)
    private let actionRowStackView = UIStackView(axis: .horizontal, spacing: 14, alignment: .center)
    private let postButton = UIButton(type: .system)

    private var textViewHeightConstraint: NSLayoutConstraint?

    var onHeightChange: (() -> Void)?
    var onPublish: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(cardView)
        cardView.pinEdges(to: contentView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = DemoPalette.groupedBackground
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.layer.cornerRadius = 14
        textView.layer.cornerCurve = .continuous
        textView.isScrollEnabled = false
        textView.delegate = self

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)

        for (symbolName, tint) in [("photo", DemoTint.green), ("video", .pink), ("location", .blue), ("face.smiling", .orange)] {
            let actionButton = UIButton(type: .system)
            actionButton.setImage(UIImage(systemName: symbolName), for: .normal)
            actionButton.tintColor = tint.color
            actionRowStackView.addArrangedSubview(actionButton)
        }
        actionRowStackView.addArrangedSubview(UIView.flexibleSpacer())

        var postButtonConfiguration = UIButton.Configuration.filled()
        postButtonConfiguration.title = "Post"
        postButtonConfiguration.baseBackgroundColor = DemoPalette.accent
        postButtonConfiguration.baseForegroundColor = .white
        postButtonConfiguration.cornerStyle = .capsule
        postButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18)
        postButtonConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
            return outgoing
        }
        postButton.configuration = postButtonConfiguration
        postButton.addTarget(self, action: #selector(publish), for: .touchUpInside)
        actionRowStackView.addArrangedSubview(postButton)
        actionRowStackView.isHidden = true

        let inputColumnStackView = UIStackView(
            axis: .vertical,
            spacing: 10,
            arrangedSubviews: [textView, actionRowStackView]
        )

        let rowStackView = UIStackView(
            axis: .horizontal,
            spacing: 12,
            alignment: .top,
            arrangedSubviews: [avatarBadgeView, inputColumnStackView]
        )
        cardView.addSubview(rowStackView)
        rowStackView.pinEdges(to: cardView, insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))

        let heightConstraint = textView.heightAnchor.constraint(equalToConstant: 44)
        textViewHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            heightConstraint,
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 13),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -13),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
        ])

        updatePostButtonState()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updatePostButtonState() {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        postButton.isEnabled = !trimmed.isEmpty
        postButton.alpha = trimmed.isEmpty ? 0.5 : 1
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func updateActionRowVisibility() {
        let shouldShow = textView.isFirstResponder || !textView.text.isEmpty
        guard actionRowStackView.isHidden == shouldShow else { return }
        actionRowStackView.isHidden = !shouldShow
        onHeightChange?()
    }

    @objc
    private func publish() {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onPublish?(trimmed)
        textView.text = ""
        textView.resignFirstResponder()
        updatePostButtonState()
        updateActionRowVisibility()
        onHeightChange?()
    }
}

extension ComposerCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePostButtonState()
        updateActionRowVisibility()

        // Grow up to four lines, then let the text view scroll internally.
        let maximumHeight = ceil(textView.font.map { $0.lineHeight * 4 } ?? 88) + 24
        let fittingHeight = textView.sizeThatFits(
            CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        ).height
        let clampedHeight = min(max(44, fittingHeight), maximumHeight)
        textView.isScrollEnabled = fittingHeight > maximumHeight

        guard let heightConstraint = textViewHeightConstraint, heightConstraint.constant != clampedHeight else { return }
        heightConstraint.constant = clampedHeight
        onHeightChange?()
    }

    func textViewDidBeginEditing(_: UITextView) {
        updateActionRowVisibility()
    }

    func textViewDidEndEditing(_: UITextView) {
        updateActionRowVisibility()
    }
}
