import UIKit
import Vision
import CoreImage

class RetouchService {
    
    private let context = CIContext()
    
    // --- 1. FACE DETECTION ---
    
    /// Finds the first face in an image and its landmarks
    func detectFace(on image: UIImage, completion: @escaping (VNFaceObservation?) -> Void) {
        // Use a background thread for Vision processing
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNDetectFaceLandmarksRequest { (request, error) in
                guard let results = request.results as? [VNFaceObservation],
                      let firstFace = results.first else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(firstFace)
                }
            }
            
            try? requestHandler.perform([request])
        }
    }
    
    // --- 2. MAIN APPLY FUNCTION ---
    
    /// Applies all retouch filters based on the detected face
    func applyRetouch(to image: UIImage,
                      observation: VNFaceObservation,
                      skinSmooth: Double,
                      eyeBrighten: Double,
                      teethWhiten: Double) -> UIImage {
        
        guard let ciImage = CIImage(image: image) else { return image }
        var outputImage = ciImage
        
        // Chain the filters
        outputImage = applySkinSmoothing(input: outputImage, observation: observation, amount: skinSmooth)
        outputImage = applyEyeBrightening(input: outputImage, observation: observation, amount: eyeBrighten)
        outputImage = applyTeethWhitening(input: outputImage, observation: observation, amount: teethWhiten)
        
        // Render the final UIImage
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        // --- THIS IS FIX 1 ---
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        // --- END OF FIX 1 ---
    }
    
    // --- 3. SUB-FILTERS ---
    
    /// Applies skin smoothing, avoiding eyes and mouth
    private func applySkinSmoothing(input: CIImage, observation: VNFaceObservation, amount: Double) -> CIImage {
        if amount == 0 { return input }
        
        // 1. Create a smoothed version of the whole image
        let smoothed = input.applyingFilter("CIBilateralFilter", parameters: [
            kCIInputRadiusKey: amount * 10,
            kCIInputIntensityKey: amount * 1.5
        ])
        
        // 2. Create a mask to *protect* eyes and mouth from smoothing
        let eyeMask = createMask(for: observation.landmarks?.leftEye, in: input.extent, feather: 0.1)
        let eyeMask2 = createMask(for: observation.landmarks?.rightEye, in: input.extent, feather: 0.1)
        let mouthMask = createMask(for: observation.landmarks?.innerLips, in: input.extent, feather: 0.1)

        // 3. Combine masks: (eyes + mouth)
        // --- FIX 2: Use CIBlendWithMask (A over B) ---
        let combinedMask = eyeMask.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: eyeMask2
        ]).applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: mouthMask
        ])

        // 4. Blend: Use the mask to blend the smoothed image over the original
        // The mask protects the features, so we blend the *original* (input) over the *smoothed*
        // --- FIX 3: Replaced 'composited(over:using:)' ---
        return input.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: smoothed,
            kCIInputMaskImageKey: combinedMask
        ])
        // --- END OF FIX 3 ---
    }
    
    /// Brightens and sharpens the eyes
    private func applyEyeBrightening(input: CIImage, observation: VNFaceObservation, amount: Double) -> CIImage {
        if amount == 0 { return input }

        // 1. Create a brightened/sharpened version
        let enhanced = input
            .applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: amount * 0.7])
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.0 + (amount * 0.3)])
            .applyingFilter("CIUnsharpMask", parameters: [kCIInputRadiusKey: 2.5, kCIInputIntensityKey: amount])
        
        // 2. Create a mask just for the eyes
        let eyeMask = createMask(for: observation.landmarks?.leftEye, in: input.extent, feather: 0.05)
        let eyeMask2 = createMask(for: observation.landmarks?.rightEye, in: input.extent, feather: 0.05)
        let combinedMask = eyeMask.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: eyeMask2
        ])
        
        // 3. Blend: Use the mask to blend the brightened version over the input
        // --- FIX 4: Replaced 'composited(over:using:)' ---
        return enhanced.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: input,
            kCIInputMaskImageKey: combinedMask
        ])
        // --- END OF FIX 4 ---
    }
    
    /// Brightens and desaturates the teeth (inner lips)
    private func applyTeethWhitening(input: CIImage, observation: VNFaceObservation, amount: Double) -> CIImage {
        if amount == 0 { return input }
        
        // 1. Create a whitened version
        let whitened = input
            .applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: amount * 0.5])
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.0 - (amount * 0.8)]) // Desaturate
        
        // 2. Create a mask for the inner lips
        let mouthMask = createMask(for: observation.landmarks?.innerLips, in: input.extent, feather: 0.05)
        
        // 3. Blend
        // --- FIX 5: Replaced 'composited(over:using:)' ---
        return whitened.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: input,
            kCIInputMaskImageKey: mouthMask
        ])
        // --- END OF FIX 5 ---
    }
    
    
    // --- 4. MASK HELPER ---
    
    /// Helper to create a CIImage mask from a set of landmark points
    private func createMask(for landmarks: VNFaceLandmarkRegion2D?, in extent: CGRect, feather: Double = 0.1) -> CIImage {
        guard let landmarks = landmarks, landmarks.pointCount > 0 else {
            return CIImage.empty().cropped(to: extent)
        }
        
        // Get all points, converted to image coordinates
        let points = landmarks.pointsInImage(imageSize: extent.size)
        
        // Find the bounding box of the points
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return CIImage.empty().cropped(to: extent)
        }
        
        let center = CIVector(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let width = (maxX - minX)
        let height = (maxY - minY)
        let radius = max(width, height) / 2 + (max(width, height) * CGFloat(feather))
        
        // Create a feathered circle (radial gradient)
        return CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": center,
            "inputRadius0": radius, // Inner radius (solid)
            "inputRadius1": radius + (radius * feather * 2), // Outer radius (fades to)
            "inputColor0": CIColor.white,
            "inputColor1": CIColor.clear
        ])!.outputImage!
         .cropped(to: extent)
    }
}
