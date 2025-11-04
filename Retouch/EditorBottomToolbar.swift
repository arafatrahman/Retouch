import SwiftUI

struct EditorBottomToolbar: View {
    @Binding var selectedTool: EditorTool?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditorTool.allCases, id: \.self) { tool in
                    Button {
                        withAnimation {
                            selectedTool = (selectedTool == tool) ? nil : tool
                        }
                    } label: {
                        VStack {
                            Image(systemName: tool.iconName) // This now works for all tools
                                .font(.title2)
                            Text(tool.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedTool == tool ? .purple : .white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
