import UIKit
import CoreImage
import Combine // <-- FIX 1: Add this import

// A simple struct to define our filters
struct Filter: Identifiable {
    let id = UUID()
    let name: String
    let ciFilterName: String // The "official" Core Image filter name
}

// --- FIX 2: Add : ObservableObject ---
class FilterService: ObservableObject {
    
    // The shared context for processing (it's expensive to create)
    private let context = CIContext()
    
    // The list of filters you specified
    let allFilters: [Filter] = [
        Filter(name: "Original", ciFilterName: ""), // Special case for no filter
        Filter(name: "Classic", ciFilterName: "CIPhotoEffectProcess"),
        Filter(name: "Vivid", ciFilterName: "CIPhotoEffectInstant"),
        Filter(name: "Portrait", ciFilterName: "CIPhotoEffectTonal"),
        Filter(name: "B&W", ciFilterName: "CIPhotoEffectNoir"),
        Filter(name: "Film", ciFilterName: "CIPhotoEffectFade"),
        Filter(name: "Warm", ciFilterName: "CISepiaTone"),
        Filter(name: "Cool", ciFilterName: "CIColorControls"), // We'll tweak this one
        Filter(name: "Cinematic", ciFilterName: "CIColorMatrix"), // We'll tweak this
        Filter(name: "Pastel", ciFilterName: "CIColorPosterize"),
        Filter(name: "Bold", ciFilterName: "CIUnsharpMask"),
        Filter(name: "Matte", ciFilterName: "CIGammaAdjust"),
        Filter(name: "Retro", ciFilterName: "CIVignette"),
        Filter(name: "Sepia", ciFilterName: "CISepiaTone"),
        Filter(name: "HDR Pop", ciFilterName: "CIHighlightShadowAdjust"),
        Filter(name: "Mono Blue", ciFilterName: "CIColorMonochrome"),
        Filter(name: "Sunset", ciFilterName: "CIColorMap"), // Needs gradient
        Filter(name: "Urban", ciFilterName: "CIPhotoEffectTransfer"),
        Filter(name: "Dreamy", ciFilterName: "CIGaussianBlur"),
        // ... add all 20+ as needed
    ]
    
    /// Applies a filter to a UIImage
    func applyFilter(to image: UIImage, filterName: String, intensity: Double) -> UIImage {
        if filterName.isEmpty || filterName == "Original" {
            return image // Return the original if "Original" is selected
        }
        
        // 1. Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else { return image }
        
        // 2. Create the filter
        guard let filter = CIFilter(name: filterName) else {
            print("Failed to create filter: \(filterName)")
            return image
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        // 3. Set filter-specific parameters and intensity
        // This is where the filter logic gets custom
        if filter.inputKeys.contains(kCIInputIntensityKey) {
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
        } else if filterName == "CISepiaTone" {
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
        } else if filterName == "CIGaussianBlur" {
            filter.setValue(intensity * 10, forKey: kCIInputRadiusKey) // Blur needs more strength
        } else if filterName == "CIColorControls" { // "Cool" filter
            filter.setValue(1.0, forKey: kCIInputSaturationKey)
            filter.setValue(0.0, forKey: kCIInputBrightnessKey)
            filter.setValue(1.1 + (intensity * 0.5), forKey: kCIInputContrastKey) // Make it pop
        }
        // ... add more custom logic for other filters ...
        
        
        // 4. Get the output image
        guard let outputImage = filter.outputImage else { return image }
        
        // 5. Render the final UIImage
        // We use 'createCGImage' for performance
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return image
    }
    
    /// Creates a small thumbnail for a filter preview
    func generateThumbnail(for filter: Filter, from image: UIImage) -> UIImage {
        // Create a small, low-res version of the image for fast processing
        guard let thumbnail = image.preparingThumbnail(of: CGSize(width: 100, height: 100)) else {
            return UIImage(systemName: "photo")!
        }
        // Apply the filter at full intensity for the preview
        return applyFilter(to: thumbnail, filterName: filter.ciFilterName, intensity: 1.0)
    }
}
