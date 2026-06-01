//
//  AuthViewModel.swift
//
//
//  Created by Shatrya Christiano on 01/06/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    
    @Published var currentUser: UCUser?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    
    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthService.shared
    }
    
    func login(email: String, password: String) async {
        guard validateLoginInputs(email: email, password: password) else { return }
        
        isLoading = true
        errorMessage = nil
        
        let result = await authService.login(email: email, password: password)
        
        isLoading = false
        
        switch result {
        case .success(let user):
            currentUser = user
            isLoggedIn = true
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
    
    func register(request: RegisterRequest) async {
        guard validateRegisterRequest(request) else { return }
        
        isLoading = true
        errorMessage = nil
        
        let result = await authService.register(request: request)
        
        isLoading = false
        
        switch result {
        case .success(let user):
            currentUser = user
            isLoggedIn = true
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
    
    func logout() {
        authService.logout()
        currentUser = nil
        isLoggedIn = false
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    private func validateLoginInputs(email: String, password: String) -> Bool {
        guard email.isNotBlank, password.isNotBlank else {
            errorMessage = AppError.invalidInput.errorDescription
            return false
        }
        guard email.isValidUCEmail else {
            errorMessage = AppError.invalidDomain.errorDescription
            return false
        }
        return true
    }
    
    private func validateRegisterRequest(_ request: RegisterRequest) -> Bool {
        guard request.name.isNotBlank,
              request.email.isNotBlank,
              request.studentId.isNotBlank,
              request.password.isNotBlank,
              request.confirmPassword.isNotBlank else {
            errorMessage = AppError.invalidInput.errorDescription
            return false
        }
        guard request.email.isValidUCEmail else {
            errorMessage = AppError.invalidDomain.errorDescription
            return false
        }
        guard request.password.meetsMinLength(8) else {
            errorMessage = AppError.weakPassword.errorDescription
            return false
        }
        guard request.password == request.confirmPassword else {
            errorMessage = AppError.passwordMismatch.errorDescription
            return false
        }
        return true
    }
}

