//Made by Lumaa

import Foundation

public struct AppAccount: Codable, Identifiable, Hashable {
    public let server: String
    public var accountName: String?
    public let oauthToken: OauthToken?
    public static let saveKey: String = "threaded-appaccount.current"
    
    public var key: String {
        if let oauthToken {
            "\(server):\(oauthToken.createdAt)"
        } else {
            "\(server):anonymous"
        }
    }
    
    public var id: String {
        key
    }
    
    public init(server: String,
                accountName: String?,
                oauthToken: OauthToken? = nil)
    {
        self.server = server
        self.accountName = accountName
        self.oauthToken = oauthToken
    }
    
    func saveAsCurrent() throws {
        let encoder = JSONEncoder()
        let json = try encoder.encode(self)
        UserDefaults.standard.setValue(json, forKey: AppAccount.saveKey)
    }
    
    static func loadAsCurrent() throws -> AppAccount? {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: AppAccount.saveKey) {
            let account = try decoder.decode(AppAccount.self, from: data)
            return account
        }
        return nil
    }
}

extension AppAccount: Sendable {}

public enum Oauth: Endpoint {
    case authorize(clientId: String)
    case token(code: String, clientId: String, clientSecret: String)
    
    public func path() -> String {
        switch self {
            case .authorize:
                "oauth/authorize"
            case .token:
                "oauth/token"
        }
    }
    
    public var jsonValue: Encodable? {
        switch self {
            case let .token(code, clientId, clientSecret):
                TokenData(clientId: clientId, clientSecret: clientSecret, code: code)
            default:
                nil
        }
    }
    
    public struct TokenData: Encodable {
        public let grantType = "authorization_code"
        public let clientId: String
        public let clientSecret: String
        public let redirectUri = AppInfo.scheme
        public let code: String
        public let scope = AppInfo.scopes
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case let .authorize(clientId):
                return [
                    .init(name: "response_type", value: "code"),
                    .init(name: "client_id", value: clientId),
                    .init(name: "redirect_uri", value: AppInfo.scheme),
                    .init(name: "scope", value: AppInfo.scopes),
                ]
            default:
                return nil
        }
    }
}

public struct OauthToken: Codable, Hashable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    public let createdAt: Double
}
