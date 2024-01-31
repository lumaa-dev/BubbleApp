//Made by Lumaa

import SwiftUI

struct NotificationRow: View {
    var notif: Notification = .placeholder()
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                ProfilePicture(url: notif.account.avatar)
                    .padding(.trailing)
                    .overlay(alignment: .bottomTrailing) {
                        notifIcon()
                            .offset(x: -5, y: 5)
                    }
                    .padding()
                Text(localizedString())
            }
            .padding(.horizontal)
        }
    }
    
    private func localizedString() -> String {
        switch (notif.supportedType) {
            case .favourite:
                return String(localized: "activity.favorite.%@").replacingOccurrences(of: "%@", with: "@\(notif.account.username)")
            case .follow:
                return String(localized: "activity.followed.%@").replacingOccurrences(of: "%@", with: "@\(notif.account.username)")
            case .mention:
                return String(localized: "activity.mentionned.%@").replacingOccurrences(of: "%@", with: "@\(notif.account.username)")
            case .reblog:
                return String(localized: "activity.reblogged.%@").replacingOccurrences(of: "%@", with: "@\(notif.account.username)")
            case .status:
                return String(localized: "activity.status.%@").replacingOccurrences(of: "%@", with: "@\(notif.account.username)")
            default:
                return String(localized: "activity.unknown")
        }
    }
    
    private func notifColor() -> Color {
        switch (notif.supportedType) {
            case .favourite:
                return Color.red
            case .follow:
                return Color.purple
            case .mention:
                return Color.blue
            case .reblog:
                return Color.pink
            case .status:
                return Color.yellow
            default:
                return Color.gray
        }
    }
    
    @ViewBuilder
    private func notifIcon() -> some View {
        ZStack {
            switch (notif.supportedType) {
                case .favourite:
                    Image(systemName: "heart.fill")
                        .font(.caption)
                case .follow:
                    Image(systemName: "person.fill.badge.plus")
                        .font(.caption)
                case .mention:
                    Image(systemName: "tag.fill")
                        .font(.caption)
                case .reblog:
                    Image(systemName: "bolt.horizontal.fill")
                        .font(.caption)
                case .status:
                    Image(systemName: "text.badge.plus")
                        .font(.caption)
                default:
                    Image(systemName: "questionmark")
                        .font(.caption)
            }
        }
        .padding(5)
        .background(notifColor())
        .clipShape(.circle)
        .overlay {
            Circle()
                .stroke(Color.appBackground, lineWidth: 3)
        }
        .fixedSize()
    }
}

#Preview {
    NotificationRow()
}
