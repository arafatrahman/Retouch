import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.5 // Start with some opacity

    var body: some View {
        // If 'isActive' is true, show Onboarding. Otherwise, show Splash.
        if isActive {
            OnboardingView()
        } else {
            ZStack {
                // Background (optional, could be your sample photo)
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Your App Logo
                    Image(systemName: "auto.awesome") // Placeholder icon
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text("Retouch")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .opacity(opacity) // Apply the fade-in effect
                .onAppear {
                    // Animate the opacity to 1.0 (fully visible)
                    withAnimation(.easeIn(duration: 1.5)) {
                        self.opacity = 1.0
                    }
                    
                    // Wait for 2.5 seconds, then activate the next screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
