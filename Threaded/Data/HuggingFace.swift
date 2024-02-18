//Made by Lumaa

import Foundation
import UIKit

@Observable
final class HuggingFace: ObservableObject {
    static var token: String = ""
    static let altGenUrl: URL = URL(string: "https://api-inference.huggingface.co/models/Salesforce/blip-image-captioning-large")!
    static let textGenURL: URL = URL(string: "https://api-inference.huggingface.co/models/grammarly/coedit-large")!
    
    var lastImgGeneration: String? = nil
    
    init() {
        self.lastImgGeneration = nil
    }
    
    static func getToken() -> String? {
        guard let path = Bundle.main.path(forResource: "Secret", ofType: "plist") else { return nil }
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        guard let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: String] else { return nil }
        Self.token = plist["AI_Token"] ?? ""
        return Self.token
    }
    
    func altGeneration(image: UIImage) -> String? {
        if let imageData = image.jpegData(compressionQuality: 0.5) {
            let base64Image = imageData.base64EncodedString()
            let parameters = ["image": base64Image]
            
            let headers = ["Authorization": "Bearer \(Self.token)"]
            var request = URLRequest(url: Self.altGenUrl)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
            
            let semaphore = DispatchSemaphore(value: 0)
            var jsonResponse: [[String: Any]]?
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                defer { semaphore.signal() }
                if let data = data {
                    jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                }
            }.resume()
            
            semaphore.wait()
            return jsonResponse?[0]["generated_text"] as? String
        }
        
        return nil
    }
}
