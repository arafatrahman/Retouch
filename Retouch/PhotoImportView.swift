import SwiftUI
import PhotosUI // Import Apple's PhotoKit

struct PhotoImportView: View {
    // State for managing photos
    @State private var assets: [PHAsset] = []
    @State private var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    
    // State for showing the Camera and Files pickers
    @State private var isShowingCamera = false
    @State private var isShowingFileImporter = false
    @State private var isShowingSettings = false // For Settings screen
    
    // State for navigating to the editor
    @State private var selectedImage: UIImage?
    @State private var navigateToEditor = false

    // Grid layout: 3 columns, flexible
    private let gridItems = [GridItem(.flexible(), spacing: 1),
                             GridItem(.flexible(), spacing: 1),
                             GridItem(.flexible(), spacing: 1)]

    var body: some View {
        // We use NavigationStack to get the top bar and allow navigation
        NavigationStack {
            VStack {
                // Main content depends on permission status
                switch authorizationStatus {
                case .authorized, .limited:
                    // We have permission, show the grid
                    photoGrid
                case .denied, .restricted:
                    // Permission denied, show message
                    permissionDeniedView
                case .notDetermined:
                    // Not yet asked, show button
                    permissionRequestView
                @unknown default:
                    EmptyView()
                }
            }
            .navigationTitle("Retouch Editor")
            .preferredColorScheme(.dark)
            .toolbar {
                // Button for "Import from Files"
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Image(systemName: "folder")
                    }
                }
                
                // Button for "Settings"
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                // Button for "Camera"
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Check for camera permission first
                        isShowingCamera = true
                    } label: {
                        Image(systemName: "camera")
                    }
                }
            }
            // When an image is selected, navigate to the Editor
            .navigationDestination(isPresented: $navigateToEditor) {
                if let selectedImage {
                    // This is the placeholder for Section 3
                    EditorMainView(image: selectedImage)
                }
            }
            // Show the native Camera sheet
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(sourceType: .camera) { image in
                    self.selectedImage = image
                    self.navigateToEditor = true
                }
            }
            // Show the native Files sheet
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.image], // Allow all image types
                onCompletion: { result in
                    handleFileImport(result: result)
                }
            )
            // Show the Settings sheet
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .onAppear {
                // When the view appears, check status and fetch photos if we can
                if authorizationStatus == .authorized || authorizationStatus == .limited {
                    fetchPhotos()
                }
            }
        }
    }
    
    // MARK: - View Components

    /// The main photo grid
    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridItems, spacing: 1) {
                ForEach(assets, id: \.self) { asset in
                    PhotoGridItem(asset: asset)
                        .aspectRatio(1, contentMode: .fill) // Make it a square
                        .clipped()
                        .onTapGesture {
                            // When tapped, load the full-res image
                            loadFullImage(from: asset)
                        }
                }
            }
        }
    }
    
    /// View shown when permission is not yet asked
    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("Welcome to Retouch")
                .font(.title)
                .fontWeight(.bold)
            Text("Please allow access to your photo library to get started.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Allow Access") {
                requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    /// View shown when permission is denied
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            Text("Access Denied")
                .font(.title)
                .fontWeight(.bold)
            Text("Retouch needs photo access. Please go to your device's Settings > Privacy > Photos to grant permission.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Button to open the app's settings
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") {
                    UIApplication.shared.open(settingsURL)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Logic Functions
    
    /// Asks the user for photo library permission
    private func requestPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            // Update status on the main thread
            DispatchQueue.main.async {
                self.authorizationStatus = newStatus
                if newStatus == .authorized || newStatus == .limited {
                    fetchPhotos()
                }
            }
        }
    }
    
    /// Fetches all photos from the library
    private func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var loadedAssets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            loadedAssets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.assets = loadedAssets
        }
    }
    
// Loads a full-resolution UIImage from a PHAsset
    private func loadFullImage(from asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // Allow iCloud download
        
        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize, // Get full resolution
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.selectedImage = image
                    self.navigateToEditor = true
                }
            }
        }
    }
    
    /// Handles the result from the Files importer
    private func handleFileImport(result: Result<URL, Error>) {
        do {
            let fileURL = try result.get()
            // Ensure we can access the file
            if fileURL.startAccessingSecurityScopedResource() {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    self.selectedImage = image
                    self.navigateToEditor = true
                }
                // Stop accessing the file
                fileURL.stopAccessingSecurityScopedResource()
            }
        } catch {
            print("Error importing file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reusable Photo Grid Item

/// A small view that represents a single photo thumbnail in the grid
struct PhotoGridItem: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }
    }
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        // Request a small, square thumbnail
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 250, height: 250),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }
}
