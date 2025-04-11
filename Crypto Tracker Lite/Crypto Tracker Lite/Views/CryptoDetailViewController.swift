import UIKit
import DGCharts

class CryptoDetailViewController: UIViewController {
    var crypto: Crypto?
    
    private let favoritesButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.backgroundColor = .systemGray6
        button.tintColor = .systemGray
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let priceChangeLabel = UILabel()
    private let chartView = LineChartView()
    private let timeRangeControl = UISegmentedControl(items: ["24h", "1h"])
    private var currentTimeRange: TimeRange = .day {
        didSet {
            fetchChartData()
        }
    }
    enum TimeRange {
        case day
        case hour
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupUI()
        fetchChartData()
        updateFavoritesButton()
    }
    
    private func setupUI() {
        setupDetailStack()
        setupTimeRangeControl()
        setupChartView()
        setupFavoritesButton()
    }
    
    private func setupFavoritesButton() {
            favoritesButton.addTarget(self, action: #selector(favoritesButtonTapped), for: .touchUpInside)
            view.addSubview(favoritesButton)
            
            NSLayoutConstraint.activate([
                favoritesButton.centerYAnchor.constraint(equalTo: symbolLabel.centerYAnchor),
                favoritesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                favoritesButton.widthAnchor.constraint(equalToConstant: 40),
                favoritesButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
    
    private func updateFavoritesButton() {
        guard let cryptoId = crypto?.id else { return }
        let isFavorite = FavoritesManager.shared.isFavorite(id: cryptoId)
        
        UIView.animate(withDuration: 0.3) {
            self.favoritesButton.setImage(UIImage(systemName: isFavorite ? "heart.fill" : "heart"), for: .normal)
            self.favoritesButton.tintColor = isFavorite ? .systemRed : .systemGray
            self.favoritesButton.backgroundColor = isFavorite ? .systemRed .withAlphaComponent(0.1) : .systemGray6
        }
    }
    
    @objc func favoritesButtonTapped() {
        guard let cryptoId = crypto?.id else { return }
        
        if FavoritesManager.shared.isFavorite(id: cryptoId) {
            // Видаляємо з улюблених
            FavoritesManager.shared.removeFavorite(id: cryptoId)
        } else {
            // Додаємо до улюблених
            FavoritesManager.shared.addFavorite(id: cryptoId)
        }
        updateFavoritesButton()
    }
    
    private func setupDetailStack() {
        let stack = UIStackView(arrangedSubviews: [symbolLabel, priceLabel, priceChangeLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        symbolLabel.text = crypto?.symbol.uppercased()
        symbolLabel.font = .boldSystemFont(ofSize: 18)
        
        priceLabel.text = String(format: "%.2f$", crypto?.current_price ?? 0)
        priceLabel.font = .boldSystemFont(ofSize: 28)
        
        if let change = crypto?.price_change_percentage_24h {
            priceChangeLabel.text = String(format: "%.2f%%", change)
            priceChangeLabel.font = .systemFont(ofSize: 16, weight: .medium)
            let color: UIColor = change >= 0 ? .systemGreen : .systemRed
            priceChangeLabel.textColor = color
            priceLabel.textColor = color
        }
    }
    
    private func setupTimeRangeControl() {
        timeRangeControl.selectedSegmentIndex = 0
        timeRangeControl.addTarget(self, action: #selector(timeRangeChanged), for: .valueChanged)
        timeRangeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeRangeControl)
        
        NSLayoutConstraint.activate([
            timeRangeControl.topAnchor.constraint(equalTo: priceChangeLabel.bottomAnchor, constant: 20),
            timeRangeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timeRangeControl.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    @objc private func timeRangeChanged() {
        currentTimeRange = timeRangeControl.selectedSegmentIndex == 0 ? .day : .hour
    }
    
    private func setupChartView() {
        chartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chartView)
        
        // Ось ключові зміни - фіксуємо висоту графіка на 30% екрана
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: timeRangeControl.bottomAnchor, constant: 20),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chartView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3) // 30% висоти екрана
        ])
        
        configureChartAppearance()
    }
    
    private func configureChartAppearance() {
        chartView.chartDescription.enabled = true
        chartView.chartDescription.text = currentTimeRange == .day ? "Price over 24h" : "Price over 1h"
        chartView.chartDescription.font = .systemFont(ofSize: 12)
        chartView.chartDescription.textColor = .secondaryLabel
        
        chartView.legend.enabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.animate(xAxisDuration: 1.5)
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.labelTextColor = .secondaryLabel
        xAxis.gridColor = .systemGray4
        xAxis.avoidFirstLastClippingEnabled = true
        
        
        chartView.leftAxis.labelFont = .systemFont(ofSize: 6)
        chartView.leftAxis.labelTextColor = .secondaryLabel
        chartView.leftAxis.gridColor = .systemGray4
        chartView.rightAxis.enabled = false
        chartView.xAxis.setLabelCount(7, force: true)
        
    }
    
    private func fetchChartData() {
        guard let id = crypto?.id else { return }
        
        let urlString: String
        if currentTimeRange == .day {
            urlString = "https://api.coingecko.com/api/v3/coins/\(id)/market_chart?vs_currency=usd&days=1"
        } else {
            let now = Int(Date().timeIntervalSince1970)
            let oneHourAgo = now - 3600
            urlString = "https://api.coingecko.com/api/v3/coins/\(id)/market_chart/range?vs_currency=usd&from=\(oneHourAgo)&to=\(now)"
        }
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                print("Error fetching data:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            do {
                let chartData = try JSONDecoder().decode(ChartData.self, from: data)
                let entries = chartData.prices.map { ChartDataEntry(x: $0[0], y: $0[1]) }
                
                DispatchQueue.main.async {
                    self.updateChart(with: entries)
                }
            } catch {
                print("Error decoding data:", error.localizedDescription)
            }
        }.resume()
    }
    
    private func updateChart(with entries: [ChartDataEntry]) {
        guard !entries.isEmpty else { return }
        
        // 1. Обчислюємо середню ціну
        let sum = entries.reduce(0) { $0 + $1.y }
        let averagePrice = sum / Double(entries.count)
        
        // 2. Розділяємо точки на ділянки вище/нижче середньої
        var segments = [(entries: [ChartDataEntry], isAboveAverage: Bool)]()
        var currentSegment = [ChartDataEntry]()
        var currentIsAbove = entries.first?.y ?? 0 >= averagePrice
        
        for entry in entries {
            let isAbove = entry.y >= averagePrice
            if isAbove != currentIsAbove {
                // Додаємо точку перетину
                if let last = currentSegment.last {
                    let ratio = (averagePrice - last.y) / (entry.y - last.y)
                    let x = last.x + ratio * (entry.x - last.x)
                    let intersection = ChartDataEntry(x: x, y: averagePrice)
                    currentSegment.append(intersection)
                }
                segments.append((currentSegment, currentIsAbove))
                currentSegment = currentSegment.isEmpty ? [] : [currentSegment.last!]
                currentIsAbove = isAbove
            }
            currentSegment.append(entry)
        }
        segments.append((currentSegment, currentIsAbove))
        
        // 3. Створюємо набори даних для кожного сегмента
        var dataSets = [LineChartDataSet]()
        for segment in segments {
            guard !segment.entries.isEmpty else { continue }
            
            let dataSet = LineChartDataSet(entries: segment.entries, label: "")
            dataSet.colors = [segment.isAboveAverage ? .systemGreen : .systemRed]
            dataSet.lineWidth = 2.5
            dataSet.drawCirclesEnabled = false
            dataSet.mode = .linear
            dataSet.drawValuesEnabled = false
            dataSets.append(dataSet)
        }
        
        // 4. Лінія середньої ціни
        let averageDataSet = LineChartDataSet(
            entries: [
                ChartDataEntry(x: entries.first?.x ?? 0, y: averagePrice),
                ChartDataEntry(x: entries.last?.x ?? 0, y: averagePrice)
            ],
            label: ""
        )
        averageDataSet.colors = [.darkGray]
        averageDataSet.lineWidth = 1.0
        averageDataSet.drawCirclesEnabled = false
        averageDataSet.drawValuesEnabled = false
        averageDataSet.lineDashLengths = [4, 2]
        dataSets.append(averageDataSet)
        
        // 5. Налаштовуємо вісь X
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = currentTimeRange == .hour ? "HH:mm" : "HH"
        chartView.xAxis.valueFormatter = DefaultAxisValueFormatter { value, _ in
            dateFormatter.string(from: Date(timeIntervalSince1970: value/1000))
        }
        chartView.xAxis.setLabelCount(6, force: false)
        chartView.xAxis.granularity = 1
        
        // 6. Налаштовуємо дані
        chartView.data = LineChartData(dataSets: dataSets)
        chartView.notifyDataSetChanged()
    }
}
