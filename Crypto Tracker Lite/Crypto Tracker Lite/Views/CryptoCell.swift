import UIKit
import SDWebImage

class CryptoCell: UITableViewCell {

    private let rankLabel = UILabel()
    private let iconImageView = UIImageView()
    private let symbolLabel = UILabel()
    private let marketCapLabel = UILabel()
    private let priceLabel = UILabel()
    private let chartView = MiniChartView()
    private let priceChangeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureBasicInfo(with crypto: Crypto) {
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
    }

    func loadChart(with prices: [CGFloat]) {
        if prices.isEmpty {
            chartView.setEmpty()
        } else {
            chartView.setData(prices)
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
        priceLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true


        let leftStack = UIStackView(arrangedSubviews: [rankLabel, iconImageView, infoStack, priceLabel])
        leftStack.axis = .horizontal
        leftStack.alignment = .center
        leftStack.spacing = 8
        leftStack.setContentHuggingPriority(.required, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        chartView.widthAnchor.constraint(equalToConstant: 100).isActive = true
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
        mainStack.spacing = 24
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
