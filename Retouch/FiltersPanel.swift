import SwiftUI

struct FiltersPanel: View {
    // The original image (to generate thumbnails)
    let originalImage: UIImage
    
    // Binding to the main image being edited
    @Binding var editedImage: UIImage
    
    // Filter engine
    @StateObject private var filterService = FilterService()
    
    // State for this panel
    @State private var selectedFilter: Filter? {
        didSet {
            // When the filter changes, reset intensity and apply
            intensity = 1.0
            applyFilterChange()
        }
    }
    @State private var intensity: Double = 1.0
    
    // A temporary image to show while dragging the slider
    @State private var previewImage: UIImage?

    var body: some View {
        VStack(spacing: 15) {
            // 1. The Filter List
            filterScrollView
            
            // 2. The Intensity Slider
            if selectedFilter != nil && selectedFilter?.name != "Original" {
                HStack {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Slider(
                        value: $intensity,
                        in: 0.0...1.0,
                        onEditingChanged: { isEditing in
                            // When the user finishes dragging, apply the change
                            if !isEditing {
                                applyFilterChange()
                            }
                        }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .onAppear {
            // When the panel opens, select "Original" by default
            if selectedFilter == nil {
                selectedFilter = filterService.allFilters.first
            }
        }
        // This makes the slider feel responsive
        .onChange(of: intensity) { _ in
            // As the slider moves, apply the filter *asynchronously*
            // so the UI doesn't lag
            Task {
                previewImage = filterService.applyFilter(
                    to: originalImage,
                    filterName: selectedFilter?.ciFilterName ?? "",
                    intensity: intensity
                )
                // Once the preview is ready, update the main image
                if let previewImage {
                    self.editedImage = previewImage
                }
            }
        }
    }
    
    /// 1. The scrollable list of filter thumbnails
    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(filterService.allFilters) { filter in
                    VStack {
                        Text(filter.name)
                            .font(.caption)
                            .foregroundColor(selectedFilter?.id == filter.id ? .purple : .white)
                        
                        // Generate a thumbnail by applying the filter
                        Image(uiImage: filterService.generateThumbnail(for: filter, from: originalImage))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            // Add a selection border
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedFilter?.id == filter.id ? Color.purple : Color.clear, lineWidth: 3)
                            )
                    }
                    .onTapGesture {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Applies the selected filter and intensity to the main image
    private func applyFilterChange() {
        guard let selectedFilter else { return }
        
        // Run this on a background thread
        Task {
            let finalImage = filterService.applyFilter(
                to: originalImage,
                filterName: selectedFilter.ciFilterName,
                intensity: intensity
            )
            
            // Update the main UI on the main thread
            await MainActor.run {
                self.editedImage = finalImage
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var image = UIImage(systemName: "photo")!
        var body: some View {
            FiltersPanel(originalImage: UIImage(systemName: "photo")!, editedImage: $image)
                .preferredColorScheme(.dark)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
    return PreviewWrapper()
}
