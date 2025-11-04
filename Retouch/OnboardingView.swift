import SwiftUI

struct OnboardingView: View {
    @State private var selection = 0
    
    // We'll navigate to this screen when done
    @State private var isDoneOnboarding = false

    var body: some View {
        if isDoneOnboarding {
            // This is the placeholder for your Photo Import screen (Section 2)
            PhotoImportView()
        } else {
            VStack {
                // The swipeable pages
                TabView(selection: $selection) {
                    OnboardingPageContent(
                        iconName: "auto.awesome.fill",
                        title: "Welcome to Retouch",
                        description: "Make your photos stand out with powerful, easy-to-use tools."
                    )
                    .tag(0)
                    
                    OnboardingPageContent(
                        iconName: "paintbrush.fill",
                        title: "Pro-Level Toolkit",
                        description: "Over 20 high-quality filters and a full retouch suite."
                    )
                    .tag(1)
                    
                    OnboardingPageContent(
                        iconName: "wand.and.rays",
                        title: "AI-Powered Editing",
                        description: "Remove objects, smooth skin, and enhance lighting in just a tap."
                    )
                    .tag(2)
                    
                    OnboardingPageContent(
                        iconName: "photo.on.rectangle.angled",
                        title: "Get Started",
                        description: "Import a photo from your library or take a new one to begin."
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle()) // This makes it swipeable
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // "Get Started" Button
                Button(action: {
                    if selection == 3 {
                        // Last page: ask for permissions & move to app
                        // We will add permission logic in the next step
                        withAnimation {
                            isDoneOnboarding = true
                        }
                    } else {
                        // Not last page: just go to next slide
                        withAnimation {
                            selection += 1
                        }
                    }
                }) {
                    Text(selection == 3 ? "Get Started" : "Next")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .preferredColorScheme(.dark)
        }
    }
}

// A reusable view for the content of each onboarding page
struct OnboardingPageContent: View {
    var iconName: String
    var title: String
    var description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 100))
                .foregroundColor(.purple.opacity(0.8))
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
