import UIKit
import GoogleGenerativeAI

class GeminiAIService {
    
    // !!! PASTE YOUR KEY HERE !!!
    // !!! WARNING: FOR DEMO USE ONLY. DO NOT SHIP AN APP WITH THIS. !!!
    private let apiKey = "AIzaSyBzsi8ldQ-DNEWuqPa9p7JDWQdSmpxF9gY" // <--- YOUR KEY
    
    // The specific model for in-painting
    private let model: GenerativeModel
    
    // Initialize the model with the API key
    init() {
        self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: self.apiKey)
    }

    enum AIError: Error {
        case failedToLoadData
        case failedToGenerateContent
        case modelError(String)
    }

    /// Uses AI to "in-paint" an image based on a mask.
    func removeObject(from image: UIImage,
                      withMask mask: UIImage,
                      prompt: String) async -> Result<UIImage, AIError> {
        
        // 1. Compress images to JPEG (required by the API)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return .failure(.failedToLoadData)
        }
        guard let maskData = mask.jpegData(compressionQuality: 0.8) else {
            return .failure(.failedToLoadData)
        }
        
        // 2. Prepare the model parts
        // (Using the syntax from your previous successful fix)
        let imagePart = ModelContent.Part.data(mimetype: "image/jpeg", imageData)
        let maskPart = ModelContent.Part.data(mimetype: "image/jpeg", maskData)
        let promptPart = ModelContent.Part.text(prompt)
        
        // 3. Send the request
        do {
            let response = try await model.generateContent(
                promptPart, // The text instruction
                imagePart,  // The original image
                maskPart    // The mask (what to edit)
            )
            
            // 4. Process the response
            // --- THIS IS THE FIX ---
            // The 'parts' are inside response.candidates.first.content
            guard let responsePart = response.candidates.first?.content.parts.first,
                  case .data(let mimetype, let bytes) = responsePart,
                  mimetype == "image/jpeg",
                  let processedImage = UIImage(data: bytes)
            else {
                return .failure(.failedToGenerateContent)
            }
            // --- END OF FIX ---
            
            // Success!
            return .success(processedImage)
            
        } catch {
            return .failure(.modelError(error.localizedDescription))
        }
    }
}
