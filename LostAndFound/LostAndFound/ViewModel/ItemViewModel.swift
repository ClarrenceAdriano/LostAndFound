import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
final class ItemViewModel: ObservableObject {


    @Published var reports: [LostItemReport] = []
    @Published var claims: [Claim] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var users: [UCUser] = []

    private let reportService: ReportService
    private let claimService: ClaimService
    private let notificationService: NotificationService


    init(
        reportService: ReportService? = nil,
        claimService: ClaimService? = nil,
        notificationService: NotificationService? = nil
    ) {
        self.reportService = reportService ?? ReportService.shared
        self.claimService = claimService ?? ClaimService.shared
        self.notificationService = notificationService ?? NotificationService.shared
    }

    func fetchAllClaims() async {
        let result = await claimService.fetchClaims()
        switch result {
        case .success(let fetched):
            claims = fetched
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }


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
    
    func fetchAllReports() async {
        isLoading = true
        errorMessage = nil

        let result = await reportService.fetchAllReports()

        isLoading = false

        switch result {
        case .success(let fetched):
            reports = fetched
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    func submitReport(_ report: LostItemReport, imageData: Data? = nil) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let result = await reportService.createReport(report, imageData: imageData)

        isLoading = false

        switch result {
        case .success(let created):
            reports.insert(created, at: 0)
            successMessage = "Your listing has been posted!"
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    func deleteReport(reportId: String, userId: String) async {
        let result = await reportService.deleteReport(
            reportId: reportId,
            userId: userId
        )
        switch result {
        case .success:
            reports.removeAll { $0.id == reportId }
            claims.removeAll { $0.itemId == reportId }
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    func filteredReports(search: String, filter: ItemStatus?) -> [LostItemReport] {
        reports.filter { report in
            guard report.status != .claimed else { return false }
            let matchesSearch = search.isEmpty
                || report.title.localizedCaseInsensitiveContains(search)
                || report.location.localizedCaseInsensitiveContains(search)
            let matchesFilter = filter == nil || report.status == filter
            return matchesSearch && matchesFilter
        }
    }

    func reports(for userId: String) -> [LostItemReport] {
        reports.filter { $0.reporterId == userId }
    }



    func claims(for itemId: String) -> [Claim] {
        claims.filter { $0.itemId == itemId }
    }


    func hasClaimed(itemId: String, userId: String) async -> Bool {
        await claimService.hasClaimed(itemId: itemId, userId: userId)
    }

    var totalLost: Int {
        reports.filter { $0.status == .lost }.count
    }

    var totalFound: Int {
        reports.filter { $0.status == .found }.count
    }

    var totalPendingClaims: Int {
        claims.filter { $0.claimStatus == .pending }.count
    }
    
    private func reporterIdFor(itemId: String) -> String {
        reports.first { $0.id == itemId }?.reporterId ?? ""
    }
    
    private func titleFor(itemId: String) -> String {
        reports.first { $0.id == itemId }?.title ?? "an item"
    }
}
