//Made by Lumaa

import Foundation

public final class Status: AnyStatus, Codable, Identifiable, Equatable, Hashable {
    public static func == (lhs: Status, rhs: Status) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id: String
    public let content: HTMLString
    public let account: Account
    public let createdAt: ServerDate
    public let editedAt: ServerDate?
    public let reblog: ReblogStatus?
    public let mediaAttachments: [MediaAttachment]
    public let mentions: [Mention]
    public let repliesCount: Int
    public let reblogsCount: Int
    public let favouritesCount: Int
    public let card: Card?
    public let favourited: Bool?
    public let reblogged: Bool?
    public let pinned: Bool?
    public let bookmarked: Bool?
    public let emojis: [Emoji]
    public let url: String?
    public let application: Application?
    public let inReplyToId: String?
    public let inReplyToAccountId: String?
    public let visibility: Visibility
    public let poll: Poll?
    public let spoilerText: HTMLString
    public let filtered: [Filtered]?
    public let sensitive: Bool
    public let language: String?
    
    public init(id: String, content: HTMLString, account: Account, createdAt: ServerDate, editedAt: ServerDate?, reblog: ReblogStatus?, mediaAttachments: [MediaAttachment], mentions: [Mention], repliesCount: Int, reblogsCount: Int, favouritesCount: Int, card: Card?, favourited: Bool?, reblogged: Bool?, pinned: Bool?, bookmarked: Bool?, emojis: [Emoji], url: String?, application: Application?, inReplyToId: String?, inReplyToAccountId: String?, visibility: Visibility, poll: Poll?, spoilerText: HTMLString, filtered: [Filtered]?, sensitive: Bool, language: String?) {
        self.id = id
        self.content = content
        self.account = account
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.reblog = reblog
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.repliesCount = repliesCount
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.card = card
        self.favourited = favourited
        self.reblogged = reblogged
        self.pinned = pinned
        self.bookmarked = bookmarked
        self.emojis = emojis
        self.url = url
        self.application = application
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.visibility = visibility
        self.poll = poll
        self.spoilerText = spoilerText
        self.filtered = filtered
        self.sensitive = sensitive
        self.language = language
    }
    
    public static func placeholder(forSettings: Bool = false, language: String? = nil) -> Status {
        .init(id: UUID().uuidString,
              content: .init(stringValue: "Here's to the [#crazy](#) ones",
                             parseMarkdown: forSettings),
              
              account: .placeholder(),
              createdAt: ServerDate(),
              editedAt: nil,
              reblog: nil,
              mediaAttachments: [],
              mentions: [],
              repliesCount: 2,
              reblogsCount: 1,
              favouritesCount: 3,
              card: nil,
              favourited: false,
              reblogged: false,
              pinned: false,
              bookmarked: false,
              emojis: [],
              url: "https://example.com",
              application: nil,
              inReplyToId: nil,
              inReplyToAccountId: nil,
              visibility: .pub,
              poll: nil,
              spoilerText: .init(stringValue: ""),
              filtered: [],
              sensitive: false,
              language: language)
    }
    
    public static func placeholders() -> [Status] {
        [.placeholder(), .placeholder(), .placeholder(), .placeholder(), .placeholder()]
    }
    
    public var reblogAsAsStatus: Status? {
        if let reblog {
            return .init(id: reblog.id,
                         content: reblog.content,
                         account: reblog.account,
                         createdAt: reblog.createdAt,
                         editedAt: reblog.editedAt,
                         reblog: nil,
                         mediaAttachments: reblog.mediaAttachments,
                         mentions: reblog.mentions,
                         repliesCount: reblog.repliesCount,
                         reblogsCount: reblog.reblogsCount,
                         favouritesCount: reblog.favouritesCount,
                         card: reblog.card,
                         favourited: reblog.favourited,
                         reblogged: reblog.reblogged,
                         pinned: reblog.pinned,
                         bookmarked: reblog.bookmarked,
                         emojis: reblog.emojis,
                         url: reblog.url,
                         application: reblog.application,
                         inReplyToId: reblog.inReplyToId,
                         inReplyToAccountId: reblog.inReplyToAccountId,
                         visibility: reblog.visibility,
                         poll: reblog.poll,
                         spoilerText: reblog.spoilerText,
                         filtered: reblog.filtered,
                         sensitive: reblog.sensitive,
                         language: reblog.language)
        }
        return nil
    }
}

