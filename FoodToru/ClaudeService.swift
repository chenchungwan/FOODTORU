//
//  ClaudeService.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation
import UIKit

struct MealAnalysis: Codable {
    let mealName: String
    let calories: Int
    let ingredients: [String]
    let replacementIngredients: [String]
    let analysis: String
    let referenceSources: [String]
}

class ClaudeService: ObservableObject {
    private let keychainService = KeychainService.shared
    private let logger = Logger.shared
    
    // Get API key from secure storage
    private var apiKey: String? {
        return keychainService.getAPIKey()
    }
    
    // Validate API key format
    private var isValidAPIKey: Bool {
        guard let key = apiKey else { return false }
        return keychainService.isValidAPIKey(key)
    }
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var workingModel: String = "claude-opus-4-1-20250805" // Default model
    
    // Check if API key is configured
    func isAPIKeyConfigured() -> Bool {
        return keychainService.hasAPIKey() && isValidAPIKey
    }
    
    // Test function to verify API connection
    func testAPIConnection() async -> Bool {
        guard isAPIKeyConfigured() else {
            logger.apiKeyStatus("Not configured", context: "API Test")
            return false
        }
        let modelsToTry = [
            "claude-opus-4-1-20250805",
            "claude-3-5-sonnet-20241022",
            "claude-3-opus-20240229",
            "claude-3-sonnet-20240229",
            "claude-3-haiku-20240307"
        ]
        
        for model in modelsToTry {
            logger.debug("Testing model: \(model)", context: "API Test")
            if await testWithModel(model) {
                logger.debug("Found working model: \(model)", context: "API Test")
                workingModel = model
                return true
            }
        }
        
        logger.warning("No working models found", context: "API Test")
        return false
    }
    
    private func testWithModel(_ model: String) async -> Bool {
        guard let apiKey = apiKey, isValidAPIKey else {
            logger.apiKeyStatus("Invalid or missing", context: "API Test")
            return false
        }
        
        let testRequestBody: [String: Any] = [
            "model": model,
            "max_tokens": 100,
            "messages": [
                [
                    "role": "user",
                    "content": "Hello, please respond with 'API connection successful'"
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0 // 30 second timeout for test
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testRequestBody)
            
            logger.apiRequest(url: url.absoluteString, method: "POST", context: "API Test")
            
            // Create URLSession with timeout configuration
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 30.0
            sessionConfig.timeoutIntervalForResource = 60.0
            let session = URLSession(configuration: sessionConfig)
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.apiResponse(statusCode: httpResponse.statusCode, dataSize: data.count, context: "API Test")
                
                if httpResponse.statusCode == 200 {
                    logger.debug("API connection test successful", context: "API Test")
                    return true
                } else if httpResponse.statusCode == 401 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    logger.apiError("Authentication Error (401): \(errorMessage)", context: "API Test")
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    logger.apiError(errorMessage, statusCode: httpResponse.statusCode, context: "API Test")
                }
            }
        } catch {
            logger.apiError(error.localizedDescription, context: "API Test")
        }
        
