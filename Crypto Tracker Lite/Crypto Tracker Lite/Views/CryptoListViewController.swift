import UIKit
import SDWebImage

class CryptoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView()
    private var cryptos: [Crypto] = []
    private var filteredCryptos: [Crypto] = []
    
    // Змінні для відслідковування напрямку сортування
    private var isSortByNumberAscending = true
    private var isSortByMarketCapAscending = true
    private var isSortByPriceAscending = true
    private var isSortBy24hChangeAscending = true
    
    // Кнопки сортування
    
    private let sortByNumberButton = makeSortButtons(label: "#")
    private let sortByMarketCapButton = makeSortButtons(label: "Market Cap")
    private let sortByPriceButton = makeSortButtons(label: "Price")
    private let sortBy24hPriceChangeButton = makeSortButtons(label: "24h")
    
    private let numberArrowImageView = makeArrowView(image: "arrow.down")
    private let priceArrowImageView = makeArrowView(image: "arrow.down")
    private let marketCapArrowImageView = makeArrowView(image: "arrow.down")
    private let priceChangeArrowImageView = makeArrowView(image: "arrow.down")
    
    
    lazy var numberStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sortByNumberButton, numberArrowImageView])
        stack.widthAnchor.constraint(equalToConstant: 32).isActive = true
        return stack
    }()
    
    lazy var marketCapStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sortByMarketCapButton, marketCapArrowImageView])
        stack.widthAnchor.constraint(equalToConstant: 64).isActive = true
        stack.spacing = 0
        return stack
    }()
    
    lazy var priceStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sortByPriceButton, priceArrowImageView])
        stack.widthAnchor.constraint(equalToConstant: 50).isActive = true
        return stack
    }()
    
    lazy var priceChangeStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sortBy24hPriceChangeButton, priceChangeArrowImageView])
        stack.widthAnchor.constraint(equalToConstant: 48).isActive = true
        stack.spacing = 0
        return stack
    }()
    
    
    private lazy var sortButtonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [numberStack, marketCapStack, priceStack, priceChangeStack])
        stack.axis = .horizontal
        
        stack.alignment = .center
        
        stack.setCustomSpacing(20, after: numberStack)
        stack.setCustomSpacing(48, after: marketCapStack)
        stack.setCustomSpacing(68, after: priceStack)
        stack.setCustomSpacing(30, after: priceChangeStack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    private lazy var segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All Cryptos", "Favorites"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        return control
    }()
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No results found"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(segmentControl)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(sortButtonsStack)
        
        
        
        // Налаштовуємо constraints
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        sortButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        priceStack.translatesAutoresizingMaskIntoConstraints = false
        priceChangeStack.translatesAutoresizingMaskIntoConstraints = false
        marketCapStack.translatesAutoresizingMaskIntoConstraints = false
        
        sortByNumberButton.addTarget(self, action: #selector(sortByNumberButtonTapped), for: .touchUpInside)
        sortByPriceButton.addTarget(self, action: #selector(sortByPriceButtonTapped), for: .touchUpInside)
        sortByMarketCapButton.addTarget(self, action: #selector(sortByMarketCapButtonTapped), for: .touchUpInside)
        sortBy24hPriceChangeButton.addTarget(self, action: #selector(sortBy24hPriceChangeButtonButton), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            
            numberArrowImageView.widthAnchor.constraint(equalToConstant: 12),
            numberArrowImageView.heightAnchor.constraint(equalToConstant: 12),
            
            priceArrowImageView.widthAnchor.constraint(equalToConstant: 12),
            priceArrowImageView.heightAnchor.constraint(equalToConstant: 12),
            
            marketCapArrowImageView.widthAnchor.constraint(equalToConstant: 12),
            marketCapArrowImageView.heightAnchor.constraint(equalToConstant: 12),
            
            priceChangeArrowImageView.widthAnchor.constraint(equalToConstant: 12),
            priceChangeArrowImageView.heightAnchor.constraint(equalToConstant: 12),
            
            sortByNumberButton.widthAnchor.constraint(equalToConstant: 12),
            sortButtonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            sortButtonsStack.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 12),
            sortButtonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            sortButtonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: sortButtonsStack.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        
        
        title = "Cryptocurrencies"
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CryptoCell.self, forCellReuseIdentifier: "CryptoCell")
        
        setupSearchController()
        fetchData()
        
    }
    
    private static func makeSortButtons(label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(UIColor.gray.withAlphaComponent(0.6), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private static func makeArrowView(image: String) -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: image))
        imageView.tintColor = .systemBlue
        imageView.alpha = 0.0
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Cryptocurrencies"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func fetchData() {
        print("📡 fetchData started")
        
        APIService.shared.fetchCryptos { [weak self] cryptos in
            print("✅ fetchCryptos finished: \(cryptos?.count ?? 0) items")
            
            guard let cryptos = cryptos else {
                print("❌ Failed to load cryptos")
                return
            }
            
            self?.cryptos = cryptos
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func segmentControlChanged() {
        tableView.reloadData()
    }
    
    private func updateArrowIndicators(selected: UIImageView, ascending: Bool) {
        let allArrows = [ numberArrowImageView, priceArrowImageView, marketCapArrowImageView, priceChangeArrowImageView]
        
        for arrow in allArrows {
            arrow.alpha = arrow == selected ? 1.0 : 0.0
        }
        selected.image = UIImage(systemName: ascending ? "arrow.down" : "arrow.up")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let displayedCryptos: [Crypto]
        
        if segmentControl.selectedSegmentIndex == 1 {
            let favoriteIds = FavoritesManager.shared.favoriteIds
            displayedCryptos = cryptos.filter { favoriteIds.contains($0.id) }
        } else {
            displayedCryptos = cryptos
        }
        
        return isSearching ? filteredCryptos.count : displayedCryptos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoCell", for: indexPath) as! CryptoCell
        
        let crypto: Crypto
        
        if isSearching {
            crypto = filteredCryptos[indexPath.row]
        } else {
            if segmentControl.selectedSegmentIndex == 1 {
                let favoriteIds = FavoritesManager.shared.favoriteIds
                let favoriteCryptos = cryptos.filter { favoriteIds.contains($0.id) }
                crypto = favoriteCryptos[indexPath.row]
            } else {
                crypto = cryptos[indexPath.row]
            }
        }
        
        cell.configureBasicInfo(with: crypto)
        
        if let sparkline = crypto.sparkline_in_7d?.price {
            cell.loadChart(with: sparkline.map { CGFloat($0) })
        } else {
            cell.loadChart(with: [])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let crypto = isSearching ? filteredCryptos[indexPath.row] : cryptos[indexPath.row]
        let detailVC = CryptoDetailViewController()
        detailVC.crypto = crypto
        let backItem = UIBarButtonItem()
        backItem.title = ""
        backItem.tintColor = .black
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(detailVC, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        85
    }
    
    // Сортування за номером (rank)
    @objc private func sortByNumberButtonTapped() {
        isSortByNumberAscending.toggle()
        cryptos.sort { isSortByNumberAscending ? $0.market_cap_rank < $1.market_cap_rank  : $0.market_cap_rank > $1.market_cap_rank }
        
        updateArrowIndicators(selected: numberArrowImageView, ascending: isSortByNumberAscending)
        
        tableView.reloadData()
    }
    
    // Сортування за ціною
    @objc private func sortByPriceButtonTapped() {
        isSortByPriceAscending.toggle()
        cryptos.sort { isSortByPriceAscending ? $0.current_price < $1.current_price : $0.current_price > $1.current_price }
        
        updateArrowIndicators(selected: priceArrowImageView, ascending: isSortByPriceAscending)
        
        tableView.reloadData()
    }
    
    // Сортування за ринковою капіталізацією
    @objc private func sortByMarketCapButtonTapped() {
        isSortByMarketCapAscending.toggle()
        
        cryptos.sort { isSortByMarketCapAscending ? $0.market_cap ?? 0 < $1.market_cap ?? 0 : $0.market_cap ?? 0 > $1.market_cap ?? 0 }
        
        updateArrowIndicators(selected: marketCapArrowImageView, ascending: isSortByMarketCapAscending)
        
        tableView.reloadData()
    }
    
    @objc func sortBy24hPriceChangeButtonButton() {
        isSortBy24hChangeAscending.toggle()
        cryptos.sort { isSortBy24hChangeAscending ? $0.price_change_percentage_24h ?? 0 < $1.price_change_percentage_24h ?? 0 : $0.price_change_percentage_24h ?? 0 > $1.price_change_percentage_24h ?? 0 }
        
        updateArrowIndicators(selected: priceChangeArrowImageView, ascending: isSortBy24hChangeAscending)
        
        tableView.reloadData()
    }
}

extension CryptoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        
        // Визначаємо, по якому набору шукати
        let searchBase: [Crypto]
        
        if segmentControl.selectedSegmentIndex == 1 { // "Favorites"
            let favoriteIds = FavoritesManager.shared.favoriteIds
            searchBase = cryptos.filter { favoriteIds.contains($0.id) }
        } else { // "All Cryptos"
            searchBase = cryptos
        }
        
        // Фільтруємо вибраний набір
        filteredCryptos = searchBase.filter { crypto in
            crypto.name.lowercased().contains(searchText.lowercased()) ||
            crypto.symbol.lowercased().contains(searchText.lowercased())
        }
        
        print("🔍 Пошук: '\(searchText)', знайдено \(filteredCryptos.count)")
        tableView.reloadData()
        
        // Якщо результатів немає, показуємо повідомлення
        emptyStateLabel.isHidden = !(isSearching && filteredCryptos.isEmpty)
    }
}
