//
//  FoodToruApp.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import SwiftUI

@main
struct FoodToruApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Initialize pre-configured API key if available
        // This allows the API key to be set via environment variables or Info.plist
        // and will be automatically stored in Keychain on first launch
        KeychainService.shared.initializePreconfiguredKeyIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
