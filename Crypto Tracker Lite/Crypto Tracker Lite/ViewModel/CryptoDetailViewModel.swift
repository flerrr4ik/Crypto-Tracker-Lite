//import UIKit
//import DGCharts
//
//final class CryptoDetailViewModel {
//    
//    // MARK: - Properties
//    var crypto: Crypto?
//    var detailedCrypto: DetailedCrypto?
//    var tickers: [Ticker] = []
//    var exchangeLogos: [String: String] = [:]
//    var exchangeURLs: [String: String] = [:]
//    var infoRows: [InfoRow] = []
//    
//    var githubURLString: String?
//    var twitterURLString: String?
//    var redditURLString: String?
//    var webSiteURLString: String?
//    var cryptoDescription: String?
//    
//    // MARK: - Chart Data
//    private var chartCache: [TimeRange: [ChartDataEntry]] = [:]
//    private var currentTimeRange: TimeRange = .day
//    
//    // MARK: - Networking
//    func fetchDetailedInfo(for id: String, completion: @escaping (Bool) -> Void) {
//        APIService.shared.fetchDetail(for: id) { [weak self] detailedCrypto in
//            guard let self = self, let detailedCrypto = detailedCrypto else {
//                completion(false)
//                return
//            }
//            
//            self.detailedCrypto = detailedCrypto
//            self.githubURLString = detailedCrypto.links.repos_url.github.first
//            self.twitterURLString = "https://twitter.com/\(detailedCrypto.links.twitter_screen_name ?? "")"
//            self.redditURLString = detailedCrypto.links.subreddit_url
//            self.webSiteURLString = detailedCrypto.links.homepage.first
//            self.cryptoDescription = detailedCrypto.description.en
//            
//            if let volume = detailedCrypto.marketData?.totalVolume?["usd"],
//               let ath = detailedCrypto.marketData?.ath?["usd"],
//               let totalSupply = detailedCrypto.marketData?.totalSupply,
//               let circulatingSupply = detailedCrypto.marketData?.circulatingSupply {
//                
//                self.infoRows = [
//                    InfoRow(title: "Rank", value: "\(self.crypto?.market_cap_rank ?? 0)"),
//                    InfoRow(title: "Volume", value: "$\(self.formatNumber(volume))"),
//                    InfoRow(title: "ATH", value: "$\(self.formatNumber(ath))"),
//                    InfoRow(title: "Total Supply", value: self.formatNumber(totalSupply)),
//                    InfoRow(title: "Circulating Supply", value: self.formatNumber(circulatingSupply))
//                ]
//            }
//            
//            completion(true)
//        }
//    }
//    
//    func fetchExchangesAndTickers(for id: String, completion: @escaping (Bool) -> Void) {
//        APIService.shared.fetchExchanges { [weak self] exchanges in
//            guard let self = self, let exchanges = exchanges else {
//                completion(false)
//                return
//            }
//            
//            exchanges.forEach {
//                self.exchangeLogos[$0.name] = $0.image
//                self.exchangeURLs[$0.name] = $0.url
//            }
//            
//            APIService.shared.fetchTickers(for: id) { result in
//                guard let result = result else {
//                    completion(false)
//                    return
//                }
//                
//                let filtered = result.filter {
//                    self.exchangeLogos[$0.market.name] != nil &&
//                    self.exchangeURLs[$0.market.name] != nil
//                }
//                
//                let sorted = filtered.sorted { ($0.volume ?? 0) > ($1.volume ?? 0) }
//                var seenExchanges = Set<String>()
//                self.tickers = sorted.filter { seenExchanges.insert($0.market.name).inserted }
//                
//                completion(true)
//            }
//        }
//    }
//    
//    func fetchChartData(for id: String, completion: @escaping ([ChartDataEntry]?) -> Void) {
//        if let cached = chartCache[currentTimeRange] {
//            completion(cached)
//            return
//        }
//        
//        let urlString = "https://api.coingecko.com/api/v3/coins/\(id)/market_chart?vs_currency=usd&days=\(currentTimeRange.daysParameter)"
//        
//        guard let url = URL(string: urlString) else {
//            completion(nil)
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
//            guard let self = self, let data = data, error == nil else {
//                completion(nil)
//                return
//            }
//            
//            do {
//                let chartData = try JSONDecoder().decode(ChartData.self, from: data)
//                let entries = chartData.prices.map { ChartDataEntry(x: $0[0], y: $0[1]) }
//                self.chartCache[self.currentTimeRange] = entries
//                completion(entries)
//            } catch {
//                print("❌ JSON decode error: \(error)")
//                completion(nil)
//            }
//        }.resume()
//    }
//    
//    // MARK: - Helpers
//    func formatNumber(_ number: Double) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        formatter.maximumFractionDigits = 2
//        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
//    }
//    
//    func updateTimeRange(_ range: TimeRange) {
//        currentTimeRange = range
//    }
//}
