import UIKit
import DGCharts
import SDWebImage

class CryptoCell: UITableViewCell {

    static var chartCache: [String: [ChartDataEntry]] = [:]

    private let rankLabel = UILabel()
    private let iconImageView = UIImageView()
    private let symbolLabel = UILabel()
    private let marketCapLabel = UILabel()
    private let priceLabel = UILabel()
    private let chartView = MiniChartView()
    private let priceChangeLabel = UILabel()

    private var currentCryptoId: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureBasicInfo(with crypto: Crypto) {
        self.currentCryptoId = crypto.id

        rankLabel.text = "\(crypto.market_cap_rank)"
        symbolLabel.text = crypto.symbol.uppercased()

        if let change = crypto.price_change_percentage_24h {
            let text = String(format: "%.2f%%", change)
            priceChangeLabel.text = text
            if change >= -0.01 {
                priceChangeLabel.textColor = .systemGreen
                chartView.setColor(.systemGreen)
            } else {
                priceChangeLabel.textColor = .systemRed
                chartView.setColor(.systemRed)
            }
        } else {
            priceChangeLabel.text = "24h: N/A"
            priceChangeLabel.textColor = .gray
            chartView.setColor(.gray)
        }

        if let marketCap = crypto.market_cap {
            let billions = Double(marketCap) / 1_000_000_000
            marketCapLabel.text = String(format: "$%.2fB", billions)
        } else {
            marketCapLabel.text = "Market Cap: N/A"
        }

        priceLabel.text = String(format: "$%.2f", crypto.current_price)

        if let url = URL(string: crypto.image) {
            iconImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "bitcoinsign.circle"))
        }

        if let cached = CryptoCell.chartCache[crypto.id] {
            chartView.setData(cached)
        } else {
            chartView.setEmpty()
        }
    }

    func loadChart(for id: String) {
        self.currentCryptoId = id

        if let cached = CryptoCell.chartCache[id] {
            DispatchQueue.main.async {
                if self.currentCryptoId == id {
                    self.chartView.setData(cached)
                }
            }
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let urlStr = "https://api.coingecko.com/api/v3/coins/\(id)/market_chart?vs_currency=usd&days=1"
            guard let url = URL(string: urlStr) else { return }

            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else { return }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let prices = json["prices"] as? [[Any]], !prices.isEmpty {
                        var entries = [ChartDataEntry]()
                        for item in prices {
                            if let timestamp = item[0] as? Double,
                               let price = item[1] as? Double {
                                let x = timestamp / 1000
                                entries.append(ChartDataEntry(x: x, y: price))
                            }
                        }

                        if entries.isEmpty {
                            DispatchQueue.main.async {
                                if self.currentCryptoId == id {
                                    self.chartView.setEmpty()
                                }
                            }
                            return
                        }

                        CryptoCell.chartCache[id] = entries

                        DispatchQueue.main.async {
                            if self.currentCryptoId == id {
                                self.chartView.setData(entries)
                            }
                        }
                    }
                } catch {
                    print("Chart error for \(id)")
                }
            }.resume()
        }
    }

    private func setupViews() {
        rankLabel.font = .systemFont(ofSize: 14, weight: .medium)
        rankLabel.textColor = .secondaryLabel
        rankLabel.textAlignment = .center
        rankLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 20
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        symbolLabel.font = .boldSystemFont(ofSize: 16)
        marketCapLabel.font = .systemFont(ofSize: 12)
        marketCapLabel.textColor = .secondaryLabel

        let infoStack = UIStackView(arrangedSubviews: [symbolLabel, marketCapLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.setContentHuggingPriority(.required, for: .horizontal)
        infoStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        infoStack.widthAnchor.constraint(lessThanOrEqualToConstant: 70).isActive = true


        priceLabel.font = .systemFont(ofSize: 16, weight: .medium)
        priceLabel.textAlignment = .center
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true


        let leftStack = UIStackView(arrangedSubviews: [rankLabel, iconImageView, infoStack, priceLabel])
        leftStack.axis = .horizontal
        leftStack.alignment = .center
        leftStack.spacing = 2
        leftStack.setContentHuggingPriority(.required, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        chartView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        chartView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        priceChangeLabel.font = .systemFont(ofSize: 13)
        priceChangeLabel.textAlignment = .center
        priceChangeLabel.setContentHuggingPriority(.required, for: .horizontal)
        


        let rightStack = UIStackView(arrangedSubviews: [chartView, priceChangeLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .fill
        rightStack.distribution = .fillEqually
        
        
      

        let mainStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 12
        mainStack.distribution = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
}

