//
//  AddListingView.swift
//  LostAndFound
//
//  Created by Dylan on 01/06/26.
//

import SwiftUI
import PhotosUI

struct AddListingView: View {
    
    @EnvironmentObject private var itemViewModel: ItemViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var listingType: ItemStatus = .lost
    @State private var itemTitle: String = ""
    @State private var date: Date = Date()
    @State private var lastSeen: String = ""
    @State private var description: String = ""
    @State private var showValidationError: Bool = false
    @State private var showSuccess: Bool = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    private var isFormValid: Bool {
        itemTitle.isNotBlank && lastSeen.isNotBlank && description.isNotBlank
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    photoSection
                    listingTypeSection
                    FormField(
                        label: "Item type",
                        placeholder: "e.g. iPhone 15 Pro Max",
                        text: $itemTitle
                    )
                    dateSection
                    FormField(
                        label: "Last seen",
                        placeholder: "e.g. Academic Support Lt. 2",
                        text: $lastSeen
                    )
                    descriptionSection
                    
                    if showValidationError {
                        ErrorBanner(message: "Please fill in all required fields.")
                    }
                    
                    PrimaryButton(
                        title: "SAVE",
                        isLoading: itemViewModel.isLoading
                    ) {
                        handleSave()
                    }
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Add Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.primary)
                }
            }
            .sheet(isPresented: $showSuccess) {
                SuccessOverlay(message: successMessage) {
                    dismiss()
                }
            }
        }
    }
    
    private var successMessage: String {
        switch listingType {
        case .lost:
            return "Your lost item has been posted!\nWe hope someone finds it soon."
        case .found:
            return "Your listing has been posted!\nPlease bring this item to the admin's office so the owner can collect it."
        case .claimed:
            return "Your listing has been posted!"
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add pictures")
                .font(.system(size: 15, weight: .medium))
            
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(AppColors.textSecondary)
                        Text("ADD PHOTO")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(AppColors.secondary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.separator, lineWidth: 0.5)
                    )
                }
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    selectedImageData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
        }
    }
    
    private var listingTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Listing type")
                .font(.system(size: 15, weight: .medium))
            HStack(spacing: 10) {
                ListingTypeButton(
                    title: "LOST",
                    isSelected: listingType == .lost,
                    activeColor: AppColors.lost
                ) { listingType = .lost }
                
                ListingTypeButton(
                    title: "FOUND",
                    isSelected: listingType == .found,
                    activeColor: AppColors.found
                ) { listingType = .found }
            }
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.system(size: 15, weight: .medium))
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.secondary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.separator, lineWidth: 0.5)
                )
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 15, weight: .medium))
            TextEditor(text: $description)
                .frame(height: 100)
                .padding(10)
                .background(AppColors.secondary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.separator, lineWidth: 0.5)
                )
                .font(.system(size: 15))
        }
    }
    
    private func handleSave() {
        showValidationError = false
        guard isFormValid else {
            showValidationError = true
            return
        }
        guard let user = authViewModel.currentUser else { return }
        
        let newReport = LostItemReport(
            title: itemTitle,
            location: lastSeen,
            date: date,
            description: description,
            status: listingType,
            reporterId: user.id,
            reporterName: user.name,
            reporterEmail: user.email
        )
        Task {
            await itemViewModel.submitReport(newReport, imageData: selectedImageData)
            showSuccess = true
        }
    }
}


private struct ListingTypeButton: View {
    
    let title: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : activeColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? activeColor : Color.clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(activeColor, lineWidth: 1.5)
                )
        }
    }
}
