import SwiftUI

struct PremiumView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. HEADER
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.purple.opacity(0.8))
                        .padding(.top, 40)
                    
                    Text("Unlock Retouch Premium")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Get full access to all filters, AI tools, and advanced features.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 2. FEATURE LIST
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(icon: "camera.filters", text: "Unlock all 20+ Premium Filters")
                        FeatureRow(icon: "wand.and.rays", text: "Unlimited AI Object Removal")
                        FeatureRow(icon: "face.smiling", text: "Advanced Portrait Retouch Tools")
                        FeatureRow(icon: "textformat", text: "Premium Fonts & Stickers")
                        FeatureRow(icon: "square.and.arrow.down", text: "Export in Full Resolution")
                        FeatureRow(icon: "nosign", text: "Remove All Ads (if any)")
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            
            // 3. BOTTOM PURCHASE SECTION
            VStack(spacing: 15) {
                // TODO: Add real StoreKit logic
                
                // --- Dummy Price Buttons (FIXED) ---
                Button(action: { /* Start purchase */ }) {
                    Text("Unlock Yearly - $29.99") // <-- Fixed
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                Button(action: { /* Start purchase */ }) {
                    Text("Unlock Monthly - $4.99") // <-- Fixed
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                // Restore Purchases
                Button(action: { /* Restore */ }) {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding([.horizontal, .bottom])
            .background(Color.black.edgesIgnoringSafeArea(.bottom)) // Pushes buttons to bottom
            .frame(maxHeight: .infinity, alignment: .bottom)
            
            // 4. CLOSE BUTTON
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
    }
}

// Helper for feature list rows
struct FeatureRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.purple)
                .frame(width: 30)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    PremiumView()
}
