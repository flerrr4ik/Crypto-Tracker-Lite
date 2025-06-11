//
//  APIService.swift
//  Crypto Tracker Lite
//
//  Created by admin on 21.03.2025.
//

import UIKit

class APIService {
    static let shared = APIService()
    
    func fetchCryptos(completion: @escaping ([Crypto]?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&sparkline=true"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
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
    
    func fetchTickers(for id: String, completion: @escaping ([Ticker]?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/\(id)/tickers?include_exchange_logo=true"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(TickerResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(decoded.tickers)
                }
            } catch {
                print("Decoding error:", error)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func fetchExchanges(completion: @escaping ([Exchange]?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/exchanges"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            do {
                let exchanges  = try JSONDecoder().decode([Exchange].self, from: data)
                DispatchQueue.main.async {
                    completion(exchanges)
                }
            } catch {
                print("Decoding error:", error)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func fetchDetail(for id: String, completion: @escaping (DetailedCrypto?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/\(id)?localization=false"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            do {
                let detailedCrypto = try JSONDecoder().decode(DetailedCrypto.self, from: data)
                DispatchQueue.main.async {
                    completion(detailedCrypto)
                }
            } catch {
                print("Decoding error", error)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    func fetchCryptoByID(id: String, completion: @escaping (Crypto?) -> Void) {
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(id)&sparkline=true"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            do {
                let result = try JSONDecoder().decode([Crypto].self, from: data)
                DispatchQueue.main.async {
                    completion(result.first)
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
