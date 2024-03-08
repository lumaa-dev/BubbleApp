//Made by Lumaa

import Foundation
import SwiftUI
import UIKit

// this is messy but it's alr

#if os(iOS)
public class AppDelegate: NSObject, UIWindowSceneDelegate, Sendable, UIApplicationDelegate {
    public var window: UIWindow?
    public private(set) var windowWidth: CGFloat = UIScreen.main.bounds.size.width
    public private(set) var windowHeight: CGFloat = UIScreen.main.bounds.size.height
    public private(set) var secret: [String: String] = [:]
    
    public func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = windowScene.keyWindow
    }
    
    override public init() {
        super.init()
        
        if let path = Bundle.main.path(forResource: "Secret", ofType: "plist") {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            if let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: String] {
                secret = plist
            }
        }
        
        windowWidth = window?.bounds.size.width ?? UIScreen.main.bounds.size.width
        windowHeight = window?.bounds.size.height ?? UIScreen.main.bounds.size.height
        Self.observedSceneDelegate.insert(self)
        _ = Self.observer // just for activating the lazy static property
    }
    
    static func readSecret() -> [String: String]? {
        if let path = Bundle.main.path(forResource: "Secret", ofType: "plist") {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            if let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String: String] {
                return plist
            }
        }
        
        return nil
    }
    
    deinit {
        Task { @MainActor in
            Self.observedSceneDelegate.remove(self)
        }
    }
    
    private static var observedSceneDelegate: Set<AppDelegate> = []
    private static let observer = Task {
        while true {
            try? await Task.sleep(for: .seconds(0.1))
            for delegate in observedSceneDelegate {
                let newWidth = delegate.window?.bounds.size.width ?? UIScreen.main.bounds.size.width
                if delegate.windowWidth != newWidth {
                    delegate.windowWidth = newWidth
                }
                let newHeight = delegate.window?.bounds.size.height ?? UIScreen.main.bounds.size.height
                if delegate.windowHeight != newHeight {
                    delegate.windowHeight = newHeight
                }
                
            }
        }
    }
}
#endif

public extension URL {
    static let placeholder: URL = URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg")!
}

extension AppInfo {
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}

public protocol Endpoint: Sendable {
    func path() -> String
    func queryItems() -> [URLQueryItem]?
    var jsonValue: Encodable? { get }
}

public extension Endpoint {
    var jsonValue: Encodable? {
        nil
    }
}

extension Endpoint {
    func makePaginationParam(sinceId: String?, maxId: String?, mindId: String?) -> [URLQueryItem]? {
        if let sinceId {
            return [.init(name: "since_id", value: sinceId)]
        } else if let maxId {
            return [.init(name: "max_id", value: maxId)]
        } else if let mindId {
            return [.init(name: "min_id", value: mindId)]
        }
        return nil
    }
}

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

public enum Accounts: Endpoint {
    case verifyCredentials

    public func path() -> String {
        switch self {
            case .verifyCredentials:
                "accounts/verify_credentials"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        nil
    }
}

public struct InstanceApp: Codable, Identifiable {
    public let id: String
    public let name: String
    public let website: URL?
    public let redirectUri: String
    public let clientId: String
    public let clientSecret: String
    public let vapidKey: String?
}

extension InstanceApp: Sendable {}

public struct ServerError: Decodable, Error {
    public let error: String?
    public var httpCode: Int?
}

public enum Apps: Endpoint {
    case registerApp
    
    public func path() -> String {
        switch self {
            case .registerApp:
                "apps"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case .registerApp:
                return [
                    .init(name: "client_name", value: AppInfo.clientName),
                    .init(name: "redirect_uris", value: AppInfo.scheme),
                    .init(name: "scopes", value: AppInfo.scopes),
                    .init(name: "website", value: AppInfo.website),
                ]
        }
    }
}

public struct LinkHandler {
    public let rawLink: String
    
    public var maxId: String? {
        do {
            let regex = try Regex("max_id=[0-9]+")
            if let match = rawLink.firstMatch(of: regex) {
                return match.output.first?.substring?.replacingOccurrences(of: "max_id=", with: "")
            }
        } catch {
            return nil
        }
        return nil
    }
}

extension LinkHandler: Sendable {}

public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
