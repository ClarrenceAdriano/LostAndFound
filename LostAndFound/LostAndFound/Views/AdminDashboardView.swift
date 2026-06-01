import SwiftUI

// MARK: - AdminDashboardView

/// Overview dashboard showing live stats and recent activity for administrators.
struct AdminDashboardView: View {

    // MARK: - Properties

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHeader
                    SectionHeader(title: "Overview")
                    statsGrid
                    SectionHeader(title: "Recent Items")
                    recentItemsList
                    pendingClaimsSection
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(AppColors.secondary)
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Private Sections

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Text(authViewModel.currentUser?.name ?? "Admin")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text("AD")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            AdminStatCard(
                value: "\(itemViewModel.reports.count)",
                label: "Total Items",
                icon: "archivebox.fill",
                color: AppColors.primary
            )
            AdminStatCard(
                value: "\(itemViewModel.totalLost)",
                label: "Lost Items",
                icon: "exclamationmark.triangle.fill",
                color: AppColors.lost
            )
            AdminStatCard(
                value: "\(itemViewModel.totalFound)",
                label: "Found Items",
                icon: "checkmark.circle.fill",
                color: AppColors.found
            )
            AdminStatCard(
                value: "\(itemViewModel.totalPendingClaims)",
                label: "Pending Claims",
                icon: "clock.fill",
                color: AppColors.admin
            )
        }
    }

    private var recentItemsList: some View {
        ForEach(itemViewModel.reports.prefix(4)) { report in
            AdminItemRow(report: report)
        }
    }

    @ViewBuilder
    private var pendingClaimsSection: some View {
        let pending = itemViewModel.claims.filter { $0.claimStatus == .pending }
        if !pending.isEmpty {
            SectionHeader(title: "Pending Claims")
            ForEach(pending.prefix(3)) { claim in
                AdminClaimCard(claim: claim)
                    .environmentObject(itemViewModel)
            }
        }
    }
}


// MARK: - AdminStatCard

struct AdminStatCard: View {

    // MARK: - Properties

    let value: String
    let label: String
    let icon: String
    let color: Color

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }
}


// MARK: - AdminItemRow

struct AdminItemRow: View {

    // MARK: - Properties

    let report: LostItemReport

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlString = report.imageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.separator)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        case .failure:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.separator)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.separator)
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.separator)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 44, height: 44)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(report.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(report.location)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
            StatusBadge(status: report.status)
        }
        .padding(12)
        .background(AppColors.card)
        .cornerRadius(10)
    }
}
