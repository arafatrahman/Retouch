import SwiftUI

// Defines a single item (text, sticker, etc.)
struct OverlayItem: Identifiable, Equatable {
    let id = UUID()
    var text: String = "Hello"
    var fontName: String = "Helvetica-Bold"
    var fontSize: CGFloat = 50.0
    var color: Color = .white
    
    // Gesture properties
    var position: CGPoint = .zero // Stored as absolute position
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    
    // State for gestures
    var lastPosition: CGPoint = .zero
    var lastScale: CGFloat = 1.0
    var lastRotation: Angle = .zero
}
