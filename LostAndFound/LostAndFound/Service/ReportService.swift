//
//  ReportService.swift
//  LostAndFound
//
//  Created by Dylan on 01/06/26.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

final class ReportService {

    static let shared = ReportService()

    private init() {}
    func fetchAllReports() async -> Result<[LostItemReport], AppError> {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("reports")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let reports = snapshot.documents.compactMap { document in
                try? document.data(as: LostItemReport.self)
            }
            return .success(reports)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func fetchReports(for userId: String) async -> Result<[LostItemReport], AppError> {
        guard userId.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("reports")
                .whereField("reporterId", isEqualTo: userId)
                .getDocuments()

            let userReports = snapshot.documents.compactMap { document in
                try? document.data(as: LostItemReport.self)
            }
            return .success(userReports)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    func createReport(
        _ report: LostItemReport,
        imageData: Data? = nil
    ) async -> Result<LostItemReport, AppError> {
        guard report.title.isNotBlank, report.location.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            var finalReport = report
            if let imageData {
                let imageUrl = try await uploadImage(imageData, reportId: report.id)
                finalReport = LostItemReport(
                    id: report.id,
                    title: report.title,
                    location: report.location,
                    date: report.date,
                    description: report.description,
                    status: report.status,
                    imageUrl: imageUrl,
                    reporterId: report.reporterId,
                    reporterName: report.reporterName,
                    reporterEmail: report.reporterEmail,
                    createdAt: report.createdAt
                )
            }

            try Firestore.firestore()
                .collection("reports")
                .document(finalReport.id)
                .setData(from: finalReport)

            return .success(finalReport)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func deleteReport(
        reportId: String,
        userId: String
    ) async -> Result<Void, AppError> {
        guard reportId.isNotBlank else {
            return .failure(.invalidInput)
        }

        do {
            try await Firestore.firestore()
                .collection("reports")
                .document(reportId)
                .delete()
            return .success(())
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    private func uploadImage(
        _ imageData: Data,
        reportId: String
    ) async throws -> String {
        guard let compressed = UIImage(data: imageData)?
                .jpegData(compressionQuality: 0.8) else {
            throw AppError.invalidInput
        }

        let storageRef = Storage.storage()
            .reference()
            .child("items/\(reportId).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(compressed, metadata: metadata)

        let downloadUrl = try await storageRef.downloadURL()
        return downloadUrl.absoluteString
    }
}
