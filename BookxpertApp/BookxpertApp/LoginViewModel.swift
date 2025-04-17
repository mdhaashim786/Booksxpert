//
//  LoginViewModel.swift
//  BookxpertApp
//
//  Created by mhaashim on 17/04/25.
//

import SwiftUI
import CoreData
import FirebaseAuth
import GoogleSignIn

class LoginViewModel: ObservableObject {
    
    // Just added to store userProfile
    @Published var userprofile: UserProfile?
    @Published var isSignedIn: Bool = false
    
    let pdfUrl: String = "https://fssservices.bookxpert.co/GeneratedPDF/Companies/nadc/2024-2025/BalanceSheet.pdf"
    
    private var context: NSManagedObjectContext?
    
    func setContext(_ context: NSManagedObjectContext) {
        self.context = context
        self.isSignedIn = Auth.auth().currentUser != nil
        fetchProfile()
    }
    
    func signInWithGoogle(presentingVC: UIViewController?) {
        guard let presentingVC = presentingVC else {
            print("Missing presenting view controller")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error  in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In error: \(error.localizedDescription)")
                } else {
                    print("Successfully signed in")
                    
                    self.isSignedIn = true
                    self.saveData(userData: user)
                }
            }
        }
    }
    
    func signOut() {
        
        do {
            try Auth.auth().signOut()
            print("Signed out from Firebase")
        } catch {
            print("Firebase sign-out error: \(error.localizedDescription)")
        }
        
        GIDSignIn.sharedInstance.signOut()
        
        guard let context = context else { return }
        
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let users = try context.fetch(fetchRequest)
            users.forEach { context.delete($0) }
            try context.save()
            print("Deleted user from Core Data")
        } catch {
            print("Failed to delete user from Core Data: \(error.localizedDescription)")
        }
        
        // 4. Update UI state
        DispatchQueue.main.async {
            self.isSignedIn = false
        }
    }
    
    private func saveData(userData: GIDGoogleUser) {
        withAnimation {
            if let context = context {
                let userProfile = UserProfile(context: context)
                userProfile.email = userData.profile?.email
                userProfile.name = userData.profile?.name
                userProfile.userId = UUID(uuidString: userData.userID ?? "")
                userProfile.givenName = userData.profile?.givenName
                userProfile.imageUrl = userData.profile?.imageURL(withDimension: 200)?.absoluteString
                
                self.userprofile = userProfile
                do {
                    try context.save()
                } catch {
                    print("Error occured \(error)")
                }
            }
        }
    }
    
    
    func fetchProfile() {
        guard let context else {
            print("Context not set")
            return
        }
        
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.sortDescriptors = []
        
        do {
            userprofile = try context.fetch(request).first
        } catch {
            print("Failed to fetch users: \(error)")
        }
    }
    
}
