import Foundation
import SwiftUI
import FirebaseFirestore
import os

// MARK: - ItemViewModel

/// Drives ItemBoardView, ItemDetailView, AddListingView, MyReportsView, and AdminViews.
/// Translates ReportService and ClaimService results into @Published UI state.
/// No business logic lives in Views — all service calls and state mutations are here.
@MainActor
final class ItemViewModel: ObservableObject {

    // MARK: - Properties

    @Published var reports: [LostItemReport] = []
    @Published var claims: [Claim] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var users: [UCUser] = []

    private let reportService: ReportService
    private let claimService: ClaimService
    private let notificationService: NotificationService
    private let logger = Logger(
        subsystem: "com.uc.lostfound",
        category: "ItemViewModel"
    )


    // MARK: - Init

    /// Creates an ItemViewModel with injected services.
    /// - Parameters:
    ///   - reportService: Service handling Firestore report operations
    ///   - claimService: Service handling Firestore claim operations
    ///   - notificationService: Service handling FCM push notifications
    init(
        reportService: ReportService = .shared,
        claimService: ClaimService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.reportService = reportService
        self.claimService = claimService
        self.notificationService = notificationService
    }


    /// Loads all claims from Firestore and updates the published claims array.
    func fetchAllClaims() async {
        let result = await claimService.fetchClaims()
        switch result {
        case .success(let fetched):
            claims = fetched
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }


    // MARK: - Public Methods — Claims

    /// Submits a claim for a found item and notifies the report owner via FCM.
    /// - Parameters:
    ///   - itemId: Firestore document ID of the found item report
    ///   - claim: Fully populated Claim model from the claimant
    func submitClaim(itemId: String, claim: Claim) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let result = await claimService.submitClaim(itemId: itemId, claimData: claim)

        isLoading = false

        switch result {
        case .success(let created):
            claims.insert(created, at: 0)
            successMessage = "Your claim has been submitted!"
            await notificationService.notifyReporterOfNewClaim(
                reporterUserId: reporterIdFor(itemId: itemId),
                itemTitle: titleFor(itemId: itemId)
            )
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    /// Updates a claim's approval status. Admin-only action — enforce RBAC at call site.
    /// - Parameters:
    ///   - claimId: Firestore document ID of the claim
    ///   - newStatus: Target ClaimStatus (.approved or .rejected)
    func updateClaimStatus(claimId: String, newStatus: ClaimStatus) async {
        let result = await claimService.updateClaimStatus(
            claimId: claimId,
            newStatus: newStatus
        )
        switch result {
        case .success(let updated):
            if let index = claims.firstIndex(where: { $0.id == claimId }) {
                claims[index] = updated
            }
            
            if newStatus == .approved {
                    await markReportAsClaimed(itemId: updated.itemId)
            }
            
            await notificationService.notifyClaimantOfStatusChange(
                claimantUserId: updated.claimantId,
                newStatus: newStatus
            )
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
    
    private func markReportAsClaimed(itemId: String) async {
        do {
            try await Firestore.firestore()
                .collection("reports")
                .document(itemId)
                .updateData(["status": ItemStatus.claimed.rawValue])

            if let index = reports.firstIndex(where: { $0.id == itemId }) {
                reports.remove(at: index)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    
    func fetchAllUsers() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .getDocuments()

            let fetchedUsers = snapshot.documents.compactMap { document in
                try? document.data(as: UCUser.self)
            }
            users = fetchedUsers
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    /// Returns all claims associated with a specific report.
    /// - Parameter itemId: Firestore document ID of the report
    /// - Returns: Filtered array of Claim
    func claims(for itemId: String) -> [Claim] {
        claims.filter { $0.itemId == itemId }
    }


    /// Returns whether a specific user has already claimed a specific item.
    /// - Parameters:
    ///   - itemId: Firestore document ID of the report
    ///   - userId: UID of the user to check
    /// - Returns: true if an existing claim is found
    func hasClaimed(itemId: String, userId: String) async -> Bool {
        await claimService.hasClaimed(itemId: itemId, userId: userId)
    }

    /// Total number of lost-status reports (for admin dashboard stat card).
    var totalLost: Int {
        reports.filter { $0.status == .lost }.count
    }

    /// Total number of found-status reports (for admin dashboard stat card).
    var totalFound: Int {
        reports.filter { $0.status == .found }.count
    }

    /// Total number of claims with pending status (for admin dashboard stat card).
    var totalPendingClaims: Int {
        claims.filter { $0.claimStatus == .pending }.count
    }
}
