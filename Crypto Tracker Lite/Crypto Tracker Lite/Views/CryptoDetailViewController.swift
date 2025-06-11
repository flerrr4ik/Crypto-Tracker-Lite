import UIKit
import DGCharts
import Charts
import UserNotifications

class CryptoDetailViewController: UIViewController {
    
    // MARK: - Models
    
    var crypto: Crypto?
    var detailedCrypto: DetailedCrypto?
    var exchangeLogos: [String: String] = [:]
    
    private var tickers: [Ticker] = []
    private var exchangeURLs: [String: String] = [:]
    
    
    // MARK: - Chart & Time Range
    
    private var currentChartTask: URLSessionDataTask?
    private var isLoadingChart = false
    private var lastChartRequestTime: Date?
    private var chartCache: [TimeRange: [ChartDataEntry]] = [:]
    private var currentTimeRange: TimeRange = .day {
        didSet { fetchChartData() }
    }
    
    // MARK: - Strings
    
    private var githubURLString: String?
    private var twitterURLString: String?
    private var redditURLString: String?
    private var webSiteURLString: String?
    private var cryptoDescription: String?
    
    // MARK: - Labels
    
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let priceChangeLabel = UILabel()
    private let marketCapLabel = UILabel()
    private let nameLabel = UILabel()
    private let rankLabel = UILabel()
    private let totalSupplyLabel = UILabel()
    private let circulatingSupplyLabel = UILabel()
    private let volumeLabel = UILabel()
    private let allTimeHighLabel = UILabel()
    private let titleRankLabel = UILabel()
    private let titleTotalSupplyLabel = UILabel()
    private let titleCirculatingSupplyLabel = UILabel()
    private let titleVolumeLabel = UILabel()
    private let titleAllTimeHighLabel = UILabel()
    private let titleAllTimeLowLabel = UILabel()
    
    // MARK: - ImageViews & Chart
    
    private let logoImageView = UIImageView()
    private let chartView = LineChartView()
    
    // MARK: - Buttons
    
    private let gitHubButton = makeSocialButton(named: "github", title: "   GitHub")
    private let twitterButton = makeSocialButton(named: "twitter", title: "   Twitter")
    private let redditButton = makeSocialButton(named: "reddit", title: "   Reddit")
    private let webSiteButton = makeSocialButton(named: "website", title: "   Website")
    
    private let favoriteButton = makeButton(named: "notFavorite")
    private let descriptionButton = makeButton(named: "info")
    private let notificationButton = makeButton(named: "notification")
    
    // MARK: - Controls & Views
    
    private let timeRangeControl = UISegmentedControl(items: ["1h", "24h", "7d", "30d", "90d"])
    private let infoTableView = UITableView()
    private var infoRows: [InfoRow] = []
    private var priceCheckTimer: Timer?
    
    // MARK: - Stacks & CollectonView
    
