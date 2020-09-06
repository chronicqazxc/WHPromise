//
//  GroceryProduct.swift
//  WHPromiseTests
//
//  Created by Hsiao, Wayne on 2019/10/27.
//  Copyright © 2019 Hsiao, Wayne. All rights reserved.
//
import Foundation

struct GroceryProduct: Codable {
    var name: String
    var points: Int
    var description: String?
    var orderId: String
}
