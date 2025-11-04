import SwiftUI

// Enum to manage which tool is currently active
enum EditorTool: String, CaseIterable {
    case filters = "Filters"
    case adjustments = "Adjustments"
    case retouch = "Retouch"
    case objects = "Objects"
    case text = "Text"
    case crop = "Crop"
    
    var iconName: String {
        switch self {
        case .filters: return "camera.filters"
        case .adjustments: return "slider.horizontal.3"
        case .retouch: return "face.smiling"
        case .objects: return "wand.and.rays"
        case .text: return "textformat"
        case .crop: return "crop.rotate"
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
                        // If we are CLOSING the text tool, render the overlays
                        if oldTool == .text && newTool != .text && !overlayItems.isEmpty {
                            let imageToRenderOn = editedImage
                            let itemsToRender = overlayItems
                            
                            // Clear items immediately for UI responsiveness
                            self.overlayItems.removeAll()
                            self.selectedItemID = nil
                            
                            Task {
                                let finalImage = await renderService.render(
                                    overlays: itemsToRender,
                                    onto: imageToRenderOn
                                )
                                await MainActor.run {
                                    // Set the newly rendered image
                                    self.editedImage = finalImage
                                }
                            }
                        }
                        // --- END RENDER LOGIC ---

                        // Set the base image for the new tool (if it's not the text tool)
                        if newTool != nil && newTool != .text {
                            imageBaseForTool = editedImage
                        }
                        
                        // If the crop tool is selected, present the full-screen cover
                        if newTool == .crop {
                            isShowingCropView = true
                            // Deselect the tool so the bottom panel closes
                            selectedTool = nil
                        }
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
        }
        .navigationBarHidden(true) // We use our custom toolbar
        .preferredColorScheme(.dark)
        // This modifier presents the Crop/Rotate tool
        .fullScreenCover(isPresented: $isShowingCropView) {
            // --- THIS IS THE CHANGE: Using our native view ---
            NativeTransformView(image: imageBaseForTool) { croppedImage in
                // This is the callback when cropping is done
                if let croppedImage = croppedImage {
                    self.editedImage = croppedImage
                }
                isShowingCropView = false
            }
        }
        // This modifier presents the Export tool
        .sheet(isPresented: $isShowingExportView) {
            ExportView(imageToExport: editedImage) {
                // This is the callback after exporting is done
                isShowingExportView = false
            }
        }
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
            
            // "Compare" Button (Hold to see original)
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
                // Ensure no tool is active (which renders text)
                if selectedTool == .text {
                    selectedTool = nil
                }
                // Show the export screen
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
            // This ZStack layers the image and the overlays
            ZStack {
                // --- The Image ---
                Image(uiImage: isComparing ? originalImage : editedImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .if(!isDrawing && selectedTool != .text) { view in // Disable pan/zoom for draw AND text
                        view.gesture(
                            // Combined gesture for pan and zoom
                            SimultaneousGesture(
                                // Zoom gesture
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 5.0) // Limit zoom
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                
                                // Pan gesture
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
                // This is visible only when the text tool is active
                if selectedTool == .text {
                    OverlaysCanvasView(
                        items: $overlayItems,
                        selectedItemID: $selectedItemID,
                        imageSize: editedImage.size,
                        viewProxy: proxy // Pass the proxy for coordinate mapping
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .clipped() // Don't let image go outside its bounds
    }
    
    /// 3. The Panel that shows the correct tool options
    @ViewBuilder
    var subToolPanel: some View {
        VStack {
            // Header for the panel (e.g., "Filters", "Adjustments")
            HStack {
                Text(selectedTool?.rawValue ?? "Tool")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                // "Close" button for the panel
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
                    isDrawing: $isDrawing // Pass the binding
                )
                
            case .text:
                TextStickersPanel(
                    items: $overlayItems,
                    selectedItemID: $selectedItemID
                )
                
            case .crop:
                EmptyView() // Handled by fullScreenCover
                
            case .none:
                EmptyView()
            }
            
            Spacer()
        }
        .frame(height: 250) // Give the panel a fixed height
        .transition(.move(edge: .bottom)) // Animate in from bottom
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
