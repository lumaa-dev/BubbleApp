//Made by Lumaa

import SwiftUI

struct NotificationRow: View {
    @EnvironmentObject private var navigator: Navigator
    
    var notif: Notification = .placeholder()
    var showIcon: Bool = true
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                ProfilePicture(url: notif.account.avatar, size: 60)
                    .padding(.trailing)
                    .overlay(alignment: .bottomTrailing) {
                        if showIcon {
                            notifIcon()
                                .offset(x: -5, y: 5)
                        }
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
                        
                        if notif.status!.mediaAttachments.count > 0 {
                            Label("activity.status.attachments-\(notif.status!.mediaAttachments.count)", systemImage: "photo.on.rectangle.angled")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .lineLimit(1, reservesSpace: false)
                        }
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
                return Color.orange
            case .status:
                return Color.yellow
            default:
                return Color.gray
        }
    }
    
    @ViewBuilder
    private func notifIcon() -> some View {
        let size: CGFloat = 60.0 / 4.0
        
        ZStack {
            switch (notif.supportedType) {
                case .favourite:
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                case .follow:
                    Image(systemName: "person.fill.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                case .mention:
                    Image(systemName: "tag.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                case .reblog:
                    Image(systemName: "bolt.horizontal.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                case .status:
                    Image(systemName: "text.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                default:
                    Image(systemName: "questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
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
