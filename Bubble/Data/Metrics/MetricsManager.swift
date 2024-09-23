// Made by Lumaa

import Foundation
import Charts

/// This gets metrics on the selected account from the ``Client``
final class MetricsManager {
    private var client: Client

    private var measured: Bool = false

    private(set) public var postCount: [IntData] = []
    private(set) public var postType: [StatusTypeData] = []

    init(accountManager: AccountManager) {
        if let cli = accountManager.getClient() {
            self.client = cli
        }
        fatalError("Account Manager doesn't have a Client bound")
    }

    init(client: Client) {
        self.client = client
    }

    /// Only gets the last few posts count AND ``StatusTypeData``
    private func getLastPosts() async -> ([IntData], [StatusTypeData]) {
        guard let accountDetail: Account = try? await self.client.get(endpoint: Accounts.verifyCredentials), let statusesCount: Int = accountDetail.statusesCount else {
            fatalError("Couldn't verify creds for Metrics")
        }

        if let posts: [Status] = try? await self.client.get(
            endpoint: Accounts.statuses(id: accountDetail.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil)
        ) {
            var countData: [IntData] = []
            var typeData: [StatusTypeData] = []

            posts.reversed().forEach { post in // go through posts backwards
                let i: Int = posts.firstIndex(of: post) ?? -1 // latest post is first, oldest is last

                let newCountData: IntData = .init(date: post.createdAt.asDate, count: statusesCount - i, fullCount: statusesCount)
                let newTypeData: StatusTypeData = .init(date: post.createdAt.asDate, type: post.getType())

                countData.append(newCountData)
                typeData.append(newTypeData)
            }

            return (countData, typeData)
        } else {
            fatalError("Couldn't fetch account's statuses")
        }
    }

    /// Data used for integer Metrics
    struct IntData: GraphData {
        let date: Date
        let count: Int
        let fullCount: Int

        var difference: Int {
            fullCount - count
        }

        var plottableCount: PlottableValue<Int> {
            .value(String(localized: "metrics.status.count"), count)
        }

        init(date: Date, count: Int, fullCount: Int) {
            self.date = date
            self.count = count
            self.fullCount = fullCount
        }
    }

    struct StatusTypeData: GraphData {
        let date: Date
        let type: Status.StatusType

        var label: String {
            self.type.localized
        }

        var plottableType: PlottableValue<String> {
            .value(String(localized: "metrics.status.count"), label)
        }

        init(date: Date, type: Status.StatusType) {
            self.date = date
            self.type = type
        }
    }

    protocol GraphData {
        var date: Date { get }
    }
}

extension MetricsManager.GraphData {
    var plottableDate: PlottableValue<Date> {
        .value(String(localized: "metrics.any.date"), date)
    }
}

// MARK: - Status Type
extension Status {
    func getType() -> Status.StatusType {
        let isReply: Bool = self.inReplyToId != nil
        let isDirect: Bool = self.visibility == .direct

        if !isReply && !isDirect {
            return Self.StatusType.post
        } else if isReply && !isDirect {
            return Self.StatusType.reply
        } else if !isReply && isDirect {
            return Self.StatusType.direct
        } else if isReply && isDirect {
            return Self.StatusType.directReply
        }
        return Self.StatusType.post
    }

    enum StatusType {
        case post
        case reply
        case direct
        case directReply
        case unknown

        var localized: String {
            switch self {
                case .post:
                    String(localized: "status.type.post")
                case .reply:
                    String(localized: "status.type.reply")
                case .direct:
                    String(localized: "status.type.direct")
                case .directReply:
                    String(localized: "status.type.direct-reply")
                default:
                    String(localized: "status.type.unknown")
            }
        }
    }
}
