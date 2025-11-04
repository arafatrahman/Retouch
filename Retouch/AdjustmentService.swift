import UIKit
import CoreImage

// Defines each adjustment type
enum AdjustmentType: String, CaseIterable, Identifiable {
    case exposure = "Exposure"
    case contrast = "Contrast"
    case highlights = "Highlights"
    case shadows = "Shadows"
    case saturation = "Saturation"
    case vibrance = "Vibrance"
    case temperature = "Warmth"
    case tint = "Tint"
    case sharpen = "Sharpen"
    case vignette = "Vignette"

    var id: String { self.rawValue }

    // Define the range for each slider
    var range: ClosedRange<Double> {
        switch self {
        case .exposure: return -1.0...1.0
        case .contrast: return 0.5...1.5
        case .highlights: return 0.0...1.0 // 1.0 is default (no change)
        case .shadows: return -1.0...1.0
        case .saturation: return 0.0...2.0
        case .vibrance: return -1.0...1.0
        case .temperature: return -1.0...1.0 // Mapped to 2000K-8000K
        case .tint: return -1.0...1.0 // Mapped to -150 to +150
        case .sharpen: return 0.0...10.0
        case .vignette: return 0.0...2.0
        }
    }
    
    // Define the default value (no change)
    var defaultValue: Double {
        switch self {
        case .contrast, .saturation: return 1.0
        case .highlights: return 1.0
        default: return 0.0
        }
    }
}

// A simple struct to hold all adjustment values
struct AdjustmentValues {
    var exposure: Double = AdjustmentType.exposure.defaultValue
    var contrast: Double = AdjustmentType.contrast.defaultValue
    var highlights: Double = AdjustmentType.highlights.defaultValue
    var shadows: Double = AdjustmentType.shadows.defaultValue
    var saturation: Double = AdjustmentType.saturation.defaultValue
    var vibrance: Double = AdjustmentType.vibrance.defaultValue
    var temperature: Double = AdjustmentType.temperature.defaultValue
    var tint: Double = AdjustmentType.tint.defaultValue
    var sharpen: Double = AdjustmentType.sharpen.defaultValue
    var vignette: Double = AdjustmentType.vignette.defaultValue
}


class AdjustmentService {
    
    private let context = CIContext()
    
    /// Applies a whole chain of adjustments to a single image
    func applyAdjustments(to image: UIImage, values: AdjustmentValues) -> UIImage {
        
        guard let ciImage = CIImage(image: image) else { return image }
        var currentImage = ciImage
        
        // --- 1. Color Controls (Saturation, Contrast, Brightness) ---
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            filter.setValue(values.saturation, forKey: kCIInputSaturationKey)
            filter.setValue(values.contrast, forKey: kCIInputContrastKey)
            if let output = filter.outputImage {
                currentImage = output
            }
        }
        
        // --- 2. Exposure ---
        if let filter = CIFilter(name: "CIExposureAdjust") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            filter.setValue(values.exposure, forKey: kCIInputEVKey)
            if let output = filter.outputImage {
                currentImage = output
            }
        }
        
        // --- 3. Highlights & Shadows ---
        if let filter = CIFilter(name: "CIHighlightShadowAdjust") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            filter.setValue(values.highlights, forKey: "inputHighlightAmount")
            filter.setValue(values.shadows, forKey: "inputShadowAmount")
            if let output = filter.outputImage {
                currentImage = output
            }
        }
        
        // --- 4. Vibrance ---
        if let filter = CIFilter(name: "CIVibrance") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            filter.setValue(values.vibrance, forKey: "inputAmount")
            if let output = filter.outputImage {
                currentImage = output
            }
        }
        
        // --- 5. Temperature & Tint ---
        if let filter = CIFilter(name: "CITemperatureAndTint") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            let neutral = CIVector(x: 6500, y: 0)
            let tempVector = CIVector(x: 6500 + (values.temperature * 1500), y: values.tint * 150)
            filter.setValue(neutral, forKey: "inputNeutral")
            filter.setValue(tempVector, forKey: "inputTargetNeutral")
            if let output = filter.outputImage {
                currentImage = output
            }
        }
        
        // --- 6. Sharpen ---
        if let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            filter.setValue(values.sharpen, forKey: kCIInputSharpnessKey)
            if let output = filter.outputImage {
                currentImage = output
            }
        }
        
        // --- 7. Vignette ---
        if let filter = CIFilter(name: "CIVignette") {
            filter.setValue(currentImage, forKey: kCIInputImageKey)
            filter.setValue(values.vignette, forKey: kCIInputIntensityKey)
            filter.setValue(values.vignette * 15, forKey: kCIInputRadiusKey)
            if let output = filter.outputImage {
                currentImage = output
            }
        }

        // --- Render the final image ---
        guard let outputCGImage = context.createCGImage(currentImage, from: currentImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
// <-- Make sure there is NO other code or class definition after this line -->
