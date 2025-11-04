import SwiftUI

struct EditorBottomToolbar: View {
    // This binding connects to the @State in EditorMainView
    @Binding var selectedTool: EditorTool?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditorTool.allCases, id: \.self) { tool in
                    Button {
                        withAnimation {
                            // Set the selected tool, or unset if tapped again
                            selectedTool = (selectedTool == tool) ? nil : tool
                        }
                    } label: {
                        VStack {
                            Image(systemName: tool.iconName)
                                .font(.title2)
                            Text(tool.rawValue)
                                .font(.caption)
                        }
                        // Highlight the selected tool
                        .foregroundColor(selectedTool == tool ? .purple : .white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    // A preview requires a dummy @State
    struct PreviewWrapper: View {
        @State var tool: EditorTool? = .filters
        var body: some View {
            EditorBottomToolbar(selectedTool: $tool)
                .preferredColorScheme(.dark)
                .background(Color(UIColor.secondarySystemBackground))
        }
    }
    return PreviewWrapper()
}
