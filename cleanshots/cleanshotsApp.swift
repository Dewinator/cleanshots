//
//  cleanshotsApp.swift
//  cleanshots
//
//  Created by Enrico Becker on 13.07.25.
//

import SwiftUI
import SwiftData

@main
struct cleanshotsApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Screenshot.self, Tag.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                ContentView()
                    .modelContainer(modelContainer)
            } else {
                OnboardingView()
                    .modelContainer(modelContainer)
            }
        }
    }
}
