//
//  Log.swift
//  NetHawk
//
//  Created by mobicom on 10/8/24.
//

import Foundation

struct Log: Codable {
    let timestamp: String
    let type: String
    let invaderAddress: String?
    let victimAddress: String
    let victimName: String
}
