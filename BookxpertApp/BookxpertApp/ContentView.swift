//
//  ContentView.swift
//  BookxpertApp
//
//  Created by mhaashim on 15/04/25.
//

import SwiftUI
import GoogleSignInSwift

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = LoginViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isSignedIn {
                //NavigationView {
                VStack {
                    Text("Welcome to the app")
                    Button(action: {
                        viewModel.signOut()
                    }, label: {
                        Text("Signout")
                    })
                    
                }
            } else {
                GoogleSignInButton {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let presentingVC = windowScene.windows.first?.rootViewController  {
                        viewModel.signInWithGoogle(presentingVC: presentingVC)
                    }
                }
                .frame(width: 200, height: 50)
            }
        }
        .onAppear {
            viewModel.setContext(viewContext)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
