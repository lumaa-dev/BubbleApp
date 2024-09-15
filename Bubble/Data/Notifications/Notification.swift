//Made by Lumaa

import Foundation

public struct Notification: Decodable, Identifiable, Equatable {
    public enum NotificationType: String, CaseIterable {
        case follow, follow_request, mention, reblog, status, favourite, poll, update
    }
    
    public let id: String
    public let type: String
    public let createdAt: ServerDate
    public let account: Account
    public let status: Status?
    
    public var supportedType: NotificationType? {
        .init(rawValue: type)
    }
    
    public static func placeholder() -> Notification {
        .init(id: UUID().uuidString,
              type: NotificationType.favourite.rawValue,
              createdAt: ServerDate(),
              account: .placeholder(),
              status: .placeholder())
    }
}

extension Notification: Sendable {}
extension Notification.NotificationType: Sendable {}

extension [Notification] {
    public func toGrouped() -> [GroupedNotification] {
        var groupedNotifications: [GroupedNotification] = []
        
        for notification in self {
            if let existingIndex = groupedNotifications.firstIndex(where: { $0.type == notification.supportedType && $0.timeDifference(with: notification) >= GroupedNotification.groupHours && $0.status == notification.status }) {
                // If a group with the same type exists, add the notification to that group
                groupedNotifications[existingIndex].notifications.append(notification)
                groupedNotifications[existingIndex].accounts.append(notification.account)
                groupedNotifications[existingIndex].accounts = groupedNotifications[existingIndex].accounts.uniqued()
            } else {
                // If no group with the same type exists, create a new group
                groupedNotifications.append(GroupedNotification(notifications: [notification], type: notification.supportedType ?? .favourite))
            }
        }
        
        return groupedNotifications
    }
}

public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public struct GroupedNotification: Identifiable, Hashable {
    public var id: String? { notifications.first?.id }
    public var notifications: [Notification]
    public let type: Notification.NotificationType
    public var accounts: [Account]
    public let status: Status?
    
    public static let groupHours: Int = -5 // all notifications 5 hours away from first
    
    init(notifications: [Notification], type: Notification.NotificationType, accounts: [Account], status: Status?) {
        self.notifications = notifications
        self.type = type
        self.accounts = accounts
        self.status = status
    }
    
    init(notifications: [Notification], type: Notification.NotificationType) {
        if let firstNotif = notifications.first {
            if let maxType = Calendar.current.date(byAdding: .hour, value: GroupedNotification.groupHours, to: firstNotif.createdAt.asDate) {
                let filtered = notifications.filter({ $0.supportedType == type && $0.createdAt.asDate >= maxType })
                let timed = filtered.sorted(by: { $0.createdAt.asDate > $1.createdAt.asDate })
                
                self.notifications = timed
                self.accounts = timed.map({ $0.account })
                self.status = firstNotif.status
            } else {
                self.notifications = []
                self.accounts = []
                self.status = nil
            }
        } else {
            self.notifications = []
            self.accounts = []
            self.status = nil
        }
        
        self.type = type
    }
    
    func timeDifference(with notification: Notification) -> Int {
        guard let firstNotificationDate = notifications.first?.createdAt.asDate else {
            return 0
        }
        
        let timeDifference = Calendar.current.dateComponents([.hour, .minute], from: firstNotificationDate, to: notification.createdAt.asDate)
        return timeDifference.hour ?? 0 // Get the time difference in hours
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
