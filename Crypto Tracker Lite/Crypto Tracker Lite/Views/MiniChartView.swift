import UIKit

class MiniChartView: UIView {

    private var lineLayer: CAShapeLayer = CAShapeLayer()
    private var lineColor: UIColor = .systemBlue

    private var bufferedPrices: [CGFloat]?

    var prices: [CGFloat] = [] {
        didSet {
            if bounds.width > 0 && bounds.height > 0 {
                drawChart()
            } else {
                bufferedPrices = prices
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let buffered = bufferedPrices {
            prices = buffered
            bufferedPrices = nil
        } else {
            drawChart()
        }
    }

    private func setupLayer() {
        layer.addSublayer(lineLayer)
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 1.5
        lineLayer.lineJoin = .round
        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.shadowColor = UIColor.black.cgColor
        lineLayer.shadowOpacity = 0.15
        lineLayer.shadowRadius = 2
        lineLayer.shadowOffset = CGSize(width: 0, height: 2)
    }

    func setColor(_ color: UIColor) {
        self.lineColor = color
        lineLayer.strokeColor = color.cgColor
    }

    func setData(_ yValues: [CGFloat]) {
        self.prices = yValues
    }

    func setEmpty() {
        self.prices = []
        lineLayer.path = nil
    }

    private func drawChart() {
        guard prices.count > 1, bounds.width > 0, bounds.height > 0 else {
            lineLayer.path = nil
            return
        }

        let maxY = prices.max() ?? 1
        let minY = prices.min() ?? 0
        let range = max(maxY - minY, 0.01)
        let stepX = bounds.width / CGFloat(prices.count - 1)

        let path = UIBezierPath()

        // Початкова точка
        let startX: CGFloat = 0
        let startY = bounds.height * (1 - (prices[0] - minY) / range)
        path.move(to: CGPoint(x: startX, y: startY))

        // Плавна лінія
        for i in 1..<prices.count {
            let prevX = CGFloat(i - 1) * stepX
            let prevY = bounds.height * (1 - (prices[i - 1] - minY) / range)
            let currentX = CGFloat(i) * stepX
            let currentY = bounds.height * (1 - (prices[i] - minY) / range)

            let midX = (prevX + currentX) / 2
            let controlPoint1 = CGPoint(x: midX, y: prevY)
            let controlPoint2 = CGPoint(x: midX, y: currentY)

            path.addCurve(to: CGPoint(x: currentX, y: currentY),
                          controlPoint1: controlPoint1,
                          controlPoint2: controlPoint2)
        }

        lineLayer.path = path.cgPath
    }
}
