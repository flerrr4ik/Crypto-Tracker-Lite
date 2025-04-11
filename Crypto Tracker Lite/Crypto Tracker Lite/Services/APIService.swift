//
//  APIService.swift
//  Crypto Tracker Lite
//
//  Created by admin on 21.03.2025.
//

import Foundation

struct Crypto: Codable {
    let id: String
    let name: String
    let symbol: String
    let current_price: Double
    let image: String
    let market_cap: Int?
    let price_change_percentage_24h: Double?
    let market_cap_rank: Int
}

class APIService {
    static let shared = APIService()
    
    func fetchCryptos(completion: @escaping ([Crypto]?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            do {
                let result = try JSONDecoder().decode([Crypto].self, from: data)
                DispatchQueue.main.async {
                    completion(result)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
