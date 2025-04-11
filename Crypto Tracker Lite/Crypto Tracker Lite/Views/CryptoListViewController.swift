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
    
    // Кнопки сортування
    private let sortByNumberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("#", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12) // менший шрифт
        button.addTarget(self, action: #selector(sortByNumber), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let sortByMarketCapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Market Cap", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12) // менший шрифт
        button.addTarget(self, action: #selector(sortByMarketCap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let sortByPriceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Price", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12) // менший шрифт
        button.addTarget(self, action: #selector(sortByPrice), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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

        // Додаємо елементи
        view.addSubview(segmentControl)
        view.addSubview(sortByNumberButton)
        view.addSubview(sortByMarketCapButton)
        view.addSubview(sortByPriceButton)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        // Налаштовуємо constraints
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        sortByNumberButton.translatesAutoresizingMaskIntoConstraints = false
        sortByMarketCapButton.translatesAutoresizingMaskIntoConstraints = false
        sortByPriceButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Segment Control
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Кнопки сортування (горизонтально)
            sortByNumberButton.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            sortByNumberButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            sortByMarketCapButton.topAnchor.constraint(equalTo: sortByNumberButton.topAnchor),
            sortByMarketCapButton.leadingAnchor.constraint(equalTo: sortByNumberButton.trailingAnchor, constant: 32),
            
            sortByPriceButton.topAnchor.constraint(equalTo: sortByMarketCapButton.topAnchor),
            sortByPriceButton.leadingAnchor.constraint(equalTo: sortByMarketCapButton.trailingAnchor, constant: 32),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: sortByNumberButton.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty State Label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        
        // Інші налаштування
        title = "Cryptocurrencies"
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CryptoCell.self, forCellReuseIdentifier: "CryptoCell")
        
        setupSearchController()
        fetchData()
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

    // Цей метод буде викликаний, коли зміниться вибір у сегментному контролері
    @objc private func segmentControlChanged() {
        tableView.reloadData()
    }

    // Табличні методи
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let displayedCryptos: [Crypto]
        
        if segmentControl.selectedSegmentIndex == 1 { // "Favorites"
            let favoriteIds = FavoritesManager.shared.favoriteIds
            displayedCryptos = cryptos.filter { favoriteIds.contains($0.id) }
        } else { // "All Cryptos"
            displayedCryptos = cryptos
        }
        
        // Якщо йде пошук — фільтруємо вже відфільтровані дані
        return isSearching ? filteredCryptos.count : displayedCryptos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CryptoCell", for: indexPath) as! CryptoCell
        
        let crypto: Crypto
        
        if isSearching {
            // Пошук активний — беремо з filteredCryptos
            crypto = filteredCryptos[indexPath.row]
        } else {
            // Пошук НЕ активний — фільтруємо за "Favorites" якщо потрібно
            if segmentControl.selectedSegmentIndex == 1 { // "Favorites"
                let favoriteIds = FavoritesManager.shared.favoriteIds
                let favoriteCryptos = cryptos.filter { favoriteIds.contains($0.id) }
                crypto = favoriteCryptos[indexPath.row]
            } else { // "All Cryptos"
                crypto = cryptos[indexPath.row]
            }
        }
        
        cell.configureBasicInfo(with: crypto)
        cell.loadChart(for: crypto.id)
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let crypto = isSearching ? filteredCryptos[indexPath.row] : cryptos[indexPath.row]
        let detailVC = CryptoDetailViewController()
        detailVC.crypto = crypto
        navigationController?.pushViewController(detailVC, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        85
    }
    
    // Сортування за номером (rank)
    @objc private func sortByNumber() {
        isSortByNumberAscending.toggle()
        cryptos.sort { isSortByNumberAscending ? $0.market_cap_rank < $1.market_cap_rank : $0.market_cap_rank > $1.market_cap_rank }
        tableView.reloadData()
    }

    // Сортування за ціною
    @objc private func sortByPrice() {
        isSortByPriceAscending.toggle()
        cryptos.sort { isSortByPriceAscending ? $0.current_price < $1.current_price : $0.current_price > $1.current_price }
        tableView.reloadData()
    }

    // Сортування за ринковою капіталізацією
    @objc private func sortByMarketCap() {
        isSortByMarketCapAscending.toggle()
        cryptos.sort { isSortByMarketCapAscending ? $0.market_cap ?? 0 < $1.market_cap ?? 0 : $0.market_cap ?? 0 > $1.market_cap ?? 0 }
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
