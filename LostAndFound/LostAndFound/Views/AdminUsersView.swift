import SwiftUI

struct AdminUsersView: View {

    @EnvironmentObject private var itemViewModel: ItemViewModel

    var body: some View {
            NavigationView {
                Group {
                    if itemViewModel.isLoading && itemViewModel.users.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading users...")
                            Spacer()
                        }
                    } else if itemViewModel.users.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "person.2")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.separator)
                            Text("No users found")
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(itemViewModel.users) { user in
                                    AdminUserRow(user: user)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .background(AppColors.secondary)
                .navigationTitle("Users (\(itemViewModel.users.count))")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    await itemViewModel.fetchAllUsers()
                }
            }
        }

}

private struct AdminUserRow: View {

    let user: UCUser

    private var avatarColor: Color {
        user.role == .admin ? AppColors.admin : AppColors.primary
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text(String(user.name.prefix(2)).uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(avatarColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    if user.role == .admin {
                        Text("ADMIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.admin)
                            .cornerRadius(4)
                    }
                }
                Text(user.email)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                Text(user.studentId)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.separator, lineWidth: 0.5)
        )
    }
}
