import UIKit
import CoreGraphics
import SwiftUI // <-- FIX: Add this import to get the 'Angle' type

class TransformService {
    
    /// Renders a new image by applying rotation, straightening, and flipping
    func applyTransforms(to image: UIImage,
                         straightenAngle: Angle,
                         rotationAngle: Angle,
                         isFlippedH: Bool,
                         isFlippedV: Bool) -> UIImage {
        
        guard let cgImage = image.cgImage else { return image }
        
        // --- 1. Calculate new canvas size ---
        // We need to create a new canvas that is large enough
        // to hold the image after it's been rotated
        let imageRect = CGRect(origin: .zero, size: image.size)
        
        // Apply straightening
        var transform = CGAffineTransform.identity
            .translatedBy(x: imageRect.midX, y: imageRect.midY)
            .rotated(by: straightenAngle.radians)
            .translatedBy(x: -imageRect.midX, y: -imageRect.midY)
        
        // Calculate the bounding box of the straightened image
        let newRect = imageRect.applying(transform)
        
        // --- 2. Create a new graphics context ---
        // Size it to fit the new bounding box
        let renderer = UIGraphicsImageRenderer(size: newRect.size)
        
        let newImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // --- 3. Apply Transforms to the Context ---
            
            // Move the origin to the center of the new canvas
            // so all rotations/flips happen from the center
            cgContext.translateBy(x: newRect.width / 2, y: newRect.height / 2)
            
            // Apply 90-degree step rotation
            cgContext.rotate(by: rotationAngle.radians)
            
            // Apply flip
            cgContext.scaleBy(x: isFlippedH ? -1 : 1, y: isFlippedV ? -1 : 1)
            
            // Apply straightening
            cgContext.rotate(by: straightenAngle.radians)
            
            // --- 4. Draw the original image ---
            // We must draw it centered *on the old origin*
            // before we moved the context
            let drawRect = CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            )
            
            // The CGImage is drawn upside down, so we flip the context
            // just for the draw call.
            cgContext.scaleBy(x: 1, y: -1)
            cgContext.draw(cgImage, in: CGRect(x: drawRect.minX, y: -drawRect.maxY, width: drawRect.width, height: drawRect.height))
        }
        
        // --- 5. Crop to Aspect Ratio (if needed) ---
        // This is a separate step
        // (We will add this next, for now just return the transformed)
        return newImage
    }
    
    /// A simpler version that just crops to an aspect ratio
    func centerCrop(image: UIImage, to aspectRatio: CGFloat) -> UIImage {
        let size = image.size
        
        var newWidth, newHeight: CGFloat
        
        if size.width / size.height > aspectRatio {
            // Image is wider than a_r
            newHeight = size.height
            newWidth = newHeight * aspectRatio
        } else {
            // Image is taller than a_r
            newWidth = size.width
            newHeight = newWidth / aspectRatio
        }
        
        let x = (size.width - newWidth) / 2.0
        let y = (size.height - newHeight) / 2.0
        
        let cropRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        
        guard let croppedCGImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
