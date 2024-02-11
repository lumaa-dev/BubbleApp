//Made by Lumaa

import Foundation

public struct SearchResults: Decodable {
    enum CodingKeys: String, CodingKey {
        case accounts, statuses, hashtags
    }
    
    public let accounts: [Account]
    public var relationships: [Relationship] = []
    public let statuses: [Status]
    public let hashtags: [Tag]
    
    public var isEmpty: Bool {
        accounts.isEmpty && statuses.isEmpty && hashtags.isEmpty
    }
}

extension SearchResults: Sendable {}

extension SearchResults: Equatable {
    public static func == (lhs: SearchResults, rhs: SearchResults) -> Bool {
        return lhs.statuses == rhs.statuses && lhs.accounts == rhs.accounts && lhs.relationships == rhs.relationships && lhs.hashtags == rhs.hashtags
    }
}

public enum Search: Endpoint {
    case search(query: String, type: String?, offset: Int?, following: Bool?)
    case accountsSearch(query: String, type: String?, offset: Int?, following: Bool?)
    
    public func path() -> String {
        switch self {
            case .search:
                "search"
            case .accountsSearch:
                "accounts/search"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case let .search(query, type, offset, following),
                let .accountsSearch(query, type, offset, following):
                var params: [URLQueryItem] = [.init(name: "q", value: query)]
                if let type {
                    params.append(.init(name: "type", value: type))
                }
                if let offset {
                    params.append(.init(name: "offset", value: String(offset)))
                }
                if let following {
                    params.append(.init(name: "following", value: following ? "true" : "false"))
                }
                params.append(.init(name: "resolve", value: "true"))
                return params
        }
    }
}
