//
//  Crypto.swift
//  Crypto Tracker Lite
//
//  Created by Andrii Pyrskyi  on 19.05.2025.
//

import UIKit

struct Crypto: Codable {
    let id: String
    let name: String
    let symbol: String
    let current_price: Double
    let image: String
    let market_cap: Int?
    let price_change_percentage_24h: Double?
    let market_cap_rank: Int
    let sparkline_in_7d: SparklineData?
}
