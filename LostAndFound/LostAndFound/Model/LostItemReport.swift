//
//  LostItemReport.swift
//  LostAndFound
//
//  Created by Dylan on 01/06/26.
//

import Foundation

struct LostItemReport: Identifiable, Codable, Equatable {

    let id: String
    let title: String
    let location: String
    let date: Date
    let description: String
    let status: ItemStatus
    let imageUrl: String?
    let reporterId: String
    let reporterName: String
    let reporterEmail: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        location: String,
        date: Date = Date(),
        description: String,
        status: ItemStatus,
        imageUrl: String? = nil,
        reporterId: String = "",
        reporterName: String = "",
        reporterEmail: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.date = date
        self.description = description
        self.status = status
        self.imageUrl = imageUrl
        self.reporterId = reporterId
        self.reporterName = reporterName
        self.reporterEmail = reporterEmail
        self.createdAt = createdAt
    }
}
