import UIKit
import DGCharts
import Charts

class MiniChartView: UIView {
    private let lineChartView = LineChartView()
    private var lineColor: UIColor = .systemBlue

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChart()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupChart() {
        let stack = UIStackView(arrangedSubviews: [lineChartView])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        backgroundColor = .clear
        lineChartView.backgroundColor = .clear
        lineChartView.gridBackgroundColor = .clear
        lineChartView.legend.enabled = false
        lineChartView.rightAxis.enabled = false
        lineChartView.leftAxis.enabled = false
        lineChartView.xAxis.enabled = false
        lineChartView.isUserInteractionEnabled = false
        lineChartView.noDataText = "No chart data"
        lineChartView.noDataTextColor = .secondaryLabel
    }

    func setData(_ entries: [ChartDataEntry]) {
        let dataSet = LineChartDataSet(entries: entries, label: "")
        dataSet.colors = [lineColor]
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 1.5
        dataSet.drawValuesEnabled = false
        dataSet.mode = .cubicBezier

        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        lineChartView.animate(xAxisDuration: 0.4)
    }

    func setEmpty() {
        lineChartView.data = nil
    }

    func setColor(_ color: UIColor) {
        self.lineColor = color
    }
}

