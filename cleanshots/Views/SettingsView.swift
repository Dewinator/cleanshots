import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var duplicateThreshold = 5
    @State private var autoDeleteDuplicates = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.backgroundMain
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "gear.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(LinearGradient.neuralPrimary)
                        
                        Text("Settings")
                            .font(CleanTypography.displayMedium)
                            .foregroundStyle(.linearGradient(
                                colors: [CleanColors.textPrimary, CleanColors.textSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                    .padding(.top, 20)
                    
                    // Duplicate Detection Section
                    GlassMorphismCard(intensity: 0.08, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Duplicate Detection")
                                .font(CleanTypography.headlineMedium)
                                .foregroundColor(CleanColors.textPrimary)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Sensitivity")
                                        .font(CleanTypography.bodyMedium)
                                        .foregroundColor(CleanColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $duplicateThreshold) {
                                        Text("Low").tag(10)
                                        Text("Medium").tag(5)
                                        Text("High").tag(3)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(width: 180)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Auto-delete duplicates")
                                            .font(CleanTypography.bodyMedium)
                                            .foregroundColor(CleanColors.textPrimary)
                                        Text("Automatically remove duplicate screenshots")
                                            .font(CleanTypography.captionMedium)
                                            .foregroundColor(CleanColors.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $autoDeleteDuplicates)
                                        .toggleStyle(SwitchToggleStyle(tint: CleanColors.primaryStart))
                                }
                            }
                        }
                        .padding(20)
                    }
                    
                    // App Info Section
                    GlassMorphismCard(intensity: 0.08, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("About")
                                .font(CleanTypography.headlineMedium)
                                .foregroundColor(CleanColors.textPrimary)
                            
                            VStack(spacing: 12) {
                                SettingsRow(title: "Version", value: "1.0.0")
                                SettingsRow(title: "Developer", value: "Enrico Becker")
                                SettingsRow(title: "Build", value: "2025.01")
                            }
                        }
                        .padding(20)
                    }
                    
                    // Privacy Section
                    GlassMorphismCard(intensity: 0.08, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .font(.title2)
                                    .foregroundStyle(LinearGradient.successFlow)
                                
                                Text("Privacy & Security")
                                    .font(CleanTypography.headlineMedium)
                                    .foregroundColor(CleanColors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                PrivacyFeature(
                                    icon: "iphone",
                                    title: "Local Processing",
                                    description: "All data stays on your device"
                                )
                                
                                PrivacyFeature(
                                    icon: "wifi.slash",
                                    title: "No Cloud Sync",
                                    description: "No data transmitted to servers"
                                )
                                
                                PrivacyFeature(
                                    icon: "checkmark.shield",
                                    title: "GDPR Compliant",
                                    description: "Full privacy compliance"
                                )
                            }
                        }
                        .padding(20)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(CleanTypography.bodyMedium)
                .foregroundColor(CleanColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(CleanTypography.bodyMedium)
                .foregroundColor(CleanColors.textPrimary)
        }
    }
}

struct PrivacyFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(CleanColors.accentStart)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CleanTypography.bodyMedium)
                    .foregroundColor(CleanColors.textPrimary)
                
                Text(description)
                    .font(CleanTypography.captionMedium)
                    .foregroundColor(CleanColors.textSecondary)
            }
            
            Spacer()
        }
    }
}