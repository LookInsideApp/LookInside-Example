import UIKit

/// Bitmaps for the TVUIKit content configurations, which take a `UIImage`
/// rather than a view: the demo has no artwork files, so it draws them.
enum ArtworkImage {
    /// A diagonal gradient with a white SF Symbol in the middle.
    static func gradientTile(symbolName: String, tint: UIColor, size: CGSize, symbolPointSize: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            drawGradient(tint: tint, size: size, in: rendererContext.cgContext)
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .light)
            if let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            {
                symbolImage.draw(at: CGPoint(
                    x: (size.width - symbolImage.size.width) / 2,
                    y: (size.height - symbolImage.size.height) / 2
                ))
            }
        }
    }

    /// A gradient square with centred initials. The monogram cell crops it to
    /// a circle.
    static func monogram(initials: String, tint: UIColor, side: CGFloat) -> UIImage {
        let size = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            drawGradient(tint: tint, size: size, in: rendererContext.cgContext)
            let attributedInitials = NSAttributedString(string: initials, attributes: [
                .font: UIFont.systemFont(ofSize: side * 0.38, weight: .bold),
                .foregroundColor: UIColor.white,
            ])
            let textSize = attributedInitials.size()
            attributedInitials.draw(at: CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            ))
        }
    }

    /// A Settings-style icon tile, for button configurations that take an
    /// image rather than a view.
    static func symbolTile(symbolName: String, tint: UIColor, side: CGFloat) -> UIImage {
        let tileSize = CGSize(width: side, height: side)
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: side * 0.46, weight: .semibold)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        return UIGraphicsImageRenderer(size: tileSize).image { _ in
            tint.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: tileSize), cornerRadius: side * 0.26).fill()
            if let symbolImage {
                symbolImage.draw(at: CGPoint(
                    x: (tileSize.width - symbolImage.size.width) / 2,
                    y: (tileSize.height - symbolImage.size.height) / 2
                ))
            }
        }
        // A button would otherwise tint the whole tile with its own colour.
        .withRenderingMode(.alwaysOriginal)
    }

    private static func drawGradient(tint: UIColor, size: CGSize, in graphicsContext: CGContext) {
        let gradientColors = [tint.cgColor, tint.withAlphaComponent(0.55).cgColor] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: gradientColors,
            locations: [0, 1]
        ) else { return }
        graphicsContext.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )
    }
}
