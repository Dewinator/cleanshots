import SwiftUI

struct FuturisticSearchBar: View {
    @Binding var text: String
    @State private var isActive = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search Icon with Animation
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isActive ? CleanColors.primaryStart : CleanColors.textSecondary)
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            // Text Field
            TextField("Search screenshots...", text: $text)
                .font(CleanTypography.bodyMedium)
                .foregroundColor(CleanColors.textPrimary)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isActive = true
                    }
                }
                .onSubmit {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isActive = false
                    }
                }
            
            // Clear Button
            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(CleanColors.textSecondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(CleanColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isActive ? 
                                LinearGradient.neuralPrimary : 
                                LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isActive ? 2 : 1
                        )
                )
        )
        .shadow(color: isActive ? CleanColors.primaryStart.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

struct CategoryFilterCarousel: View {
    @Binding var selectedCategory: ScreenshotCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" Button
                CategoryFilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    color: LinearGradient.neuralPrimary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = nil
                    }
                }
                
                // Category Buttons
                ForEach(ScreenshotCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: LinearGradient(
                            colors: [category.brandColor, category.brandColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(CleanTypography.captionLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : CleanColors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : LinearGradient(colors: [CleanColors.surfaceElevated], startPoint: .leading, endPoint: .trailing))
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? 
                                    LinearGradient(colors: [Color.white.opacity(0.3)], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: isSelected ? CleanColors.primaryStart.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}