import SwiftUI
import SwiftData

struct ScreenshotGridView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var selectedScreenshots: Set<Screenshot> = []
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.backgroundMain
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Futuristic Search Bar
                FuturisticSearchBar(text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        screenshotManager.searchText = newValue
                        screenshotManager.loadScreenshots()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                // Category Filter Carousel
                CategoryFilterCarousel(selectedCategory: $screenshotManager.selectedCategory)
                    .onChange(of: screenshotManager.selectedCategory) { _, _ in
                        screenshotManager.loadScreenshots()
                    }
                    .padding(.top, 24)
                
                // Screenshot Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(screenshotManager.screenshots, id: \.id) { screenshot in
                            PremiumScreenshotCell(
                                screenshot: screenshot,
                                isSelected: selectedScreenshots.contains(screenshot)
                            ) {
                                toggleSelection(screenshot)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !selectedScreenshots.isEmpty {
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .neuralStyle(size: .small, variant: .danger)
                }
            }
        }
        .alert("Delete Screenshots", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                screenshotManager.deleteScreenshots(Array(selectedScreenshots))
                selectedScreenshots.removeAll()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedScreenshots.count) screenshot(s)?")
        }
    }
    
    private func toggleSelection(_ screenshot: Screenshot) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedScreenshots.contains(screenshot) {
                selectedScreenshots.remove(screenshot)
            } else {
                selectedScreenshots.insert(screenshot)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Suche...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct CategoryFilterView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Alle Kategorien Button
                CategoryChip(
                    category: nil,
                    isSelected: screenshotManager.selectedCategory == nil
                ) {
                    screenshotManager.selectedCategory = nil
                    screenshotManager.loadScreenshots()
                }
                
                // Einzelne Kategorien
                ForEach(ScreenshotCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: screenshotManager.selectedCategory == category
                    ) {
                        screenshotManager.selectedCategory = category
                        screenshotManager.loadScreenshots()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct CategoryChip: View {
    let category: ScreenshotCategory?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.caption)
                } else {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption)
                    Text("Alle")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? (category?.color ?? .accentColor) : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
        }
    }
}