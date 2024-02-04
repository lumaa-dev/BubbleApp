//Made by Lumaa

import SwiftUI

struct NotificationRow: View {
    @EnvironmentObject private var navigator: Navigator
    
    var notif: Notification = .placeholder()
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                ProfilePicture(url: notif.account.avatar, size: 60)
                    .padding(.trailing)
                    .overlay(alignment: .bottomTrailing) {
                        notifIcon()
                            .offset(x: -5, y: 5)
                    }
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: notif.account))
                    }
                
                VStack(alignment: .leading) {
                    Text(localizedString())
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                        .lineLimit(2)
                    
                    if notif.status != nil {
                        TextEmoji(notif.status!.content, emojis: notif.status!.emojis)
                            .multilineTextAlignment(.leading)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                            .lineLimit(3, reservesSpace: true)
                    } else {
                        TextEmoji(notif.account.note, emojis: notif.account.emojis)
                            .multilineTextAlignment(.leading)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                            .lineLimit(3, reservesSpace: true)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    navigator.navigate(to: notif.status == nil ? .account(acc: notif.account) : .post(status: notif.status!))
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func localizedString() -> LocalizedStringKey {
        let nameStr = "@\(notif.account.username)"
        switch (notif.supportedType) {
            case .favourite:
                return "activity.favorite.\(nameStr)"
            case .follow:
                return "activity.followed.\(nameStr)"
            case .mention:
                return "activity.mentionned.\(nameStr)"
            case .reblog:
                return "activity.reblogged.\(nameStr)"
            case .status:
                return "activity.status.\(nameStr)"
            default:
                return "activity.unknown" // follow requests & polls
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
        let font: Font = .system(size: 12, weight: .regular, design: .monospaced)
        
        ZStack {
            switch (notif.supportedType) {
                case .favourite:
                    Image(systemName: "heart.fill")
                        .font(font)
                case .follow:
                    Image(systemName: "person.fill.badge.plus")
                        .font(font)
                case .mention:
                    Image(systemName: "tag.fill")
                        .font(font)
                case .reblog:
                    Image(systemName: "bolt.horizontal.fill")
                        .font(font)
                case .status:
                    Image(systemName: "text.badge.plus")
                        .font(font)
                default:
                    Image(systemName: "questionmark")
                        .font(font)
            }
        }
        .frame(minWidth: 30)
        .padding(7)
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
