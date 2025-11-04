import SwiftUI

struct ObjectRemovalPanel: View {
    
    // The base image for the tool
    let originalImage: UIImage
    
    // Binding to the main edited image
    @Binding var editedImage: UIImage
    
    // Binding to disable main editor gestures
    @Binding var isDrawing: Bool
    
    // AI Service
    private let service = GeminiAIService()
    
    // Drawing state
    @State private var drawnPaths: [CGPath] = []
    @State private var brushSize: CGFloat = 40.0
    
    // UI State
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // This is the view we show *over* the main image
    private var canvasView: some View {
        DrawingCanvasView(
            paths: $drawnPaths,
            brushSize: $brushSize,
            isDrawing: $isDrawing
        ) {
            // Undo action
            _ = drawnPaths.popLast()
        }
        .allowsHitTesting(!isLoading) // Disable drawing while loading
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView {
                    Text("AI is thinking...")
                        .foregroundColor(.gray)
                }
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            } else {
                toolOptions // Show sliders and buttons
            }
        }
        .padding(.vertical)
        .overlay(
            // This is a "hack" to show our drawing canvas
            // *on top of* the main image preview.
            // We read the main editor's frame and place our canvas there.
            GeometryReader { proxy in
                Color.clear
                    .overlay(canvasView, alignment: .top)
            }
        )
        .onDisappear {
            // When the panel is closed, re-enable main gestures
            isDrawing = false
        }
    }
    
    /// Sliders and buttons
    private var toolOptions: some View {
        HStack(spacing: 20) {
            // Undo Button
            Button {
                _ = drawnPaths.popLast()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(drawnPaths.isEmpty)
            
            // Brush Size Slider
            VStack(alignment: .leading, spacing: 2) {
                Text("Brush Size")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Slider(value: $brushSize, in: 10...100)
                    .tint(.purple)
            }
            
            // "Remove" Button
            Button("Remove") {
                Task {
                    await performAIRemoval()
                }
            }
            .font(.headline)
            .foregroundColor(.purple)
            .disabled(drawnPaths.isEmpty)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Logic
    
    /// Generates the black-and-white mask image
    private func createMaskImage() -> UIImage? {
        let size = originalImage.size
        
        // Start a graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Fill background black
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw paths in white
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // We must scale the paths from the view's size to the image's size
        let viewSize = UIScreen.main.bounds.size
        let aspect = originalImage.size.width / originalImage.size.height
        let viewAspect = viewSize.width / (viewSize.height * 0.7) // Approx.
        
        // This scaling is complex and depends on the Image's .scaledToFit()
        // This is a simplified example. A production app needs robust coordinate conversion.
        let scaleX = size.width / viewSize.width
        let scaleY = size.height / (viewSize.width / aspect) // TODO: Fix this scaling
        let scale = max(scaleX, scaleY) * 1.2 // HACK: Fudge factor
        
        print("Warning: Mask scaling is for demo only.")
        
        for path in drawnPaths {
            context.setLineWidth(brushSize * scale)
            
            // A simple (but imperfect) transform
            var transform = CGAffineTransform.identity
                .scaledBy(x: scale, y: scale)
            
            if let transformedPath = path.copy(using: &transform) {
                context.addPath(transformedPath)
                context.strokePath()
            }
        }
        
        // Get the final mask
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return maskImage
    }
    
    /// Calls the AI service
    private func performAIRemoval() async {
        isLoading = true
        errorMessage = nil
        
        guard let maskImage = createMaskImage() else {
            errorMessage = "Failed to create mask"
            isLoading = false
            return
        }
        
        let result = await service.removeObject(
            from: originalImage,
            withMask: maskImage,
            prompt: "Remove the object highlighted in the mask and fill the area realistically."
        )
        
        isLoading = false
        switch result {
        case .success(let newImage):
            // Success! Update the main image
            editedImage = newImage
            drawnPaths = [] // Clear the mask
        case .failure(let error):
            errorMessage = error.localizedDescription
            print("AI Error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var image = UIImage(systemName: "photo")!
        @State var isDrawing = false
        var body: some View {
            ObjectRemovalPanel(originalImage: image, editedImage: $image, isDrawing: $isDrawing)
                .preferredColorScheme(.dark)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
    return PreviewWrapper()
}
