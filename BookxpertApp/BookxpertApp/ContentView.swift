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
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceOptions = false
    
    var body: some View {
        VStack {
            if viewModel.isSignedIn {
                NavigationStack {
                    VStack {
                        Text("Welcome \(viewModel.userName) to the app")
                        
                        VStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                
                            } else {
                                if let photo = viewModel.userPhoto {
                                    photo
                                        .resizable()
                                }
                            }
                        }
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        
                        Button(action: {
                            showSourceOptions = true
                        }) {
                            Label("Change profile photo", systemImage: "photo")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .confirmationDialog("Choose Image Source", isPresented: $showSourceOptions, titleVisibility: .visible) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button("Camera") {
                                    sourceType = .camera
                                    showImagePicker = true
                                }
                            }
                            Button("Gallery") {
                                sourceType = .photoLibrary
                                showImagePicker = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        
                        Button(action: {
                            viewModel.signOut()
                        }, label: {
                            Text("Signout")
                        })
                        
                        if let pdfURL = URL(string: viewModel.pdfUrl) {
                            NavigationLink(destination: PDFKitView(url: pdfURL)) {
                                Image(systemName: "square.text.square")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundStyle(.blue)
                            }
                        } else {
                            Text("Invalid PDF URL")
                                .foregroundColor(.gray)
                        }

                    }
                    
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage, { _, newImage in
            viewModel.saveImage(imageData: newImage?.jpegData(compressionQuality: 1.0))
            
        })
        
        .onAppear {
            viewModel.setContext(viewContext)
        }
    }
}
