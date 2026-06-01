//
//  MainTabView.swift
//  LostAndFound
//
//  Created by Clarrence Adriano Hemeldan on 01/06/26.
//

import Foundation
import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0
    @State private var showAddListing: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            StudentTabBar(
                selectedTab: $selectedTab,
                showAddListing: $showAddListing
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddListing) {
            AddListingView()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            ItemBoardView(showAddListing: $showAddListing)
        case 1:
            MyReportsView()
        case 2:
            AddListingView()
        case 3:
            ProfileView()
        default:
            ItemBoardView(showAddListing: $showAddListing)
        }
    }
}

private struct StudentTabBar: View {

    @Binding var selectedTab: Int
    @Binding var showAddListing: Bool

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "house.fill",
                label: "HOME",
                isSelected: selectedTab == 0
            ) { selectedTab = 0 }

            TabBarItem(
                icon: "doc.text.fill",
                label: "REPORT",
                isSelected: selectedTab == 1
            ) { selectedTab = 1 }
            
            TabBarItem(icon: "plus",
                       label: "ADD LISTING",
                       isSelected: selectedTab == 2
            ){ selectedTab = 2}
                .multilineTextAlignment(.center)

            TabBarItem(
                icon: "person.fill",
                label: "PROFILE",
                isSelected: selectedTab == 3
            ) { selectedTab = 3 }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            AppColors.card
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
    }

    private var addListingButton: some View {
        Button(action: { showAddListing = true }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primary)
                        .frame(width: 60, height: 36)
                    Text("ADD\nLISTING")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TabBarItem: View {

    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(
                        isSelected ? AppColors.primary : AppColors.textSecondary
                    )
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(
                        isSelected ? AppColors.primary : AppColors.textSecondary
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}
