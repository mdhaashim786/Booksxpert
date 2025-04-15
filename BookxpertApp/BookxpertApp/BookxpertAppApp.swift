//
//  BookxpertAppApp.swift
//  BookxpertApp
//
//  Created by mhaashim on 15/04/25.
//

import SwiftUI

@main
struct BookxpertAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
