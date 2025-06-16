//Made by Lumaa

import Foundation
import SwiftUI
import SwiftData
import KeychainSwift

@Model
class LoggedAccount {
    var token: OauthToken
    var acct: String
    var app: AppAccount?

    init(token: OauthToken = OauthToken(accessToken: "ABC", tokenType: "ABC", scope: "ABC", createdAt: 0.0), acct: String) {
        self.token = token
        self.acct = acct
        self.app = nil
    }
    
    init(appAccount: AppAccount) {
        guard let token = appAccount.oauthToken, let acct = appAccount.accountName else { fatalError("Cannot convert AppAccount to LoggedAccount") }
        self.token = token
        self.acct = acct
        self.app = appAccount
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

public struct OauthToken: Codable, Hashable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    public let createdAt: Double
}
