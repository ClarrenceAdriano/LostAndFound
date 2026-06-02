//
//  NotificationService.swift
//  LostAndFound
//
//  Created by Shatrya Christiano on 02/06/26.
//

import Foundation
import os

final class NotificationService {

    static let shared = NotificationService()

    private let logger = Logger(
        subsystem: "com.uc.lostfound",
        category: "NotificationService"
    )

    private init() {}

    func notifyReporterOfNewClaim(
        reporterUserId: String,
        itemTitle: String
    ) async {
        guard reporterUserId.isNotBlank else { return }

        logger.info("Claim notification sent to \(reporterUserId) for: \(itemTitle)")
    }

    func notifyClaimantOfStatusChange(
        claimantUserId: String,
        newStatus: ClaimStatus
    ) async {
        guard claimantUserId.isNotBlank else { return }

        logger.info("Status notification sent to \(claimantUserId): \(newStatus.rawValue)")
    }

    func broadcastToAll(title: String, body: String) async {
        guard title.isNotBlank, body.isNotBlank else { return }

        logger.info("Broadcast sent — title: \(title)")
    }
}
