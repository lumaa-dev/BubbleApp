//Made by Lumaa

import Foundation

public struct AccountsList: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let repliesPolicy: RepliesPolicy?
    public let exclusive: Bool?
    
    public enum RepliesPolicy: String, Sendable, Codable, CaseIterable, Identifiable {
        public var id: String {
            rawValue
        }
        
        case followed, list, `none`
    }
}

extension AccountsList: Sendable {}
