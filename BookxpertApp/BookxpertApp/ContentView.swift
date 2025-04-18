//
//  ContentView.swift
//  BookxpertApp
//
//  Created by mhaashim on 15/04/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = MyViewModel()
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceOptions = false
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if viewModel.isSignedIn {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Welcome Header
                            VStack(spacing: 4) {
                                Text("Welcome")
                                    .font(.largeTitle)
                                    .bold()
                                
                                Text(viewModel.userName)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top)
                            
                            // Profile Image
                            ZStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                } else if let photo = viewModel.userPhoto {
                                    photo
                                        .resizable()
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            .shadow(radius: 4)
                            
                            // Change Photo Button
                            Button {
                                showSourceOptions = true
                            } label: {
                                Label("Change Profile Photo", systemImage: "photo")
                                    .font(.headline)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
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
                            
                            
                            // Object List or Error
                            Group {
                                if let error = viewModel.isFetchingObjects.1 {
                                    Text("Server error while fetching the objects.\nNo objects to show.")
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    Section(header: Text("Stored Objects")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)) {
                                            List {
                                                ForEach(viewModel.storedObjects, id: \.id) { item in
                                                    VStack(alignment: .leading) {
                                                        Text(item.name ?? "Unnamed")
                                                            .font(.body)
                                                        if let capacity = item.data?.capacity {
                                                            Text("Capacity: \(capacity)")
                                                                .font(.subheadline)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                }
                                                .onDelete(perform: viewModel.deleteItems)
                                            }
                                            .frame(height: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                }
                            }
                            // PDF Viewer Link
                            if let pdfURL = URL(string: viewModel.pdfUrl) {
                                NavigationLink(destination: PDFKitView(url: pdfURL)) {
                                    Label("View PDF", systemImage: "square.text.square")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            } else {
                                Text("Invalid PDF URL")
                                    .foregroundColor(.gray)
                            }
                            
                            Button(role: .destructive) {
                                viewModel.signOut()
                            } label: {
                                Text("Sign Out")
                                    .bold()
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .navigationTitle("Dashboard")
                }
                
            } else {
                VStack(spacing: 32) {
                    
                    Text("Bookxpert")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 149/255, blue: 215/255))
                        .shadow(radius: 6)
                    
                    Text("Your Accounting partner")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))
                    GoogleSignInButton(action: {
                        isLoading = true
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let presentingVC = windowScene.windows.first?.rootViewController {
                            viewModel.signInWithGoogle(presentingVC: presentingVC)
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoading = false
                        }
                    }, isLoading: isLoading)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage, { _, newImage in
            viewModel.saveImage(imageData: newImage?.jpegData(compressionQuality: 1.0))
            
        })
        .onChange(of: viewModel.isSignedIn, { _, newValue in
            if newValue {
                viewModel.fetchStoredObjects()
            }
        })
        .onAppear {
            viewModel.askNotificationPermissions()
            viewModel.setContext(viewContext)
        }
    }
}


struct GoogleSignInButton: View {
    var action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                
                Text("Sign in with Google")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(width: 250, height: 50)
            .background(LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(14)
            .shadow(radius: 5)
        }
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        )
        .disabled(isLoading)
    }
}
