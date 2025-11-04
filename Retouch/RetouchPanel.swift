import SwiftUI
import Vision // <-- ADD THIS LINE

struct RetouchPanel: View {
    // The image *before* this tool was opened
    let originalImage: UIImage
    
    // Binding to the main edited image
    @Binding var editedImage: UIImage
    
    // Service to process the image
    private let service = RetouchService()
    
    // State for this panel
    @State private var faceObservation: VNFaceObservation?
    @State private var isLoading = true
    @State private var noFaceFound = false
    
    // State for slider values
    @State private var skinAmount = 0.0
    @State private var eyeAmount = 0.0
    @State private var teethAmount = 0.0
    
    // Timer to delay processing (for performance)
    @State private var updateTimer: Timer?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Detecting face...")
                    .foregroundColor(.gray)
                    .font(.caption)
            } else if noFaceFound {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("No face detected in this photo.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                // Show the sliders
                slidersView
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical)
        .onAppear {
            // When panel opens, detect the face
            service.detectFace(on: originalImage) { observation in
                self.isLoading = false
                self.faceObservation = observation
                self.noFaceFound = (observation == nil)
            }
        }
        .onChange(of: [skinAmount, eyeAmount, teethAmount]) { _ in
            scheduleImageUpdate()
        }
    }
    
    /// The view containing all sliders
    private var slidersView: some View {
        VStack(spacing: 15) {
            AdjustSlider(label: "Skin Smoothing", value: $skinAmount)
            AdjustSlider(label: "Eye Brightening", value: $eyeAmount)
            AdjustSlider(label: "Teeth Whitening", value: $teethAmount)
        }
    }
    
    /// Applies *all* adjustments to the base image
    private func applyRetouch() {
        guard let faceObservation else { return }

        // Run on background thread
        Task {
            let finalImage = service.applyRetouch(
                to: originalImage, // Always start from the tool's base image
                observation: faceObservation,
                skinSmooth: skinAmount,
                eyeBrighten: eyeAmount,
                teethWhiten: teethAmount
            )
            
            // Update UI on main thread
            await MainActor.run {
                editedImage = finalImage
            }
        }
    }
    
    /// Schedules an image update to avoid lagging the slider
    private func scheduleImageUpdate() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            applyRetouch()
        }
    }
}

/// A reusable Slider view
struct AdjustSlider: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
            Slider(value: $value, in: 0.0...1.0)
                .tint(.purple)
        }
        .padding(.horizontal)
    }
}

// Allows .onChange to watch multiple values
extension Array: Equatable where Element: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.count == rhs.count && !zip(lhs, rhs).contains { $0 != $1 }
  }
}

#Preview {
    struct PreviewWrapper: View {
        @State var image = UIImage(systemName: "photo")!
        var body: some View {
            RetouchPanel(originalImage: UIImage(systemName: "photo")!, editedImage: $image)
                .preferredColorScheme(.dark)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
    return PreviewWrapper()
}
