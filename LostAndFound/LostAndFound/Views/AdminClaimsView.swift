import SwiftUI

struct AdminClaimsView: View {

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @State private var filterStatus: ClaimStatus? = nil

    private var filteredClaims: [Claim] {
        guard let filter = filterStatus else { return itemViewModel.claims }
        return itemViewModel.claims.filter { $0.claimStatus == filter }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                claimFilterBar
                Divider()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredClaims) { claim in
                            AdminClaimCard(claim: claim)
                                .environmentObject(itemViewModel)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .background(AppColors.secondary)
            .navigationTitle("Claims")
            .navigationBarTitleDisplayMode(.inline)
            .task{
                await itemViewModel.fetchAllClaims()
            }
        }
    }

    private var claimFilterBar: some View {
        HStack(spacing: 0) {
            claimChip(title: "All",      filter: nil)
            claimChip(title: "Pending",  filter: .pending)
            claimChip(title: "Approved", filter: .approved)
            claimChip(title: "Rejected", filter: .rejected)
        }
        .padding(12)
        .background(AppColors.background)
    }

    private func claimChip(title: String, filter: ClaimStatus?) -> some View {
        Button(action: { filterStatus = filter }) {
            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: filterStatus == filter ? .semibold : .regular
                    )
                )
                .foregroundColor(
                    filterStatus == filter
                        ? AppColors.textPrimary
                        : AppColors.textSecondary
                )
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(filterStatus == filter ? AppColors.card : Color.clear)
                .cornerRadius(16)
        }
    }
}

struct AdminClaimCard: View {

    @EnvironmentObject private var itemViewModel: ItemViewModel
    let claim: Claim

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(claim.claimantName)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                ClaimStatusBadge(claimStatus: claim.claimStatus)
            }

            Text(claim.message)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)

            if claim.claimStatus == .pending {
                HStack(spacing: 8) {
                    adminActionChip(
                        title: "Approve",
                        color: AppColors.found,
                        status: .approved
                    )
                    adminActionChip(
                        title: "Reject",
                        color: .red,
                        status: .rejected
                    )
                }
            }
        }
        .padding(12)
        .background(AppColors.card)
        .cornerRadius(10)
    }

    private func adminActionChip(
        title: String,
        color: Color,
        status: ClaimStatus
    ) -> some View {
        Button(action: {
            Task {
                await itemViewModel.updateClaimStatus(
                    claimId: claim.id,
                    newStatus: status
                )
            }
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(8)
        }
    }
}
