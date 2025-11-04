import SwiftUI

// --- 1. ADD 'removeBG' TO THE ENUM ---
enum EditorTool: String, CaseIterable {
    case filters = "Filters"
    case adjustments = "Adjustments"
    case retouch = "Retouch"
    case objects = "Objects"
    case text = "Text"
    case crop = "Crop"
    case removeBG = "Remove BG" // <-- NEW
    
    var iconName: String {
        switch self {
        case .filters: return "camera.filters"
        case .adjustments: return "slider.horizontal.3"
        case .retouch: return "face.smiling"
        case .objects: return "wand.and.rays"
        case .text: return "textformat"
        case .crop: return "crop.rotate"
        case .removeBG: return "scissors" // <-- NEW
        }
    }
}

struct EditorMainView: View {
    // The image passed from the gallery
    let originalImage: UIImage
    
    // State for the *final* edited image
    @State private var editedImage: UIImage
    
    // State for the image *before* the current tool was opened
    @State private var imageBaseForTool: UIImage
    
    // State for which tool is selected
    @State private var selectedTool: EditorTool? = nil
    
    // State for zoom and pan
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // State to disable pan/zoom when drawing
    @State private var isDrawing = false
    
    // State to show the full-screen crop tool
    @State private var isShowingCropView = false
    
    // State to show the export sheet
    @State private var isShowingExportView = false
    
    // --- State for Text/Overlays (from Section 9) ---
    @State private var overlayItems: [OverlayItem] = []
    @State private var selectedItemID: UUID? = nil
    private let renderService = RenderService()
    
    // State for "Compare" button
    @State private var isComparing = false
    
    // --- 2. ADD AI LOADING STATE & SERVICE ---
    @State private var isProcessingAI = false // <-- NEW
    private let aiService = GeminiAIService() // <-- NEW (This line will no longer error)
    
    @Environment(\.presentationMode) var presentationMode

    // Initialize state with the passed-in image
    init(image: UIImage) {
        self.originalImage = image
        self._editedImage = State(initialValue: image)
        self._imageBaseForTool = State(initialValue: image) // Init new state
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. TOP TOOLBAR
                topToolbar
                    .onChange(of: selectedTool) { [oldTool = selectedTool] newTool in // Capture old value
                        
                        // --- RENDER LOGIC for Text Tool ---
                        if oldTool == .text && newTool != .text && !overlayItems.isEmpty {
                            let imageToRenderOn = editedImage
                            let itemsToRender = overlayItems
                            
                            self.overlayItems.removeAll()
                            self.selectedItemID = nil
                            
                            Task {
                                let finalImage = await renderService.render(
                                    overlays: itemsToRender,
                                    onto: imageToRenderOn
                                )
                                await MainActor.run {
                                    self.editedImage = finalImage
                                }
                            }
                        }
                        // --- END RENDER LOGIC ---

                        // Set the base image for the new tool
                        if newTool != nil && newTool != .text && newTool != .removeBG {
                            imageBaseForTool = editedImage
                        }
                        
                        // If the crop tool is selected
                        if newTool == .crop {
                            isShowingCropView = true
                            selectedTool = nil
                        }
                        
                        // --- 3. HANDLE NEW 'REMOVE BG' TOOL ---
                        if newTool == .removeBG {
                            isProcessingAI = true // Show global spinner
                            let imageToProcess = editedImage
                            
                            Task {
                                let result = await aiService.removeBackground(image: imageToProcess)
                                await MainActor.run {
                                    switch result {
                                    case .success(let newImage):
                                        self.editedImage = newImage
                                    case .failure(let error):
                                        print("Error removing background: \(error)")
                                    }
                                    self.isProcessingAI = false
                                    self.selectedTool = nil // It's a one-shot tool
                                }
                            }
                        }
                        // --- END OF NEW LOGIC ---
                    }
                
                // 2. MAIN IMAGE PREVIEW
                imagePreview
                
                // 3. BOTTOM TOOLBAR (Main tools)
                EditorBottomToolbar(selectedTool: $selectedTool)
                    .background(Color(UIColor.secondarySystemBackground))
                
                // 4. SUB-TOOL PANEL (Shows when a tool is selected)
                if selectedTool != nil {
                    subToolPanel
                        .background(Color(UIColor.secondarySystemBackground))
                }
            }
            
