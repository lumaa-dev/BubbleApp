//Made by Lumaa

/// All other Mastodon clients' URIs found
final class AltClients {
    
    // - Official iOS Mastodon client by Mastodon
    struct OfficialMastodon {
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
    struct IceCubesApp {
        static let `default` = "icecubesapp://"
        
        static func profile(server: String, username: String) -> String {
            return "\(Self.default)\(server)/@\(username)"
        }
        
        static func profile(account: Account) -> String {
            let url = account.url?.absoluteString.replacingOccurrences(of: "https://", with: Self.default)
            return url ?? Self.default
        }
        
        static func status(_ status: Status) -> String {
            return Self.profile(account: status.account) + "/\(status.id)"
        }
    }
    
    // - Ivory by Tapbots
    struct IvoryApp {
        static let `default` = "ivory://"
        
        // Others found don't work? Maybe because of demo
    }
}
