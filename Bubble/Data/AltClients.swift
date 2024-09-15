//Made by Lumaa

/// An available app on the App Store
protocol DownloadableApp {
    static var name: String { get }
    static var `default`: String { get }
}

/// All other Mastodon clients' URIs found
final class AltClients {
    
    // - Official iOS Mastodon client by Mastodon
    struct OfficialMastodon: DownloadableApp {
        static let name = "Mastodon"
        static let `default` = "mastodon://"
        
        static let post = "\(Self.default)post"
        static let search = "\(Self.default)search?query=Threaded" // query feature does not work?
        
        static func status(id: String) -> String {
            return "\(Self.default)status/\(id)"
        }
        
        static func profile(account: Account) -> String {
            return "\(Self.default)status/\(account.acct)"
        }
        
        static func profile(acct: String) -> String {
            return "\(Self.default)status/\(acct)"
        }
        
    }
    
    // - IcesCubesApp by Dimillian, open-source
    struct IceCubesApp: DownloadableApp {
        static let name = "Ice Cubes"
        static let `default` = "icecubesapp://"
        
        static func profile(server: String, username: String) -> String {
            return "\(Self.default)\(server)/@\(username)"
        }
        
        static func profile(account: Account) -> String {
            let username = account.username
            let server = account.acct.split(separator: "@")[1]
            
            return Self.profile(server: String(server), username: username)
        }
        
        static func status(_ statusUrl: String) -> String {
            return Self.default + "\(statusUrl.replacingOccurrences(of: "https://", with: ""))"
        }
        
        static func status(_ status: Status) -> String {
            return Self.profile(account: status.account) + "/\(status.id)"
        }
    }
    
    // - Ivory by Tapbots
    struct IvoryApp: DownloadableApp {
        // official URL Schemes: https://tapbots.com/support/ivory/tips/urlschemes
        
        static let name = "Ivory"
        static let `default` = "ivory://"
        
        static func profile(account: Account) -> String {
            return "\(Self.default)acct/user_profile/\(account.acct)"
        }
        
        static func profile(acct: String) -> String {
            return "\(Self.default)acct/user_profile/\(acct)"
        }
        
        static func createPost(_ text: String) -> String {
            let compose = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(Self.default)acct/post?text=\(compose)"
        }
    }
    
    /// Threads by Meta Platforms only allows connections from inside their personal protocol just yet
    struct ThreadsApp: DownloadableApp {
        static let name = "Threads"
        static let `default` = "barcelona://"
        
        static func profile(_ username: String) -> String {
            return "\(Self.default)user?username=\(username)"
        }
        
        static let settings = "\(Self.default)settings"
        static let search = "\(Self.default)search"
        
        static func createPost(_ text: String) -> String {
            let compose = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(Self.default)create?text=\(compose)"
        }
    }
    
    /// X by X Corp. only allows connections from inside their personal protocol
    struct XApp: DownloadableApp {
        static let name = "X (formerly Twitter)"
        static let `default` = "twitter://"
        
        static func createPost(_ text: String) -> String {
            let compose = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(Self.default)post?message=\(compose)"
        }
    }
}