public final class ReblogStatus: AnyStatus, Codable, Identifiable, Equatable, Hashable {
    public static func == (lhs: ReblogStatus, rhs: ReblogStatus) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id: String
    public let content: HTMLString
    public let account: Account
    public let createdAt: ServerDate
    public let editedAt: ServerDate?
    public let mediaAttachments: [MediaAttachment]
    public let mentions: [Mention]
    public let repliesCount: Int
    public let reblogsCount: Int
    public let favouritesCount: Int
    public let card: Card?
    public let favourited: Bool?
    public let reblogged: Bool?
    public let pinned: Bool?
    public let bookmarked: Bool?
    public let emojis: [Emoji]
    public let url: String?
    public let application: Application?
    public let inReplyToId: String?
    public let inReplyToAccountId: String?
    public let visibility: Visibility
    public let poll: Poll?
    public let spoilerText: HTMLString
    public let filtered: [Filtered]?
    public let sensitive: Bool
    public let language: String?
    
    public init(id: String, content: HTMLString, account: Account, createdAt: ServerDate, editedAt: ServerDate?, mediaAttachments: [MediaAttachment], mentions: [Mention], repliesCount: Int, reblogsCount: Int, favouritesCount: Int, card: Card?, favourited: Bool?, reblogged: Bool?, pinned: Bool?, bookmarked: Bool?, emojis: [Emoji], url: String?, application: Application? = nil, inReplyToId: String?, inReplyToAccountId: String?, visibility: Visibility, poll: Poll?, spoilerText: HTMLString, filtered: [Filtered]?, sensitive: Bool, language: String?) {
        self.id = id
        self.content = content
        self.account = account
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.repliesCount = repliesCount
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.card = card
        self.favourited = favourited
        self.reblogged = reblogged
        self.pinned = pinned
        self.bookmarked = bookmarked
        self.emojis = emojis
        self.url = url
        self.application = application
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.visibility = visibility
        self.poll = poll
        self.spoilerText = spoilerText
        self.filtered = filtered
        self.sensitive = sensitive
        self.language = language
    }
}

// Every property in Status is immutable.
extension Status: Sendable {}

// Every property in ReblogStatus is immutable.
extension ReblogStatus: Sendable {}

public protocol AnyStatus {
    var id: String { get }
    var content: HTMLString { get }
    var account: Account { get }
    var createdAt: ServerDate { get }
    var editedAt: ServerDate? { get }
    var mediaAttachments: [MediaAttachment] { get }
    var mentions: [Mention] { get }
    var repliesCount: Int { get }
    var reblogsCount: Int { get }
    var favouritesCount: Int { get }
    var card: Card? { get }
    var favourited: Bool? { get }
    var reblogged: Bool? { get }
    var pinned: Bool? { get }
    var bookmarked: Bool? { get }
    var emojis: [Emoji] { get }
    var url: String? { get }
    var application: Application? { get }
    var inReplyToId: String? { get }
    var inReplyToAccountId: String? { get }
    var visibility: Visibility { get }
    var poll: Poll? { get }
    var spoilerText: HTMLString { get }
    var filtered: [Filtered]? { get }
    var sensitive: Bool { get }
    var language: String? { get }
}

public struct StatusContext: Decodable {
    public let ancestors: [Status]
    public let descendants: [Status]
    
    public static func empty() -> StatusContext {
        .init(ancestors: [], descendants: [])
    }
}

extension StatusContext: Sendable {}

public struct MediaAttachment: Codable, Identifiable, Hashable, Equatable {
    public struct MetaContainer: Codable, Equatable {
        public struct Meta: Codable, Equatable {
            public let width: Int?
            public let height: Int?
        }
        
