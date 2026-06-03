import SwiftUI

struct AdminItemsView: View {

    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var searchText: String = ""
    @State private var filterStatus: ItemStatus? = nil
    @State private var reportToDelete: LostItemReport? = nil
    @State private var showDeleteConfirm: Bool = false

    private var filteredReports: [LostItemReport] {
        itemViewModel.filteredReports(search: searchText, filter: filterStatus)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                HStack(spacing: 0) {
                    FilterChip(title: "All items", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    FilterChip(title: "Lost", isSelected: filterStatus == .lost) {
                        filterStatus = .lost
                    }
                    FilterChip(title: "Found", isSelected: filterStatus == .found) {
                        filterStatus = .found
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Divider()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredReports) { report in
                            HStack(spacing: 8) {
                                ItemCard(report: report)
                                deleteButton(for: report)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(AppColors.secondary)
            .navigationTitle("All Items")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Item", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Permanently delete this listing and all associated claims?")
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            TextField("Search items...", text: $searchText)
        }
        .padding(12)
        .background(AppColors.secondary)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
    }

    private func deleteButton(for report: LostItemReport) -> some View {
        Button(action: {
            reportToDelete = report
            showDeleteConfirm = true
        }) {
            Image(systemName: "trash")
                .foregroundColor(.red)
                .padding(8)
        }
    }

    private func confirmDelete() {
        guard let report = reportToDelete,
              let userId = authViewModel.currentUser?.id else { return }
        Task {
            await itemViewModel.deleteReport(
                reportId: report.id,
                userId: userId
            )
        }
    }
}
