import DGCharts
import Charts
import UIKit

class BalloonMarker: MarkerImage {
    private var color: UIColor
    private var font: UIFont
    private var textColor: UIColor
    private var insets: UIEdgeInsets
    private var minimumSize = CGSize()

    private var label: String = ""
    private var labelSize: CGSize = .zero
    private var paragraphStyle: NSMutableParagraphStyle?
    private var drawAttributes = [NSAttributedString.Key: Any]()

    init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets) {
        self.color = color
        self.font = font
        self.textColor = textColor
        self.insets = insets

        super.init()

        paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.alignment = .center
    }

    override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        let size = self.size
        var offset = self.offset
        var origin = point
        origin.x -= size.width / 2
        origin.y -= size.height

        if origin.x + offset.x < 0.0 {
            offset.x = -origin.x
        } else if let chart = self.chartView,
                  origin.x + size.width + offset.x > chart.bounds.size.width {
            offset.x = chart.bounds.size.width - origin.x - size.width
        }

        if origin.y + offset.y < 0 {
            offset.y = -origin.y
        } else if let chart = self.chartView,
                  origin.y + size.height + offset.y > chart.bounds.size.height {
            offset.y = chart.bounds.size.height - origin.y - size.height
        }

        return offset
    }

    override func draw(context: CGContext, point: CGPoint) {
        guard chartView != nil else { return }

        let offset = self.offsetForDrawing(atPoint: point)
        let size = self.size

        var rect = CGRect(origin: CGPoint(
            x: point.x + offset.x,
            y: point.y + offset.y),
            size: size)

        context.saveGState()

        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        context.setFillColor(color.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()

        rect.origin.y += self.insets.top
        rect.size.height -= self.insets.top + self.insets.bottom

        UIGraphicsPushContext(context)
        label.draw(in: rect, withAttributes: drawAttributes)
        UIGraphicsPopContext()

        context.restoreGState()
    }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        label = String(format: "%.2f", entry.y)
        drawAttributes.removeAll()
        drawAttributes[.font] = font
        drawAttributes[.paragraphStyle] = paragraphStyle
        drawAttributes[.foregroundColor] = textColor

        labelSize = label.size(withAttributes: drawAttributes)

        let size = CGSize(width: labelSize.width + insets.left + insets.right,
                          height: labelSize.height + insets.top + insets.bottom)
        self.size = size
    }
}
