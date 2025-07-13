//
//  ContentView.swift
//  cleanshots
//
//  Created by Enrico Becker on 13.07.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var screenshotManager = ScreenshotManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScreenshotGridView()
                    .environmentObject(screenshotManager)
            }
            .tabItem {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Screenshots")
            }
            .tag(0)
            
            NavigationStack {
                ImportView()
                    .environmentObject(screenshotManager)
            }
            .tabItem {
                Image(systemName: "square.and.arrow.down")
                Text("Import")
            }
            .tag(1)
            
            NavigationStack {
                SettingsView()
                    .environmentObject(screenshotManager)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            screenshotManager.setModelContext(modelContext)
        }
    }
}

#Preview {
    ContentView()
}
