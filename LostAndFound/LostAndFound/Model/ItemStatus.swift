//
//  ItemStatus.swift
//  LostAndFound
//
//  Created by Dylan on 01/06/26.
//

import Foundation

enum ItemStatus: String, Codable, CaseIterable {
    case lost  = "LOST"
    case found = "FOUND"
    case claimed = "CLAIMED"
}
