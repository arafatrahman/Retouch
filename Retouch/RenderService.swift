import UIKit
import SwiftUI

class RenderService {
    
    /// Renders an array of overlay items onto a base image
    func render(overlays: [OverlayItem], onto image: UIImage) async -> UIImage {
        
        let size = image.size
        // Create a new image renderer
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let newImage = renderer.image { context in
            // 1. Draw the base image
            image.draw(at: .zero)
            
            let cgContext = context.cgContext
            
            // 2. Loop and draw each overlay
            for item in overlays {
                // Create the text attributes
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: item.fontName, size: item.fontSize) ?? .systemFont(ofSize: item.fontSize),
                    .foregroundColor: UIColor(item.color)
                ]
                let attributedString = NSAttributedString(string: item.text, attributes: attributes)
                
                // --- Apply Transforms ---
                // We must apply transforms in the correct order:
                // 1. Move to the item's position
                // 2. Rotate around that point
                // 3. Scale from that point
                
                // Save the clean context state
                cgContext.saveGState()
                
                // 1. Translate to the position
                // Note: Image context is (0,0) top-left, SwiftUI is (0,0) top-left.
                // The item.position is already in the correct coordinate space
                // from the GeometryReader in our canvas.
                cgContext.translateBy(x: item.position.x, y: item.position.y)
                
                // 2. Rotate
                cgContext.rotate(by: item.rotation.radians)
                
                // 3. Scale
                cgContext.scaleBy(x: item.scale, y: item.scale)
                
                // Draw the text *at the origin (0,0)*, since we've already
                // moved the entire coordinate system.
                // We offset by half the size to rotate/scale from the center.
                let textSize = attributedString.size()
                let drawPoint = CGPoint(x: -textSize.width / 2, y: -textSize.height / 2)
                
                attributedString.draw(at: drawPoint)
                
                // Restore the context to its original state for the next item
                cgContext.restoreGState()
            }
        }
        
        return newImage
    }
}
