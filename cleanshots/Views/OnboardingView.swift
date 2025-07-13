import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showMainApp = false
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.backgroundMain
                .ignoresSafeArea()
            
            if showMainApp {
                ContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 0) {
                    // Skip Button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showMainApp = true
                            }
                        }
                        .font(CleanTypography.bodyMedium)
                        .foregroundColor(CleanColors.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Page Content
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(page: page, isLastPage: index == pages.count - 1) {
                                if index == pages.count - 1 {
                                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showMainApp = true
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        currentPage = index + 1
                                    }
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom Page Indicator
                    PageIndicator(currentPage: currentPage, totalPages: pages.count)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showMainApp)
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onNext: () -> Void
    
    @State private var animateIcon = false
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated Icon
            ZStack {
                // Pulsing Background
                Circle()
                    .fill(page.gradient)
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .opacity(animateIcon ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
            }
            
            // Content
            VStack(spacing: 24) {
                Text(page.title)
                    .font(CleanTypography.displayMedium)
                    .foregroundStyle(.linearGradient(
                        colors: [CleanColors.textPrimary, CleanColors.textSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .multilineTextAlignment(.center)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                Text(page.description)
                    .font(CleanTypography.bodyLarge)
                    .foregroundColor(CleanColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                // Feature Points
                if !page.features.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                            OnboardingFeature(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description
                            )
                            .scaleEffect(animateContent ? 1.0 : 0.9)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: animateContent
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // Action Button
            Button(isLastPage ? "Get Started" : "Next") {
                onNext()
            }
            .neuralStyle(size: .xlarge, variant: isLastPage ? .primary : .secondary)
            .scaleEffect(animateContent ? 1.0 : 0.9)
            .opacity(animateContent ? 1.0 : 0.0)
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateIcon = true
            }
        }
    }
}

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(LinearGradient.neuralPrimary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CleanTypography.headlineSmall)
                    .foregroundColor(CleanColors.textPrimary)
                
                Text(description)
                    .font(CleanTypography.bodySmall)
                    .foregroundColor(CleanColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? LinearGradient.neuralPrimary : LinearGradient(colors: [CleanColors.surfaceElevated], startPoint: .leading, endPoint: .trailing))
                    .frame(width: index == currentPage ? 32 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Onboarding Data Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let features: [OnboardingFeature]
    
    struct OnboardingFeature {
        let icon: String
        let title: String
        let description: String
    }
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            icon: "photo.stack.fill",
            title: "Welcome to\nClean Screenshots",
            description: "Transform your screenshot chaos into organized brilliance with AI-powered intelligence.",
            gradient: .neuralPrimary,
            features: []
        ),
        
        OnboardingPage(
            icon: "brain.head.profile",
            title: "AI-Powered\nRecognition",
            description: "Advanced OCR technology reads and understands your screenshots automatically.",
            gradient: .successFlow,
            features: [
                OnboardingFeature(
                    icon: "text.viewfinder",
                    title: "Smart Text Recognition",
                    description: "Extracts text with neural precision"
                ),
                OnboardingFeature(
                    icon: "tag.fill",
                    title: "Auto Categorization",
                    description: "Intelligently sorts by content type"
                ),
                OnboardingFeature(
                    icon: "magnifyingglass",
                    title: "Instant Search",
                    description: "Find any screenshot by content"
                )
            ]
        ),
        
        OnboardingPage(
            icon: "square.grid.3x3.fill",
            title: "Effortless\nOrganization",
            description: "Keep your screenshots perfectly organized without lifting a finger.",
            gradient: .sunsetGlow,
            features: [
                OnboardingFeature(
                    icon: "folder.fill",
                    title: "Smart Categories",
                    description: "Websites, chats, documents & more"
                ),
                OnboardingFeature(
                    icon: "doc.on.doc.fill",
                    title: "Duplicate Detection",
                    description: "Automatically finds similar images"
                ),
                OnboardingFeature(
                    icon: "trash.fill",
                    title: "Batch Actions",
                    description: "Delete multiple screenshots at once"
                )
            ]
        ),
        
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Privacy\nFirst",
            description: "Your screenshots never leave your device. Complete privacy guaranteed.",
            gradient: LinearGradient(
                colors: [CleanColors.accentStart, Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            features: [
                OnboardingFeature(
                    icon: "iphone",
                    title: "Local Processing",
                    description: "All AI runs on your device"
                ),
                OnboardingFeature(
                    icon: "wifi.slash",
                    title: "No Cloud Sync",
                    description: "Zero data transmission"
                ),
                OnboardingFeature(
                    icon: "checkmark.shield",
                    title: "GDPR Compliant",
                    description: "Full European privacy standards"
                )
            ]
        )
    ]
}