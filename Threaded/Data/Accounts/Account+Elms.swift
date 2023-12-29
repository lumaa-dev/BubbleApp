//Made by Lumaa

import Foundation

public enum Visibility: String, Codable, CaseIterable, Hashable, Equatable, Sendable {
    case pub = "public"
    case unlisted
    case priv = "private"
    case direct
}

private enum CodingKeys: CodingKey {
    case asDate
}

public struct ServerDate: Codable, Hashable, Equatable, Sendable {
    public let asDate: Date
    
    public var relativeFormatted: String {
        DateFormatterCache.shared.createdAtRelativeFormatter.localizedString(for: asDate, relativeTo: Date())
    }
    
    public var shortDateFormatted: String {
        DateFormatterCache.shared.createdAtShortDateFormatted.string(from: asDate)
    }
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    public init() {
        asDate = Date() - 100
    }
    
    public init(from decoder: Decoder) throws {
        do {
            // Decode from server
            let container = try decoder.singleValueContainer()
            let stringDate = try container.decode(String.self)
            asDate = DateFormatterCache.shared.createdAtDateFormatter.date(from: stringDate) ?? Date()
        } catch {
            // Decode from cache
            let container = try decoder.container(keyedBy: CodingKeys.self)
            asDate = try container.decode(Date.self, forKey: .asDate)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(asDate, forKey: .asDate)
    }
}

class DateFormatterCache: @unchecked Sendable {
    static let shared = DateFormatterCache()
    
    let createdAtRelativeFormatter: RelativeDateTimeFormatter
    let createdAtShortDateFormatted: DateFormatter
    let createdAtDateFormatter: DateFormatter
    
    init() {
        let createdAtRelativeFormatter = RelativeDateTimeFormatter()
        createdAtRelativeFormatter.unitsStyle = .short
        self.createdAtRelativeFormatter = createdAtRelativeFormatter
        
        let createdAtShortDateFormatted = DateFormatter()
        createdAtShortDateFormatted.dateStyle = .short
        createdAtShortDateFormatted.timeStyle = .none
        self.createdAtShortDateFormatted = createdAtShortDateFormatted
        
        let createdAtDateFormatter = DateFormatter()
        createdAtDateFormatter.calendar = .init(identifier: .iso8601)
        createdAtDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        createdAtDateFormatter.timeZone = .init(abbreviation: "UTC")
        self.createdAtDateFormatter = createdAtDateFormatter
    }
}