            // --- 4. ADD AI LOADING SPINNER OVERLAY ---
            if isProcessingAI {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("AI is thinking...")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.6))
                .ignoresSafeArea()
            }
            // --- END OF OVERLAY ---
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        // This modifier presents the Crop/Rotate tool
        .fullScreenCover(isPresented: $isShowingCropView) {
            NativeTransformView(image: imageBaseForTool) { croppedImage in
                if let croppedImage = croppedImage {
                    self.editedImage = croppedImage
                }
                isShowingCropView = false
            }
        }
        // This modifier presents the Export tool
        .sheet(isPresented: $isShowingExportView) {
            ExportView(imageToExport: editedImage) {
                isShowingExportView = false
            }
        }
        .disabled(isProcessingAI) // <-- 5. Disable all controls while AI is working
    }
    
    // MARK: - View Components

    /// 1. The Top Toolbar (Cancel, Compare, Done)
    var topToolbar: some View {
        HStack {
            // "Cancel" Button
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            // "Compare" Button
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title2)
                .foregroundColor(.white)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isComparing = true }
                        .onEnded { _ in isComparing = false }
                )
            
            Spacer()
            
            // "Done" (Export) Button
            Button("Done") {
                if selectedTool == .text {
                    selectedTool = nil
                }
                isShowingExportView = true
            }
            .font(.headline.weight(.bold))
            .foregroundColor(.purple)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
    
    /// 2. The Zoomable/Pannable Image Preview
    var imagePreview: some View {
        GeometryReader { proxy in
            ZStack {
                // --- The Image ---
                Image(uiImage: isComparing ? originalImage : editedImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .if(!isDrawing && selectedTool != .text) { view in
                        view.gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: value.translation.width + lastOffset.width,
                                            height: value.translation.height + lastOffset.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastOffset = offset
                                    }
                            )
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                
                // --- The Overlay Canvas ---
                if selectedTool == .text {
                    OverlaysCanvasView(
                        items: $overlayItems,
                        selectedItemID: $selectedItemID,
                        imageSize: editedImage.size,
                        viewProxy: proxy
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .clipped()
    }
    
    /// 3. The Panel that shows the correct tool options
    @ViewBuilder
    var subToolPanel: some View {
        VStack {
            // Header for the panel
            HStack {
                Text(selectedTool?.rawValue ?? "Tool")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                // "Close" button
                Button {
                    withAnimation {
                        selectedTool = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.trailing)
            }
            .padding(.top)

            // Show the correct view for the selected tool
            switch selectedTool {
            case .filters:
                FiltersPanel(
                    originalImage: imageBaseForTool,
                    editedImage: $editedImage
                )
            case .adjustments:
                AdjustmentsPanel(
                    originalImage: imageBaseForTool,
                    editedImage: $editedImage
                )
            case .retouch:
                RetouchPanel(
                    originalImage: imageBaseForTool,
                    editedImage: $editedImage
                )
            case .objects:
                ObjectRemovalPanel(
                    originalImage: imageBaseForTool,
                    editedImage: $editedImage,
                    isDrawing: $isDrawing
                )
            case .text:
                TextStickersPanel(
                    items: $overlayItems,
                    selectedItemID: $selectedItemID
                )
            case .crop:
                EmptyView() // Handled by fullScreenCover
            case .removeBG:
                EmptyView() // Handled by onChange modifier
            case .none:
                EmptyView()
            }
            
            Spacer()
        }
        .frame(height: 250)
        .transition(.move(edge: .bottom))
    }
}

// Helper view extension for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


#Preview {
    EditorMainView(image: UIImage(systemName: "photo")!)
}
