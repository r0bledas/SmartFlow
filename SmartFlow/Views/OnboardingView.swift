import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    
    @State private var step = 1
    @State private var showingSetup = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if step == 1 {
                LanguageSelectionView(
                    appLanguage: $appLanguage,
                    title: L("Choose Language"),
                    continueText: L("Continue")
                ) {
                    withAnimation { step = 2 }
                }
            } else if step == 2 {
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "drop.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    
                    Text(L("Welcome to SmartFlow"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(L("Monitor your water usage in real-time"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            showingSetup = true
                        }) {
                            Text(L("Setup Sensor Now"))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            withAnimation { hasSeenOnboarding = true }
                        }) {
                            Text(L("Skip for now"))
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .sheet(isPresented: $showingSetup, onDismiss: {
                    // When setup sheet is dismissed, finish onboarding
                    withAnimation { hasSeenOnboarding = true }
                }) {
                    DeviceSetupView()
                }
            }
        }
        .environment(\.locale, .init(identifier: appLanguage))
    }
}

struct LanguageSelectionView: View {
    @Binding var appLanguage: String
    let title: String
    let continueText: String
    var onContinue: () -> Void
    
    let languages = [
        ("en", "English 🇺🇸"),
        ("es", "Español 🇲🇽")
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "globe")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 60)
            
            Text(title)
                .font(.title)
                .bold()
            
            VStack(spacing: 16) {
                ForEach(languages, id: \.0) { lang in
                    Button(action: {
                        appLanguage = lang.0
                    }) {
                        HStack {
                            Text(lang.1)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if appLanguage.starts(with: lang.0) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: onContinue) {
                Text(continueText)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
