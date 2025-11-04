import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingPremium = false
    
    // Get app version
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 1. PREMIUM SECTION
                Section {
                    Button(action: { isShowingPremium = true }) {
                        HStack(spacing: 15) {
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text("Retouch Premium")
                                    .font(.headline)
                                Text("Unlock all filters & AI tools")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 2. HELP & FEEDBACK
                Section(header: Text("Support")) {
                    Link(destination: URL(string: "https://www.google.com")!) {
                        Label("Help & Tutorials", systemImage: "questionmark.circle")
                    }
                    Link(destination: URL(string: "https://www.google.com")!) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
                
                // 3. LEGAL & ABOUT
                Section(header: Text("About")) {
                    Link(destination: URL(string: "https://www.google.com")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    Link(destination: URL(string: "https://www.google.com")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                    HStack {
                        Label("App Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingPremium) {
                PremiumView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
