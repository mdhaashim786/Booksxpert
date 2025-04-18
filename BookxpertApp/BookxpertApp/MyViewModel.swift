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

class MyViewModel: ObservableObject {
    
    // Just added to store userProfile
    @Published var userprofile: UserProfile?
    @Published var isSignedIn: Bool = false
    @Published var isFetchingObjects: (Bool,Error?) = (true, nil)
    
    let pdfUrl: String = "https://fssservices.bookxpert.co/GeneratedPDF/Companies/nadc/2024-2025/BalanceSheet.pdf"
    let objectsUrl: String = "https://api.restful-api.dev/objects"
    
    
    private var context: NSManagedObjectContext?
    @Published var storedObjects: [PersistentResponse] = []
    
    func fetchObjectsFromApi(context: NSManagedObjectContext) {
        Task {
            let urlRequest = URLRequest(url: URL(string: objectsUrl)!)
            do {
                let (data, _) = try await  URLSession.shared.data(for: urlRequest)
                print(data)
                let decodedData = try JSONDecoder().decode([ObjectsResponse].self, from: data)
                DispatchQueue.main.async {
                    self.isFetchingObjects = (false, nil)
                    self.saveObjectResponse(decodedData, context: context)
                }
                print("✅ Stored objects fetched from api")
            } catch {
                DispatchQueue.main.async {
                    self.isFetchingObjects = (false, error)
                }
                print("Network error - \(error.localizedDescription)")
            }
        }
    }
    
    func saveObjectResponse(_ objects: [ObjectsResponse], context: NSManagedObjectContext) {
        for object in objects {
            
            let storedObject = PersistentResponse(context: context)
            storedObject.id = object.id
            storedObject.name = object.name
            
            if let data = object.data {
                let storedData = MyData(context: context)
                storedData.color = data.color
                storedData.capacity = data.capacity
                storedData.generation = data.generation
                storedData.price = data.price
                storedData.screenSize = data.screenSize
                storedData.desc = data.description
                storedData.strapColor = data.strapColor
                storedData.caseSize = data.caseSize
                storedData.capacitygb = data.capacitygb
                storedData.year = data.year
                storedData.cpuModel = data.cpuModel
                storedData.hardDiskSize = data.hardDiskSize
                
                storedObject.data = storedData
            }
            
            storedObjects.append(storedObject)
        }

        do {
            try context.save()
            print("✅ Saved to Core Data")
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
    
    func fetchStoredObjects() {
        guard let context else {
            print("Context not set")
            return
        }
        
        let fetchRequest: NSFetchRequest<PersistentResponse> = PersistentResponse.fetchRequest()
        let sortDescriptor = NSSortDescriptor(keyPath: \PersistentResponse.name, ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            do {
                storedObjects = try context.fetch(fetchRequest)
                let isStoredObjectsEmpty = storedObjects.isEmpty
                print("✅ Stored ojects fetched from Core Data is \(isStoredObjectsEmpty ? "empty": "not empty")")
                if isStoredObjectsEmpty {
                    self.fetchObjectsFromApi(context: context)
                }
            } catch {
                print("❌ Failed to fetch objects: \(error)")
            }
        }
    
    func deleteAllObjects(context: NSManagedObjectContext) {
        
        let fetchRequest: NSFetchRequest<PersistentResponse> = PersistentResponse.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
            print("✅ All objects deleted")
        } catch {
            print("❌ Failed to delete objects: \(error)")
        }
    }

    
   func deleteItems(offsets: IndexSet) {
       guard let context else {
           print("Context not set")
           return
       }
       
        withAnimation {
            for index in offsets {
                let objectToDelete = storedObjects[index]
                context.delete(objectToDelete)
            }
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    var userPhoto: Image? {
        if let imageData = userprofile?.imageUrl,
           let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
            
        }
        return nil
    }
    
    var userName: String {
        userprofile?.name ?? ""
    }
    
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
                    Task {
                        await self.saveData(userData: user)
                    }
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
        
        deleteAllObjects(context: context)
        
        // 4. Update UI state
        DispatchQueue.main.async {
            self.isSignedIn = false
        }
    }
    
    private func saveData(userData: GIDGoogleUser) async {
        Task {
            if let context = context {
                let userProfile = UserProfile(context: context)
                userProfile.email = userData.profile?.email
                userProfile.name = userData.profile?.name
                userProfile.userId = UUID(uuidString: userData.userID ?? "")
                userProfile.givenName = userData.profile?.givenName
                if let imageUrl = userData.profile?.imageURL(withDimension: 200) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: imageUrl)
                        userProfile.imageUrl = data
                    } catch {
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.userprofile = userProfile
                }
                do {
                    try context.save()
                } catch {
                    print("Error occured \(error)")
                }
            }
        }
    }
    
    func saveImage(imageData: Data?) {
        guard let context else {
            print("Context not set")
            return
        }
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.sortDescriptors = []
        
        do {
            let profileToUpdate = try context.fetch(request).first
            profileToUpdate?.imageUrl = imageData
            try context.save()
        } catch {
            print("Failed to fetch users: \(error)")
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
