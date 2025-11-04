import SwiftUI

struct OverlaysCanvasView: View {
    @Binding var items: [OverlayItem]
    @Binding var selectedItemID: UUID?
    
    // Info from main view to map coordinates
    let imageSize: CGSize
    let viewProxy: GeometryProxy

    var body: some View {
        // We use another GeometryReader to get the *canvas's* frame
        GeometryReader { canvasProxy in
            ForEach($items) { $item in
                // We pass the geometry info down
                InteractiveOverlayItemView(
                    item: $item,
                    isSelected: selectedItemID == item.id,
                    imageSize: imageSize,
_viewSize: viewProxy.size // The size of the scaledToFit image
                )
                .onTapGesture {
                    selectedItemID = item.id
                }
            }
        }
    }
}

/// This helper view holds a single item and all its gestures
struct InteractiveOverlayItemView: View {
    
    @Binding var item: OverlayItem
    var isSelected: Bool
    
    // Geometry
    let imageSize: CGSize
    let _viewSize: CGSize
    
    // Gestures
    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    
    var body: some View {
        Text(item.text)
            .font(.custom(item.fontName, size: item.fontSize))
            .foregroundColor(item.color)
            .padding(10) // Add padding for easier tapping
            .background(Color.black.opacity(0.001)) // Make sure it's tappable
            .overlay(
                // Show selection border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
            // --- Apply Transforms ---
            .scaleEffect(item.scale * currentScale)
            .rotationEffect(item.rotation + currentRotation)
            .position(item.position) // Use absolute position
            .offset(dragOffset) // Use drag offset for live dragging
            
            // --- Gestures ---
            .gesture(
                // 1. Drag Gesture
                DragGesture()
                    .onChanged { value in
                        self.dragOffset = value.translation
                    }
                    .onEnded { value in
                        // Commit the drag to the item's permanent position
                        item.position = CGPoint(
                            x: item.position.x + value.translation.width,
                            y: item.position.y + value.translation.height
                        )
                        // Reset live offset
                        self.dragOffset = .zero
                    }
            )
            .simultaneousGesture(
                // 2. Scale Gesture
                MagnificationGesture()
                    .onChanged { value in
                        self.currentScale = value
                    }
                    .onEnded { value in
                        // Commit the scale
                        item.scale *= value
                        // Reset live scale
                        self.currentScale = 1.0
                    }
            )
            .simultaneousGesture(
                // 3. Rotation Gesture
                RotationGesture()
                    .onChanged { value in
                        self.currentRotation = value
                    }
                    .onEnded { value in
                        // Commit the rotation
                        item.rotation += value
                        // Reset live rotation
                        self.currentRotation = .zero
                    }
            )
    }
}
