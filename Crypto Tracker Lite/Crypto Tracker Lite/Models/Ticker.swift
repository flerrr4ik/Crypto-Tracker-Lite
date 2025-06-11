//
//  Ticker.swift
//  Crypto Tracker Lite
//
//  Created by admin on 30.04.2025.
//

import UIKit

struct Ticker: Codable {
    let market: Market
    let base: String
    let target: String
    let last: Double
    let volume: Double?
}
struct Market: Codable {
    let name: String
    let identifier: String
    let hasTradingIncentive: Bool?
    let logo: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case hasTradingIncentive = "has_trading_incentive"
        case logo = "logo_url"
    }
}

struct TickerResponse: Decodable {
    let tickers: [Ticker]
}

struct Exchange: Decodable {
    let id: String
    let name: String
    let image: String
    let url: String
}
