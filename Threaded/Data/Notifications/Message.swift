//Made by Lumaa

import Foundation

public struct MessageContact: Identifiable, Decodable, Hashable, Equatable {
    public let id: String
    public let unread: Bool
    public let lastStatus: Status?
    public let accounts: [Account]
    
    public init(id: String, unread: Bool, lastStatus: Status? = nil, accounts: [Account]) {
        self.id = id
        self.unread = unread
        self.lastStatus = lastStatus
        self.accounts = accounts
    }
    
    public static func placeholder() -> MessageContact {
        .init(id: UUID().uuidString, unread: false, lastStatus: .placeholder(), accounts: [.placeholder()])
    }
    
    public static func placeholders() -> [MessageContact] {
        [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder(),
         .placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
    }
}

extension MessageContact: Sendable {}
