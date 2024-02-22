//Made by Lumaa

import Foundation
import KeychainSwift

@Observable
public class AccountManager: ObservableObject {
    private var client: Client?
    private var account: Account?
    
    public static let shared: AccountManager = AccountManager()
    
    init(client: Client? = nil, account: Account? = nil) {
        self.client = client
        self.account = account
    }
    
    public func clear() {
        self.client = nil
        self.account = nil
    }
    
    public func setClient(_ client: Client) {
        self.client = client
    }
    
    public func getClient() -> Client? {
        return client
    }
    
    public func setAccount(_ account: Account) {
        self.account = account
    }
    
    public func getAccount() -> Account? {
        return account
    }
    
    public func forceClient() -> Client {
        guard client != nil else { fatalError("Client is not existant in that context") }
        return client!
    }
    
    public func forceAccount() -> Account {
        guard account != nil else { fatalError("Account is not existant in that context") }
        return account!
    }
    
    public func fetchAccount() async -> Account? {
        guard client != nil else { fatalError("Client is not existant in that context") }
        account = try? await client!.get(endpoint: Accounts.verifyCredentials)
        return account
    }
}

public struct AppAccount: Codable, Identifiable, Hashable {
    public let server: String
    public var accountName: String?
    public let oauthToken: OauthToken?
    
    private static let saveKey: String = "threaded-appaccount.current"
    private static var keychain: KeychainSwift {
        let kc = KeychainSwift()
        // synchronise later
        return kc
    }
    
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
    
    public init(server: String, accountName: String?, oauthToken: OauthToken? = nil) {
        self.server = server
        self.accountName = accountName
        self.oauthToken = oauthToken
    }
    
    public static func clear() {
        Self.keychain.delete(Self.saveKey)
    }
    
    public func clear() {
        Self.clear()
    }
    
    /// This function only works with the given `AppAccount`
    public func saveAsCurrent(_ appAccount: AppAccount? = nil) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(appAccount ?? self) {
            Self.keychain.set(data, forKey: Self.saveKey, withAccess: .accessibleWhenUnlocked)
        } else {
            fatalError("Couldn't encode AppAccount correctly to save")
        }
    }
    
    /// This function only works with the last saved `AppAccount` or with the given `Data`
    public static func loadAsCurrent(_ data: Data? = nil) -> Self? {
        let decoder = JSONDecoder()
        if let newData = data ?? keychain.getData(Self.saveKey) {
            if let decoded = try? decoder.decode(Self.self, from: newData) {
                return decoded
            } else {
                return nil
            }
        } else {
            return nil
        }
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
