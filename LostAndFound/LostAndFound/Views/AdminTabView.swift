import SwiftUI

struct AdminTabView: View {

    var body: some View {
        TabView {
            AdminDashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            AdminItemsView()
                .tabItem { Label("Items", systemImage: "list.bullet") }

            AdminClaimsView()
                .tabItem { Label("Claims", systemImage: "doc.text.fill") }

            AdminUsersView()
                .tabItem { Label("Users", systemImage: "person.2.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .accentColor(AppColors.primary)
    }
}
