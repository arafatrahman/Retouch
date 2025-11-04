import SwiftUI

struct TextStickersPanel: View {
    
    @Binding var items: [OverlayItem]
    @Binding var selectedItemID: UUID?
    
    // Get a binding to the *currently selected* item
    private var selectedItemBinding: Binding<OverlayItem>? {
        guard let id = selectedItemID,
              let index = items.firstIndex(where: { $0.id == id })
        else {
            return nil
        }
        // Return a binding to that specific item in the array
        return $items[index]
    }

    var body: some View {
        VStack {
            // Contextual controls (shows if an item is selected)
            if let itemBinding = selectedItemBinding {
                VStack {
                    // Font color
                    ColorPicker("Color", selection: itemBinding.color, supportsOpacity: false)
                        .padding(.horizontal)
                        .font(.caption)
                    
                    // TODO: Add Font Picker
                }
                .padding(.bottom, 10)
                
                Divider()
            }
            
            // Main tool buttons
            HStack(spacing: 30) {
                Button {
                    // Add a new default text item
                    let newItem = OverlayItem(
                        position: CGPoint(x: UIScreen.main.bounds.width / 2, y: 200) // Default position
                    )
                    items.append(newItem)
                    selectedItemID = newItem.id // Select it
                } label: {
                    VStack {
                        Image(systemName: "textformat.abc")
                        Text("Add Text")
                    }
                }
                
                // Placeholder buttons
                Button {
                    // TODO: Add sticker logic
                } label: {
                    VStack {
                        Image(systemName: "face.smiling")
                        Text("Stickers")
                    }
                }
                
                Button {
                    // TODO: Add overlay logic
                } label: {
                    VStack {
                        Image(systemName: "photo.stack")
                        Text("Overlays")
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.white)
        }
    }
}
