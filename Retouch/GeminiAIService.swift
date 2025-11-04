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

    // --- HELPER FUNCTION ---
    private func sendAIRequest(prompt: String, image: UIImage) async -> Result<UIImage, AIError> {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return .failure(.failedToLoadData)
        }
        
        
        let imagePart = ModelContent.Part.data(mimetype: "image/jpeg", imageData)
        let promptPart = ModelContent.Part.text(prompt)
        
        do {
            let response = try await model.generateContent(promptPart, imagePart)
            
            guard let responsePart = response.candidates.first?.content.parts.first,
                  case .data(let mimetype, let bytes) = responsePart,
                  (mimetype == "image/jpeg" || mimetype == "image/png"),
                  let processedImage = UIImage(data: bytes)
            else {
                return .failure(.failedToGenerateContent)
            }
            
            return .success(processedImage)
            
        } catch {
            return .failure(.modelError(error.localizedDescription))
        }
    }

    // --- 1. OBJECT REMOVAL ---
    func removeObject(from image: UIImage,
                      withMask mask: UIImage,
                      prompt: String) async -> Result<UIImage, AIError> {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let maskData = mask.jpegData(compressionQuality: 0.8) else {
            return .failure(.failedToLoadData)
        }
        
       
        let imagePart = ModelContent.Part.data(mimetype: "image/jpeg", imageData)
        let maskPart = ModelContent.Part.data(mimetype: "image/jpeg", maskData)
        
        let promptPart = ModelContent.Part.text(prompt)
        
        do {
            let response = try await model.generateContent(promptPart, imagePart, maskPart)
            
            guard let responsePart = response.candidates.first?.content.parts.first,
                  case .data(let mimetype, let bytes) = responsePart,
                  mimetype == "image/jpeg",
                  let processedImage = UIImage(data: bytes)
            else {
                return .failure(.failedToGenerateContent)
            }
            return .success(processedImage)
        } catch {
            return .failure(.modelError(error.localizedDescription))
        }
    }
    
    // --- 2. NEW: AUTO ENHANCE ---
    func autoEnhanceImage(image: UIImage) async -> Result<UIImage, AIError> {
        let prompt = "Auto-enhance this photo. Adjust brightness, contrast, and color balance to make it look professional, vibrant, and clear. Return only the enhanced image."
        return await sendAIRequest(prompt: prompt, image: image)
    }
    
    // --- 3. NEW: BACKGROUND REMOVAL ---
    func removeBackground(image: UIImage) async -> Result<UIImage, AIError> {
        let prompt = "Remove the background from this image. Make the background transparent. Return a PNG with alpha transparency. Return only the processed image."
        // Note: This relies on the model's ability to return a PNG.
        return await sendAIRequest(prompt: prompt, image: image)
    }
    
    // --- 4. NEW: AI COLORIZE ---
    func colorizeImage(image: UIImage) async -> Result<UIImage, AIError> {
        let prompt = "Colorize this black and white photo. Make the colors look realistic and natural. Return only the colorized image."
        return await sendAIRequest(prompt: prompt, image: image)
    }
}
// <-- Make sure there is NO other code or class definition after this line -->
