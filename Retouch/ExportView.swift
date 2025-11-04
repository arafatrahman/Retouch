import SwiftUI

struct ExportView: View {
    // The final, edited image to export
    let imageToExport: UIImage
    
    // Callback to close the sheet
    var onDismiss: () -> Void
    
    // State for export settings
    @State private var format: ExportFormat = .jpeg
    @State private var quality: Double = 0.9
    
    // State for UI
    @State private var isShowingShareSheet = false
    @State private var isShowingSuccessAlert = false
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case jpeg = "JPEG"
        case png = "PNG"
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            Form {
                // 1. PREVIEW SECTION
                Section(header: Text("Preview")) {
                    Image(uiImage: imageToExport)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxHeight: 300)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // 2. SETTINGS SECTION
                Section(header: Text("Export Settings")) {
                    // Format Picker
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Quality Slider (only show for JPEG)
                    if format == .jpeg {
                        VStack(alignment: .leading) {
                            Text("Quality: \(Int(quality * 100))%")
                                .font(.caption)
                            Slider(value: $quality, in: 0.1...1.0)
                        }
                    }
                }
                
                // 3. ACTIONS SECTION
                Section {
                    // Save to Camera Roll
                    Button(action: saveToCameraRoll) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Camera Roll")
                        }
                    }
                    
                    // Share Button
                    Button(action: { isShowingShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share...")
                        }
                    }
                }
            }
            .navigationTitle("Export & Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
            // The success checkmark alert
            .alert("Saved!", isPresented: $isShowingSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
            // The native iOS Share Sheet
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(activityItems: [getExportData()])
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Logic
    
    /// Gets the final image data based on settings
    private func getExportData() -> Any {
        if format == .png {
            // PNG is lossless, quality slider is ignored
            return imageToExport.pngData() ?? imageToExport
        } else {
            // JPEG uses the quality slider
            return imageToExport.jpegData(compressionQuality: quality) ?? imageToExport
        }
    }

    /// Saves the image to the user's Photo Library
    private func saveToCameraRoll() {
        let imageSaver = ImageSaver(
            image: imageToExport,
            onSuccess: {
                isShowingSuccessAlert = true
            },
            onError: { error in
                print("Error saving image: \(error.localizedDescription)")
                // TODO: Show an error alert
            }
        )
        imageSaver.save()
    }
}

// MARK: - Share Sheet Helper

// Wraps the native UIKit Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Image Saver Helper

// A helper class to save to Photos (requires a delegate)
class ImageSaver: NSObject {
    var image: UIImage
    var onSuccess: () -> Void
    var onError: (Error) -> Void

    init(image: UIImage, onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.image = image
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func save() {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            onError(error)
        } else {
            onSuccess()
        }
    }
}

