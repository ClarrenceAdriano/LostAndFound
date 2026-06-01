//
//  AuthService.swift
//
//
//  Created by Shatrya Christiano on 01/06/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class AuthService {
    
    static let shared = AuthService()
    private init() {}
    
    func validateDomain(_ email: String) -> Bool {
        email.isValidUCEmail
    }
    
    func login(
        email: String,
        password: String
    ) async -> Result<UCUser, AppError> {
        guard validateDomain(email) else {
            return .failure(.invalidDomain)
        }
        
        guard password.isNotBlank else {
            return .failure(.invalidInput)
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await fetchUserFromFirestore(uid: result.user.uid)
            return .success(user)
        } catch {
            return .failure(.wrongCredentials)
        }
    }
    
    func register(request: RegisterRequest) async -> Result<UCUser, AppError> {
        guard validateDomain(request.email) else {
            return .failure(.invalidDomain)
        }
        
        guard request.name.isNotBlank,
              request.studentId.isNotBlank else {
            return .failure(.invalidInput)
        }
        
        guard request.password.meetsMinLength(8) else {
            return .failure(.weakPassword)
        }
        
        guard request.password == request.confirmPassword else {
            return .failure(.passwordMismatch)
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: request.email, password: request.password)
            
            let newUser = UCUser(
                id: result.user.uid,
                name: request.name,
                email: request.email,
                role: .student,
                studentId: request.studentId
            )
            
            try Firestore.firestore()
                .collection("users")
                .document(result.user.uid)
                .setData(from: newUser)
            
            return .success(newUser)
        } catch {
            return .failure(.passwordMismatch)
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
    
    private func fetchUserFromFirestore(uid: String) async throws -> UCUser {
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
        
        let user = try snapshot.data(as: UCUser.self)
        return user
    }
}

