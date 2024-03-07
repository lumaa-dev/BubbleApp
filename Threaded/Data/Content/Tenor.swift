//Made by Lumaa

import Foundation

class Tenor {
    private static let url: String = "https://tenor.googleapis.com/v2"
    private static var token: String = ""
    
    private static let limit: Int = 20
    private static let contentFilter: String = "off" // all content other than nudity
    private static let mediaFilter: String = "preview,tinygif,gif,tinywebm,webm"
    
    init(token: String) {
        _ = Self.getToken()
    }
    
    static func getToken() -> String? {
        guard let plist = AppDelegate.readSecret() else { return nil }
        Self.token = plist["Tenor_Token"] ?? ""
        return Self.token
    }
    
    func search(query: String) {
        let params: [URLQueryItem] = [
            .init(name: "q", value: query),
            .init(name: "key", value: Self.token),
            .init(name: "client_key", value: "\(AppInfo.clientName)-\(AppInfo.appVersion)"),
            .init(name: "contentfilter", value: Self.contentFilter),
            .init(name: "media_filter", value: Self.mediaFilter)
        ]
        
        if var comp = URLComponents(string: "\(Self.url)/search") {
            comp.queryItems = params
            if let url = comp.url {
                var req = URLRequest(url: url)
                req.httpMethod = "GET"
                
                let semaphore = DispatchSemaphore(value: 0)
                
                var jsonResponse: [String: Any]?
                URLSession.shared.dataTask(with: req) { (data, response, error) in
                    defer { semaphore.signal() }
                    if let data = data {
                        jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    }
                }.resume()
            }
        }
    }
}