    private lazy var marketsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 70)
        layout.minimumLineSpacing = 8
        layout.sectionInset = .init(top: 0, left: 4, bottom: 0, right: 4)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(MarketCell.self, forCellWithReuseIdentifier: "MarketCell")
        return collectionView
    }()
    
    private lazy var miniDetailStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [symbolLabel, priceChangeLabel,])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var mainDetailStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [miniDetailStack, priceLabel, marketCapLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.layer.cornerRadius = 20
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var labelInfoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, logoImageView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    private lazy var buttonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [favoriteButton, descriptionButton, notificationButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var socialMediaStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [webSiteButton, twitterButton, redditButton, gitHubButton])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    private let fadeMask = CAGradientLayer()
    
    override func viewDidLoad() {
        //        view.backgroundColor = UIColor(red: 225/255, green: 222/255, blue: 245/255, alpha: 1)
        view.backgroundColor = .systemBackground
        requestNotificationPermission()
        setupSubviews()
        setupActions()
        setupDelegates()
        setupTableView()
        setupTimeRangeControl()
        setupChartView()
        updateFavoritesButton()
        fetchChartData()
        setupConstraints()
        startPriceMonitoring()
        updateNotificationButton()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Notifications allowed")
            } else {
                print("❌ Notifications denied")
            }
        }
        
        if let crypto = crypto {
            configureWithCrypto(crypto)
            fetchDetailedInfo(for: crypto.id)
            fetchExchangesAndTickers(for: crypto.id)
        }
        
        if let change = crypto?.price_change_percentage_24h {
            updatePriceChange(change)
        }
        loadLogo(from: crypto?.image ?? "")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyGradientBackground(to: mainDetailStack)
    }
    
    private func setupSubviews() {
        [mainDetailStack, timeRangeControl, chartView, marketsCollectionView, labelInfoStack, socialMediaStack, infoTableView, buttonsStack].forEach {
            view.addSubview($0)
        }
    }
    private func setupActions() {
        gitHubButton.addTarget(self, action: #selector(gitHubButtonTapped), for: .touchUpInside)
        twitterButton.addTarget(self, action: #selector(twitterButtonTapped), for: .touchUpInside)
        redditButton.addTarget(self, action: #selector(redditButtonTapped), for: .touchUpInside)
        webSiteButton.addTarget(self, action: #selector(webSiteButtonTapped), for: .touchUpInside)
        descriptionButton.addTarget(self, action: #selector(descriptionButtonTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoritesButtonTapped), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        infoTableView.register(InfoCell.self, forCellReuseIdentifier: InfoCell.identifier)
        infoTableView.translatesAutoresizingMaskIntoConstraints = false
        infoTableView.backgroundColor = .clear
    }
    private func qqqqq() {
        priceLabel.backgroundColor = .green.withAlphaComponent(0.2)
    }
    private func setupDelegates() {
        infoTableView.dataSource = self
        marketsCollectionView.delegate = self
        marketsCollectionView.dataSource = self
    }
    private func configureWithCrypto(_ crypto: Crypto) {
        nameLabel.text = crypto.name
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textColor = .label
        rankLabel.text = "\(crypto.market_cap_rank)"
        
        symbolLabel.text = crypto.symbol.uppercased()
        symbolLabel.font = .systemFont(ofSize: 26, weight: .medium)
        
        priceLabel.text = String(format: "%.2f$", crypto.current_price)
        priceLabel.font = .monospacedDigitSystemFont(ofSize: 26, weight: .regular)
        priceLabel.textColor = .label
      
        if let marketCap = crypto.market_cap {
            let billions = Double(marketCap) / 1_000_000_000
            let smallText = NSAttributedString(
                string: "Market Cap:\n",
                attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: UIColor.label.withAlphaComponent(0.4)] )
            
            let bigText = NSAttributedString(
                string:  "\(String(format: "$%.2fB", billions))",
                attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .bold)] )
            
            let combined = NSMutableAttributedString()
            combined.append(smallText)
            combined.append(bigText)
            marketCapLabel.numberOfLines = 0
            marketCapLabel.attributedText = combined
        }
           
        
        if let url = URL(string: crypto.image) {
            logoImageView.sd_setImage(with: url)
        }
    }
    private func updatePriceChange(_ change: Double) {
        priceChangeLabel.font = .systemFont(ofSize: 16, weight: .medium)
        let color: UIColor = change >= 0 ? .systemGreen : .systemRed
        priceChangeLabel.textColor = color
        priceLabel.textColor = color
        
        let arrow: String = change >= 0 ? " ▲" : " ▼"
        priceChangeLabel.text = String(format: "%.2f%%", change) + arrow
        
            
        if let id = crypto?.id {
            let key = "alert_\(id)"
            let alertPrice = UserDefaults.standard.double(forKey: key)
            
            if alertPrice > 0 {
                if (change >= 0 && crypto?.current_price ?? 0 >= alertPrice) ||
                    (change < 0 && crypto?.current_price ?? 0 <= alertPrice) {
                    sendNotification(for: crypto?.name ?? "Crypto", target: alertPrice)
                    
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
    }
    
    private func loadLogo(from urlString: String) {
        if let url = URL(string: urlString) {
            logoImageView.sd_setImage(with: url)
        }
    }
    
    private func fetchDetailedInfo(for id: String) {
        APIService.shared.fetchDetail(for: id) { [weak self] detailedCrypto in
            guard let self = self, let detailedCrypto = detailedCrypto else { return }
            
            DispatchQueue.main.async { [self] in
                self.githubURLString = detailedCrypto.links.repos_url.github.first
                self.twitterURLString = "https://twitter.com/\(detailedCrypto.links.twitter_screen_name ?? "")"
                self.redditURLString = detailedCrypto.links.subreddit_url
                self.webSiteURLString = detailedCrypto.links.homepage.first
                guard let volume = detailedCrypto.marketData?.totalVolume?["usd"] ?? 0 else { return }
                self.volumeLabel.text = "$\(self.formatNumber(volume)) USD"
                guard let totalSupply = detailedCrypto.marketData?.totalSupply else { return }
                self.totalSupplyLabel.text = " \(self.formatNumber(totalSupply))"
                guard let circulatingSupply = detailedCrypto.marketData?.circulatingSupply else { return }
                self.circulatingSupplyLabel.text = "\(self.formatNumber(circulatingSupply))"
                guard let ath = detailedCrypto.marketData?.ath?["usd"] else { return }
                self.allTimeHighLabel.text = "$\(self.formatNumber(ath))"
                let description = detailedCrypto.description.en
                self.cryptoDescription = "\(description)"
                
                self.infoRows = [
                    InfoRow(title: "Rank", value: "\(self.crypto?.market_cap_rank ?? 0)"),
                    InfoRow(title: "Volume", value: "$\(self.formatNumber(volume))"),
                    InfoRow(title: "ATH", value: "$\(self.formatNumber(ath))"),
                    InfoRow(title: "Total Supply", value: self.formatNumber(totalSupply)),
                    InfoRow(title: "Circulating Supply", value: self.formatNumber(circulatingSupply))
                ]
                
                self.infoTableView.reloadData()
            }
        }
    }
    
    private func fetchExchangesAndTickers(for id: String) {
        APIService.shared.fetchExchanges { [weak self] exchanges in
            guard let self = self, let exchanges = exchanges else { return }
            
            DispatchQueue.main.async {
                exchanges.forEach {
                    self.exchangeLogos[$0.name] = $0.image
                    self.exchangeURLs[$0.name] = $0.url
                }
                
                // Тепер тикери обробляються після того, як логотипи і URL завантажені
                APIService.shared.fetchTickers(for: id) { result in
                    guard let result = result else { return }
                    let filtered = result.filter {
                        self.exchangeLogos[$0.market.name] != nil &&
                        self.exchangeURLs[$0.market.name] != nil
                    }
                    let sorted = filtered.sorted { ($0.volume ?? 0) > ($1.volume ?? 0) }
                    
                    var seenExchanges = Set<String>()
                    let unique = sorted.filter { seenExchanges.insert($0.market.name).inserted }
                    
                    DispatchQueue.main.async {
                        self.tickers = unique
                        self.marketsCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            labelInfoStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            labelInfoStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
//            miniDetailStack.heightAnchor.constraint(equalToConstant: 40),
//            marketCapLabel.heightAnchor.constraint(equalToConstant: 54),
            priceLabel.heightAnchor.constraint(equalToConstant: 40),
            
            logoImageView.widthAnchor.constraint(equalToConstant: 32),
            logoImageView.heightAnchor.constraint(equalToConstant: 32),
            
            descriptionButton.widthAnchor.constraint(equalToConstant: 40),
            descriptionButton.heightAnchor.constraint(equalToConstant: 40),
           
            notificationButton.widthAnchor.constraint(equalToConstant: 40),
            notificationButton.heightAnchor.constraint(equalToConstant: 40),
           
            favoriteButton.widthAnchor.constraint(equalToConstant: 40),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40),
            
            buttonsStack.topAnchor.constraint(equalTo: socialMediaStack.topAnchor),
            buttonsStack.leadingAnchor.constraint(equalTo: socialMediaStack.trailingAnchor, constant: 12),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(equalTo: socialMediaStack.bottomAnchor ),
            
            mainDetailStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainDetailStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainDetailStack.widthAnchor.constraint(equalToConstant: 155),
            
            socialMediaStack.topAnchor.constraint(equalTo: mainDetailStack.topAnchor, constant: 0),
            socialMediaStack.leadingAnchor.constraint(equalTo: mainDetailStack.trailingAnchor, constant: 8),
            socialMediaStack.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            socialMediaStack.bottomAnchor.constraint(equalTo: mainDetailStack.bottomAnchor, constant: 0),
            
            gitHubButton.heightAnchor.constraint(equalToConstant: 30),
            gitHubButton.widthAnchor.constraint(equalToConstant: 165),
            
            twitterButton.heightAnchor.constraint(equalToConstant: 30),
            twitterButton.widthAnchor.constraint(equalToConstant: 165),
            
            redditButton.heightAnchor.constraint(equalToConstant: 30),
            redditButton.widthAnchor.constraint(equalToConstant: 165),
            
            webSiteButton.heightAnchor.constraint(equalToConstant: 30),
            webSiteButton.widthAnchor.constraint(equalToConstant: 165),
            
            chartView.topAnchor.constraint(equalTo: timeRangeControl.bottomAnchor, constant: 20),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.24),
            
            marketsCollectionView.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 2),
            marketsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            marketsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            marketsCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            infoTableView.topAnchor.constraint(equalTo: marketsCollectionView.bottomAnchor, constant: 0),
            infoTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoTableView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private static func makeSocialButton(named: String, title: String) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(named: named)?.withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        button.tintColor = .systemBlue
        button.setTitleColor(.systemGray, for: .normal)
        button.backgroundColor = .systemGray.withAlphaComponent(0.08)
        button.layer.cornerRadius = 20
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .leading
        button.semanticContentAttribute = .forceLeftToRight
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        return button
    }
    
    private static func makeButton(named: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: named), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func applyGradientBackground(to view: UIView) {
        // Уникнути дублювання
        if let sublayers = view.layer.sublayers,
           sublayers.contains(where: { $0.name == "fadeGradient" }) {
            return
        }

        let gradient = CAGradientLayer()
        gradient.name = "fadeGradient"
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.systemGray.withAlphaComponent(0.08).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5) // 👉 Зліва
        gradient.endPoint = CGPoint(x: 1, y: 0.5)   // 👉 Направо
        gradient.frame = view.bounds
        gradient.cornerRadius = view.layer.cornerRadius

        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private func updateFavoritesButton() {
        guard let cryptoId = crypto?.id else { return }
        let isFavorite = FavoritesManager.shared.isFavorite(id: cryptoId)
        
        UIView.animate(withDuration: 0.3) {
            self.favoriteButton.setImage(UIImage(named: isFavorite ? "favorite" : "notFavorite"), for: .normal)
        }
    }
    
    private func updateNotificationButton() {
            guard let cryptoID = crypto?.id else { return }
        let key = "alert_\(cryptoID)"
        let alertPrice = UserDefaults.standard.double(forKey: key)
        
        let imageName = alertPrice > 0 ? "notificationOn" : "notification"
        UIView.transition(with: notificationButton, duration: 0.25, animations: {
            self.notificationButton.setImage(UIImage(named: imageName), for: .normal)
        })
        }
    
    private func setupTimeRangeControl() {
        timeRangeControl.selectedSegmentIndex = 1
        timeRangeControl.addTarget(self, action: #selector(timeRangeChanged), for: .valueChanged)
        timeRangeControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeRangeControl.topAnchor.constraint(equalTo: mainDetailStack.bottomAnchor, constant: 16),
            timeRangeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timeRangeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeRangeControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @objc private func timeRangeChanged() {
        let now = Date()
        if let last = lastChartRequestTime, now.timeIntervalSince(last) < 1.5 {
            print("⏳ Занадто швидке перемикання — ігноруємо")
            return
        }
        lastChartRequestTime = now
        
        if let selected = TimeRange(rawValue: timeRangeControl.selectedSegmentIndex) {
            currentTimeRange = selected
        }
    }
    
    private func setupChartView() {
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        configureChartAppearance()
        
        let marker = BalloonMarker(
            color: UIColor.systemIndigo.withAlphaComponent(0.9),
            font: .systemFont(ofSize: 12, weight: .medium),
            textColor: .white,
            insets: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        )
        marker.chartView = chartView
        chartView.marker = marker
    }
    
    private func configureChartAppearance() {
        chartView.chartDescription.enabled = false
        chartView.legend.enabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.labelTextColor = .secondaryLabel
        xAxis.gridColor = .systemGray4
        xAxis.avoidFirstLastClippingEnabled = true
        chartView.rightAxis.enabled = false
        chartView.leftAxis.labelFont = .systemFont(ofSize: 6)
        chartView.leftAxis.labelTextColor = .secondaryLabel
        chartView.leftAxis.gridColor = .systemGray4
    }
    
    private func fetchChartData() {
        guard let id = crypto?.id else { return }
        
        if let cached = chartCache[currentTimeRange] {
            updateChart(with: cached)
            return
        }
        
        isLoadingChart = true
        timeRangeControl.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.timeRangeControl.isEnabled = true
        }
        
        currentChartTask?.cancel()
        
        let urlString = "https://api.coingecko.com/api/v3/coins/\(id)/market_chart?vs_currency=usd&days=\(currentTimeRange.daysParameter)"
        
        guard let url = URL(string: urlString) else {
            isLoadingChart = false
            print("❌ Некоректний URL: \(urlString)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { self.isLoadingChart = false }
            
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Відсутня HTTP відповідь")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP помилка: \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("❌ Порожні дані у відповіді")
                return
            }
            
            do {
                let chartData = try JSONDecoder().decode(ChartData.self, from: data)
                let entries = chartData.prices.map { ChartDataEntry(x: $0[0], y: $0[1]) }
                self.chartCache[self.currentTimeRange] = entries
                
                DispatchQueue.main.async {
                    self.updateChart(with: entries)
                }
            } catch {
                if let raw = String(data: data, encoding: .utf8) {
                    print("❌ JSON decode error: \(error)\n🔎 Raw response:\n\(raw)")
                } else {
                    print("❌ JSON decode error: \(error)")
                }
            }
        }
        
        currentChartTask = task
        task.resume()
    }
    
    private func updateChart(with entries: [ChartDataEntry]) {
        guard !entries.isEmpty else { return }
        
        chartView.clear()
        let maxEntries = 1000
        let trimmedEntries = entries.suffix(maxEntries)
        
        let avg = trimmedEntries.map { $0.y }.reduce(0, +) / Double(trimmedEntries.count)
        
        let dataSet = LineChartDataSet(entries: Array(trimmedEntries), label: "")
        dataSet.colors = [UIColor.systemGreen.withAlphaComponent(0.6)]
        dataSet.lineWidth = 1.5
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.mode = .linear
        
        // Градієнтна тінь під графіком з адаптивним співвідношенням
        dataSet.drawFilledEnabled = true
        let minY = trimmedEntries.map { $0.y }.min() ?? 0
        let maxY = trimmedEntries.map { $0.y }.max() ?? 1
        let ratio = CGFloat((avg - minY) / (maxY - minY))
        
        let topColor = UIColor.systemRed.cgColor
        let bottomColor = UIColor.systemGreen.cgColor
        let gradientColors = [topColor, bottomColor] as CFArray
        let colorLocations: [CGFloat] = [0.0, ratio]
        
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: gradientColors,
                                     locations: colorLocations) {
            dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90)
        }
        
        let chartData = LineChartData(dataSet: dataSet)
        chartView.data = chartData
        
        // Лінія середньої ціни
        let avgLine = ChartLimitLine(limit: avg, label: String(format: "Avg: %.2f", avg))
        avgLine.lineWidth = 1
        avgLine.lineDashLengths = [4, 2]
        avgLine.lineColor = .systemGray2
        avgLine.labelPosition = .rightTop
        avgLine.valueFont = .systemFont(ofSize: 10)
        
        chartView.leftAxis.removeAllLimitLines()
        chartView.leftAxis.addLimitLine(avgLine)
        chartView.leftAxis.axisMinimum = minY * 0.98
        chartView.leftAxis.axisMaximum = maxY * 1.02
        
        switch currentTimeRange {
        case .hour:
            chartView.xAxis.valueFormatter = DateAxisValueFormatter(format: "HH:mm")
        case .day:
            chartView.xAxis.valueFormatter = DateAxisValueFormatter(format: "HH:mm")
        case .week:
            chartView.xAxis.valueFormatter = DateAxisValueFormatter(format: "E")
        case .month, .threeMonths:
            chartView.xAxis.valueFormatter = DateAxisValueFormatter(format: "d MMM")
        }
        
        chartView.xAxis.setLabelCount(6, force: true)
        chartView.notifyDataSetChanged()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notifications allowed")
            } else {
                print("Notifications denied")
            }
        }
    }
    
    private func sendNotification(for name: String, target: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(name) hit your target"
        content.body = "The price has reached $\(target)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "UUID().uuidString", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            } else {
                print("Nititfication sheduled")
            }
        }
    }
    
    private func startPriceMonitoring() {
        priceCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [ weak self ] _ in
            self?.checkPriceForNotification()
        }
    }
    
    private func checkPriceForNotification() {
        guard let id = crypto?.id else { return }
        
        // Отримуємо цільову ціну з UserDefaults
        let key = "alert_\(id)"
        let targetPrice = UserDefaults.standard.double(forKey: key)
        
        // Завантажуємо актуальну ціну
        
        let operation = CryptoFetchOperation(cryptoID: id, targetPrice: targetPrice)
        let queue = OperationQueue()
        queue.addOperation(operation)
    }
    
    
    @objc private func gitHubButtonTapped() {
        guard let urlString = githubURLString,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc func twitterButtonTapped() {
        guard let urlString = twitterURLString,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc private func redditButtonTapped() {
        guard let urlString = redditURLString,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc private func webSiteButtonTapped() {
        guard let urlString = webSiteURLString,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc private func descriptionButtonTapped() {
        let textVC = DescriptionViewController()
        textVC.textView.text = cryptoDescription
        textVC.modalPresentationStyle = .pageSheet
        
        if let sheet = textVC.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in 700 })]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(textVC, animated: true)
    }
    @objc func favoritesButtonTapped() {
        guard let cryptoId = crypto?.id else { return }
        
        if FavoritesManager.shared.isFavorite(id: cryptoId) {
            FavoritesManager.shared.removeFavorite(id: cryptoId)
        } else {
            FavoritesManager.shared.addFavorite(id: cryptoId)
        }
        updateFavoritesButton()
    }
    
    @objc private func notificationButtonTapped() {
        
        guard let cryptoID = crypto?.id else { return }
        let key = "alert_\(cryptoID)"
        let currentTarget = UserDefaults.standard.double(forKey: key)
        
        if currentTarget > 0 {
            let alert = UIAlertController(title: "Delete notification?", message: "Target price: $\(currentTarget)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                UserDefaults.standard.removeObject(forKey: key)
                self.updateNotificationButton()
                print("Notification deleted")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            
            let alert = UIAlertController(title: "Сповіщення", message: "Введи цільову ціну", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Наприклад: 70000"
                textField.keyboardType = .decimalPad
            }
            let confirm = UIAlertAction(title: "Увімкнути", style: .default) { [weak self] _ in
                guard let self = self,
                      let text = alert.textFields?.first?.text,
                      let targetPrice = Double(text) else { return }
                
                UserDefaults.standard.set(targetPrice, forKey: key)
                UserDefaults.standard.set(targetPrice, forKey: "alert_\(cryptoID)")
                updateNotificationButton()
                
                print("🔔 Notification set for \(cryptoID) at $\(targetPrice)")
            }
            alert.addAction(confirm)
            alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
            present(alert, animated: true)
        }
    }
}

extension CryptoDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let ticker = tickers[indexPath.item]
        let logoURL = exchangeLogos[ticker.market.name]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MarketCell", for: indexPath) as! MarketCell
        cell.configure(with: ticker, logoURL: logoURL)
        return cell
    }
}

extension CryptoDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ticker = tickers[indexPath.item]
        let name = ticker.market.name
        
        if let urlString = exchangeURLs[name], let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            print("Немає URL для біржі \(name)")
        }
    }
}

extension CryptoDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InfoCell.identifier, for: indexPath) as? InfoCell else {
            return UITableViewCell()
        }
        let item = infoRows[indexPath.row]
        cell.configure(with: item)
        cell.selectionStyle = .none
        return cell
    }
}

extension CryptoDetailViewController {
    enum TimeRange: Int, CaseIterable {
        case hour = 0, day, week, month, threeMonths
        var daysParameter: String {
            switch self {
            case .hour: return "1"
            case .day: return "1"
            case .week: return "7"
            case .month: return "30"
            case .threeMonths: return "90"
            }
        }
        var displayName: String {
            switch self {
            case .hour: return "1h"
            case .day: return "24h"
            case .week: return "7d"
            case .month: return "30d"
            case .threeMonths: return "90d"
            }
        }
    }
    class DateAxisValueFormatter: AxisValueFormatter {
        private let dateFormatter: DateFormatter
        init(format: String) {
            dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
        }
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let date = Date(timeIntervalSince1970: value / 1000)
            return dateFormatter.string(from: date)
        }
    }
}
