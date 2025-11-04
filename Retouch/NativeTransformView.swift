import SwiftUI

struct NativeTransformView: View {
    
    // The image to edit
    let image: UIImage
    
    // A callback to pass the edited image back
    var onComplete: (UIImage?) -> Void
    
    // Service to render the final image
    private let service = TransformService()
    
    // State for all transforms
    @State private var straightenAngle: Angle = .zero
    @State private var rotationAngle: Angle = .zero
    @State private var isFlippedH = false
    @State private var isFlippedV = false
    
    // State for tools
    @State private var isStraightenActive = false
    
    // We use a temporary image for previews
    @State private var previewImage: UIImage

    init(image: UIImage, onComplete: @escaping (UIImage?) -> Void) {
        self.image = image
        self._previewImage = State(initialValue: image)
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. TOP BAR
            HStack {
                Button("Cancel") {
                    onComplete(nil) // Send back nil
                }
                Spacer()
                Button("Done") {
                    // Apply transforms permanently
                    let finalImage = service.applyTransforms(
                        to: image,
                        straightenAngle: straightenAngle,
                        rotationAngle: rotationAngle,
                        isFlippedH: isFlippedH,
                        isFlippedV: isFlippedV
                    )
                    onComplete(finalImage) // Send back new image
                }
                .font(.headline.weight(.bold))
                .foregroundColor(.purple)
            }
            .padding()
            .background(Color.black.opacity(0.5))
            
            // 2. IMAGE PREVIEW
            Spacer()
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFit()
                // Apply live visual transforms
                .rotationEffect(straightenAngle + rotationAngle)
                .scaleEffect(x: isFlippedH ? -1 : 1, y: isFlippedV ? -1 : 1)
                .animation(.easeInOut(duration: 0.2), value: previewImage)
                .animation(.easeInOut(duration: 0.2), value: straightenAngle)
                .animation(.easeInOut(duration: 0.2), value: rotationAngle)
                .animation(.easeInOut(duration: 0.2), value: isFlippedH)
                .animation(.easeInOut(duration: 0.2), value: isFlippedV)
            Spacer()
            
            // 3. TOOL PANEL
            VStack {
                // Show slider if Straighten is active
                if isStraightenActive {
                    straightenSlider
                }
                
                // Show aspect ratios if Crop is active (TODO)
                
                // Main tool buttons
                bottomToolbar
            }
            .padding(.bottom)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
    }
    
    /// The bottom row of tool buttons
    var bottomToolbar: some View {
        HStack(spacing: 30) {
            // Rotate Button
            Button {
                rotationAngle -= .degrees(90)
            } label: {
                VStack {
                    Image(systemName: "rotate.left.fill")
                    Text("Rotate")
                }
            }
            
            // Flip Button
            Button {
                isFlippedH.toggle()
            } label: {
                VStack {
                    Image(systemName: "flip.horizontal.fill")
                    Text("Flip")
                }
            }
            
            // Straighten Button
            Button {
                withAnimation {
                    isStraightenActive.toggle()
                }
            } label: {
                VStack {
                    Image(systemName: "slider.horizontal.below.rectangle")
                    Text("Straighten")
                }
                .foregroundColor(isStraightenActive ? .purple : .white)
            }
            
            // Aspect Ratio Crop Button
            Menu {
                Button("Original") {
                    // Reset to the base image for this tool
                    previewImage = image
                }
                Button("1:1 Square") {
                    previewImage = service.centerCrop(image: previewImage, to: 1.0/1.0)
                }
                Button("16:9") {
                    previewImage = service.centerCrop(image: previewImage, to: 16.0/9.0)
                }
                Button("4:5") {
                    previewImage = service.centerCrop(image: previewImage, to: 4.0/5.0)
                }
            } label: {
                VStack {
                    Image(systemName: "aspectratio.fill")
                    Text("Crop")
                }
            }
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding()
    }
    
    /// The slider for the Straighten tool
    var straightenSlider: some View {
        HStack {
            Text("-45°")
            Slider(
                value: $straightenAngle.degrees,
                in: -45...45
            )
            .tint(.purple)
            Text("+45°")
            
            Button("Reset") {
                straightenAngle = .zero
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .font(.caption)
        .foregroundColor(.gray)
        .padding(.horizontal)
    }
}

// Helper extension to get/set degrees from an Angle
extension Angle {
    var degrees: Double {
        get { self.radians * 180 / .pi }
        set { self = .radians(newValue * .pi / 180) }
    }
}
