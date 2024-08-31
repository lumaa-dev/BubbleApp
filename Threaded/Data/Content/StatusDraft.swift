// Made by Lumaa

import Foundation
import SwiftData

@Model
class StatusDraft {
    var content: String
    var visibility: Visibility

    var hasPoll: Bool
    var pollOptions: [String]
    var pollMulti: Bool
    var pollExpire: Int

    init(
        content: String,
        visibility: Visibility,
        hasPoll: Bool = false,
        pollOptions: [String] = [],
        pollMulti: Bool = false,
        pollExpire: StatusData.PollData.DefaultExpiry = .oneDay
    ) {
        self.content = content
        self.visibility = visibility
        self.hasPoll = hasPoll
        self.pollOptions = pollOptions
        self.pollMulti = pollMulti
        self.pollExpire = pollExpire.rawValue
    }

    func setPoll(options: [String], multiselect: Bool, expiresIn: StatusData.PollData.DefaultExpiry = .oneDay) {
        self.setPoll(options: options, multiselect: multiselect, expiresIn: expiresIn.rawValue)
    }

    func setPoll(options: [String], multiselect: Bool, expiresIn: Int = StatusData.PollData.DefaultExpiry.oneDay.rawValue) {
        self.pollOptions = options
        self.pollMulti = multiselect
        self.pollExpire = expiresIn
    }

    static let empty: StatusDraft = .init(content: "", visibility: .pub)
}
