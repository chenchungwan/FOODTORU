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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
