//
//  MarketCell.swift
//  Crypto Tracker Lite
//
//  Created by admin on 30.04.2025.
//

import UIKit

class MarketCell: UICollectionViewCell {
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pairAndPriceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init (frame: CGRect) {
        super.init (frame: frame)
        contentView.backgroundColor = UIColor.systemGray6
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        setupViews()
    }
    required init? (coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Налаштування логотипа
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = 8
        logoImageView.clipsToBounds = true
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Налаштування лейблів
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        pairAndPriceLabel.font = UIFont.systemFont(ofSize: 11)
        pairAndPriceLabel.textColor = .secondaryLabel
        pairAndPriceLabel.numberOfLines = 2
        pairAndPriceLabel.adjustsFontSizeToFitWidth = true
        pairAndPriceLabel.minimumScaleFactor = 0.7
        pairAndPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        // Стек для тексту
        let labelsStack = UIStackView(arrangedSubviews: [nameLabel, pairAndPriceLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.alignment = .leading
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelsStack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        // Головний горизонтальний стек
        let horizontalStack = UIStackView(arrangedSubviews: [logoImageView, labelsStack])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 12
        horizontalStack.alignment = .center
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 32),
            logoImageView.heightAnchor.constraint(equalToConstant: 32),

            horizontalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            horizontalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            horizontalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            horizontalStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with ticker: Ticker, logoURL: String?) {
        nameLabel.text = ticker.market.name
        pairAndPriceLabel.text = "\(ticker.base)/\(ticker.target)\n$\(ticker.last)"
        
        if let logoURL = logoURL, let url = URL(string: logoURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.logoImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        } else {
            logoImageView.image = UIImage(systemName: "questionmark")
        }
    }
}