        return false
    }
    
    func analyzeMeal(image: UIImage) async -> MealAnalysis? {
        guard let apiKey = apiKey, isValidAPIKey else {
            await MainActor.run {
                self.errorMessage = "No valid API key found. Please set your Claude API key in Settings."
            }
            return nil
        }
        
        // Validate and compress image
        let maxImageSize: Int = 5 * 1024 * 1024 // 5MB limit
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // Reduce quality if image is too large
        while let data = imageData, data.count > maxImageSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalImageData = imageData else {
            await MainActor.run {
                self.errorMessage = "Failed to process image"
            }
            return nil
        }
        
        // Log image size for debugging
        logger.debug("Image size: \(finalImageData.count) bytes (compression: \(compressionQuality))", context: "Meal Analysis")
        
        let base64Image = finalImageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": workingModel,
            "max_tokens": 1000,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Analyze this food image and provide: 1) The name of the meal/dish, 2) Estimated total calories, 3) List of main ingredients, 4) Healthier replacement ingredient suggestions, 5) Brief nutritional analysis, 6) URLs to reference sources used for nutritional information (such as USDA FoodData Central, nutrition databases, or reputable nutritional resources). Return ONLY valid JSON without any markdown formatting, code blocks, or extra text. Use this exact format with keys: mealName (string), calories (integer), ingredients (array of strings), replacementIngredients (array of strings), analysis (string), referenceSources (array of URL strings). Example: {\"mealName\":\"Pasta\",\"calories\":450,\"ingredients\":[\"pasta\",\"tomato sauce\"],\"replacementIngredients\":[\"whole wheat pasta\"],\"analysis\":\"Nutritional info\",\"referenceSources\":[\"https://fdc.nal.usda.gov/\",\"https://nutritiondata.self.com/\"]}"
                        ],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else {
            await MainActor.run {
                self.errorMessage = "Invalid URL"
            }
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60.0 // 60 second timeout
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            logger.apiRequest(url: url.absoluteString, method: "POST", context: "Meal Analysis")
            logger.imageProcessing(finalImageData.count, context: "Meal Analysis")
            
        } catch {
            logger.apiError("Failed to create request: \(error.localizedDescription)", context: "Meal Analysis")
            await MainActor.run {
                self.errorMessage = "Failed to create request: \(error.localizedDescription)"
            }
            return nil
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Create URLSession with timeout configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60.0
        sessionConfig.timeoutIntervalForResource = 120.0
        let session = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await session.data(for: request)
            
        guard let httpResponse = response as? HTTPURLResponse else {
            await MainActor.run {
                self.errorMessage = "Invalid response"
                self.isLoading = false
            }
            return nil
        }
        
        logger.apiResponse(statusCode: httpResponse.statusCode, dataSize: data.count, context: "Meal Analysis")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.apiError(errorMessage, statusCode: httpResponse.statusCode, context: "Meal Analysis")
            await MainActor.run {
                self.errorMessage = "API request failed (Status: \(httpResponse.statusCode)): \(errorMessage)"
                self.isLoading = false
            }
            return nil
        }
            
            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            logger.debug("API response received successfully", context: "Meal Analysis")
            
            guard let content = jsonResponse?["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                logger.apiError("Failed to parse response content", context: "Meal Analysis")
                await MainActor.run {
                    self.errorMessage = "Invalid response format"
                    self.isLoading = false
                }
                return nil
            }
            
            logger.debug("Parsing Claude response", context: "Meal Analysis")
            
            // Extract JSON from the response text (handle markdown code blocks or extra text)
            let jsonText = extractJSON(from: text)
            
            guard let jsonData = jsonText.data(using: .utf8) else {
                logger.apiError("Failed to convert text to data", context: "Meal Analysis")
                await MainActor.run {
                    self.errorMessage = "Failed to parse response"
                    self.isLoading = false
                }
                return nil
            }
            
            do {
                let mealAnalysis = try JSONDecoder().decode(MealAnalysis.self, from: jsonData)
                logger.mealAnalysis(mealAnalysis.mealName, calories: mealAnalysis.calories, context: "Meal Analysis")
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                return mealAnalysis
            } catch {
                logger.apiError("Failed to decode JSON: \(error.localizedDescription). Response text: \(text.prefix(200))", context: "Meal Analysis")
                await MainActor.run {
                    self.errorMessage = "Failed to parse meal analysis: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Network error: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    // MARK: - JSON Extraction Helper
    
    /// Extracts JSON from response text, handling markdown code blocks or extra text
    private func extractJSON(from text: String) -> String {
        var jsonText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present (```json ... ``` or ``` ... ```)
        if jsonText.hasPrefix("```") {
            // Find the first newline after ```
            if let firstNewline = jsonText.firstIndex(of: "\n") {
                jsonText = String(jsonText[jsonText.index(after: firstNewline)...])
            }
            // Remove the closing ```
            if let lastBackticks = jsonText.range(of: "```", options: .backwards) {
                jsonText = String(jsonText[..<lastBackticks.lowerBound])
            }
            jsonText = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find JSON object boundaries if there's extra text
        if let firstBrace = jsonText.firstIndex(of: "{") {
            if let lastBrace = jsonText.lastIndex(of: "}") {
                jsonText = String(jsonText[firstBrace...lastBrace])
            }
        }
        
        return jsonText
    }
}