        public let original: Meta?
    }
    
    public enum SupportedType: String {
        case image, gifv, video, audio
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id: String
    public let type: String
    public var supportedType: SupportedType? {
        SupportedType(rawValue: type)
    }
    
    public var localizedTypeDescription: String? {
        if let supportedType {
            switch supportedType {
                case .image:
                    return NSLocalizedString("accessibility.media.supported-type.image.label", bundle: .main, comment: "A localized description of SupportedType.image")
                case .gifv:
                    return NSLocalizedString("accessibility.media.supported-type.gifv.label", bundle: .main, comment: "A localized description of SupportedType.gifv")
                case .video:
                    return NSLocalizedString("accessibility.media.supported-type.video.label", bundle: .main, comment: "A localized description of SupportedType.video")
                case .audio:
                    return NSLocalizedString("accessibility.media.supported-type.audio.label", bundle: .main, comment: "A localized description of SupportedType.audio")
            }
        }
        return nil
    }
    
    public let url: URL?
    public let previewUrl: URL?
    public let description: String?
    public let meta: MetaContainer?
    
    public static func imageWith(url: URL) -> MediaAttachment {
        .init(id: UUID().uuidString,
              type: "image",
              url: url,
              previewUrl: url,
              description: "Alternative text",
              meta: nil)
    }
}

extension MediaAttachment: Sendable {}
extension MediaAttachment.MetaContainer: Sendable {}
extension MediaAttachment.MetaContainer.Meta: Sendable {}
extension MediaAttachment.SupportedType: Sendable {}

public struct Mention: Codable, Equatable, Hashable {
    public let id: String
    public let username: String
    public let url: URL
    public let acct: String
}

extension Mention: Sendable {}

public struct Card: Codable, Identifiable, Equatable, Hashable {
    public var id: String {
        url
    }
    
    public let url: String
    public let title: String?
    public let description: String?
    public let type: String
    public let image: URL?
}

extension Card: Sendable {}

public struct Application: Codable, Identifiable, Hashable, Equatable, Sendable {
    public var id: String {
        name
    }
    
    public let name: String
    public let website: URL?
}

public extension Application {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
        website = try? values.decodeIfPresent(URL.self, forKey: .website)
    }
}

public struct Filtered: Codable, Equatable, Hashable {
    public let filter: Filter
    public let keywordMatches: [String]?
}

public struct Filter: Codable, Identifiable, Equatable, Hashable {
    public enum Action: String, Codable, Equatable {
        case warn, hide
    }
    
    public enum Context: String, Codable {
        case home, notifications, account, thread
        case pub = "public"
    }
    
    public let id: String
    public let title: String
    public let context: [String]
    public let filterAction: Action
}

extension Filtered: Sendable {}
extension Filter: Sendable {}
extension Filter.Action: Sendable {}
extension Filter.Context: Sendable {}

public struct Poll: Codable, Equatable, Hashable {
    public static func == (lhs: Poll, rhs: Poll) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public struct Option: Identifiable, Codable {
        enum CodingKeys: String, CodingKey {
            case title, votesCount
        }
        
        public var id = UUID().uuidString
        public let title: String
        public let votesCount: Int?
    }
    
    public let id: String
    public let expiresAt: NullableString
    public let expired: Bool
    public let multiple: Bool
    public let votesCount: Int
    public let votersCount: Int?
    public let voted: Bool?
    public let ownVotes: [Int]?
    public let options: [Option]
    
    // the votersCount can be null according to the docs when multiple is false.
    // Didn't find that to be true, but we make sure
    public var safeVotersCount: Int {
        votersCount ?? votesCount
    }
}

public struct NullableString: Codable, Equatable, Hashable {
    public let value: ServerDate?
    
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            value = try container.decode(ServerDate.self)
        } catch {
            value = nil
        }
    }
}

extension Poll: Sendable {}
extension Poll.Option: Sendable {}
extension NullableString: Sendable {}
