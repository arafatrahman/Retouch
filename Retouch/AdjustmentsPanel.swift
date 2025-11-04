import SwiftUI

struct AdjustmentsPanel: View {
    // The image *before* this tool was opened
    let originalImage: UIImage
    
    // Binding to the main edited image
    @Binding var editedImage: UIImage

    // Service to process the image
    private let service = AdjustmentService()
    
    // State to hold all slider values
    @State private var values = AdjustmentValues()
    
    // State for which slider is active
    @State private var selectedAdjustment: AdjustmentType = .exposure
    
    // Timer to delay processing (for performance)
    @State private var updateTimer: Timer?
    
    var body: some View {
        VStack(spacing: 15) {
            // 1. The Main Slider
            adjustmentSlider
            
            // 2. The List of Tools
            adjustmentList
        }
        .padding(.vertical)
        .onChange(of: values) { _ in
            // When any slider value changes,
            // schedule an update (don't process every tiny move)
            scheduleImageUpdate()
        }
    }
    
    /// 1. The main slider that changes based on the selected tool
    @ViewBuilder
    private var adjustmentSlider: some View {
        VStack {
            // Text showing the current value
            Text(String(format: "%.2f", currentSliderValue))
                .font(.caption)
                .foregroundColor(.white)
            
            Slider(value: currentSliderBinding, in: selectedAdjustment.range) { isEditing in
                // When the user lets go of the slider,
                // apply the change immediately.
                if !isEditing {
                    applyAdjustments()
                }
            }
            .tint(.purple)
            
            // "Reset" button
            Button("Reset") {
                resetCurrentAdjustment()
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
    
    /// 2. The scrollable list of adjustment tools
    private var adjustmentList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(AdjustmentType.allCases) { adj in
                    Button {
                        selectedAdjustment = adj
                    } label: {
                        VStack {
                            Image(systemName: adjIcon(adj))
                            Text(adj.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedAdjustment == adj ? .purple : .white)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Logic
    
    /// A helper to get a nice icon for each adjustment
    private func adjIcon(_ adj: AdjustmentType) -> String {
        switch adj {
        case .exposure: return "sun.max.fill"
        case .contrast: return "circle.lefthalf.filled"
        case .highlights: return "sun.min.fill"
        case .shadows: return "shadow"
        case .saturation: return "drop.fill"
        case .vibrance: return "flame.fill"
        case .temperature: return "thermometer"
        case .tint: return "eyedropper.halffull"
        case .sharpen: return "triangle.fill"
        case .vignette: return "circle.dotted"
        }
    }
    
    /// Creates a 2-way binding to the correct @State var in `values`
    private var currentSliderBinding: Binding<Double> {
        Binding<Double>(
            get: {
                switch selectedAdjustment {
                case .exposure: return values.exposure
                case .contrast: return values.contrast
                case .highlights: return values.highlights
                case .shadows: return values.shadows
                case .saturation: return values.saturation
                case .vibrance: return values.vibrance
                case .temperature: return values.temperature
                case .tint: return values.tint
                case .sharpen: return values.sharpen
                case .vignette: return values.vignette
                }
            },
            set: { newValue in
                switch selectedAdjustment {
                case .exposure: values.exposure = newValue
                case .contrast: values.contrast = newValue
                case .highlights: values.highlights = newValue
                case .shadows: values.shadows = newValue
                case .saturation: values.saturation = newValue
                case .vibrance: values.vibrance = newValue
                case .temperature: values.temperature = newValue
                case .tint: values.tint = newValue
                case .sharpen: values.sharpen = newValue
                case .vignette: values.vignette = newValue
                }
            }
        )
    }
    
    /// Gets the current value as a Double (for the Text label)
    private var currentSliderValue: Double {
        currentSliderBinding.wrappedValue
    }
    
    /// Resets only the *current* slider to its default
    private func resetCurrentAdjustment() {
        currentSliderBinding.wrappedValue = selectedAdjustment.defaultValue
    }
    
    /// Applies *all* adjustments to the base image
    private func applyAdjustments() {
        // Run on background thread
        Task {
            let finalImage = service.applyAdjustments(
                to: originalImage, // Use the "base" image
                values: values
            )
            // Update UI on main thread
            await MainActor.run {
                editedImage = finalImage
            }
        }
    }
    
    /// Schedules an image update to avoid lagging the slider
    private func scheduleImageUpdate() {
        // Invalidate previous timer
        updateTimer?.invalidate()
        
        // Start a new timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            applyAdjustments()
        }
    }
}

// Allows the `values` struct to be used with .onChange
extension AdjustmentValues: Equatable {
    static func == (lhs: AdjustmentValues, rhs: AdjustmentValues) -> Bool {
        return lhs.exposure == rhs.exposure &&
               lhs.contrast == rhs.contrast &&
               lhs.highlights == rhs.highlights &&
               lhs.shadows == rhs.shadows &&
               lhs.saturation == rhs.saturation &&
               lhs.vibrance == rhs.vibrance &&
               lhs.temperature == rhs.temperature &&
               lhs.tint == rhs.tint &&
               lhs.sharpen == rhs.sharpen &&
               lhs.vignette == rhs.vignette
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var image = UIImage(systemName: "photo")!
        var body: some View {
            AdjustmentsPanel(originalImage: UIImage(systemName: "photo")!, editedImage: $image)
                .preferredColorScheme(.dark)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
    return PreviewWrapper()
}
