//Made by Lumaa

import SwiftUI

struct NotificationRow: View {    
    @State private var multiPeopleSheet: Bool = false
    
    var notif: GroupedNotification
    var showIcon: Bool = true
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                if let acc = notif.accounts.first {
                    if notif.accounts.count == 1 {
                        ProfilePicture(url: acc.avatar, size: 60)
                            .padding(.trailing)
                            .overlay(alignment: .bottomTrailing) {
                                if showIcon {
                                    notifIcon()
                                        .offset(x: -5, y: 5)
                                }
                            }
                            .padding(.horizontal, 10)
                            .onTapGesture {
                                Navigator.shared.navigate(to: .account(acc: acc))
                            }
                    } else {
                        accountCount()
                            .padding(.trailing)
                            .overlay(alignment: .bottomTrailing) {
                                if showIcon {
                                    notifIcon()
                                        .offset(x: -5, y: 5)
                                }
                            }
                            .padding(.horizontal, 10)
                            .onTapGesture {
                                multiPeopleSheet.toggle()
                            }
                    }
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
                        
                        
                        HStack(spacing: 7.5) {
                            if notif.status!.mediaAttachments.count > 0 {
                                Label("activity.status.attachments-\(notif.status!.mediaAttachments.count)", systemImage: notif.status!.mediaAttachments.count > 1 ? "photo.on.rectangle.angled" : "photo")
                                    .multilineTextAlignment(.leading)
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1, reservesSpace: false)
                            }
                            
                            Spacer()
                            
                            Text(notif.notifications[0].createdAt.relativeFormatted)
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .lineLimit(1, reservesSpace: false)
                        }
                    } else {
                        if let acc = notif.accounts.first {
                            TextEmoji(acc.note, emojis: acc.emojis)
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .lineLimit(3, reservesSpace: true)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Navigator.shared.navigate(to: notif.status == nil ? .account(acc: notif.accounts.first!) : .post(status: notif.status!))
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $multiPeopleSheet) {
                users
                    .presentationDetents([.height(200), .medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(25)
                    .scrollBounceBehavior(.basedOnSize)
            }
        }
    }
    
    var users: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .listRowSeparatorLeading) {
                ForEach(notif.accounts) { acc in
                    HStack {
                        ProfilePicture(url: acc.avatar, size: 60)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text(acc.displayName ?? acc.username)
                                .font(.body.bold())
                            Text("@\(acc.acct)")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    .onTapGesture {
                        multiPeopleSheet.toggle()
                        Navigator.shared.navigate(to: .account(acc: acc))
                    }
                }
            }
            .padding(.top)
        }
    }
    
    private func localizedString() -> LocalizedStringKey {
        var nameStr: String = ""
        if notif.accounts.count > 1, let acc = notif.accounts.first {
            nameStr = String(localized: "activity.group.\("@" + acc.username)-\(notif.accounts.count - 1)")
        } else if let acc = notif.accounts.first {
            nameStr = "@\(acc.username)"
        }
        
        switch (notif.type) {
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
            case .update:
                return "activity.update.\(nameStr)"
            case .poll:
                return "activity.poll.\(nameStr)"
            default:
                return "activity.unknown" // follow requests
        }
    }
    
    private func notifColor() -> Color {
        switch (notif.type) {
            case .favourite:
                return Color.red
            case .follow:
                return Color.purple
            case .mention:
                return Color.blue
            case .reblog:
                return Color.orange
            case .status, .update: // update and post are techn. the same
                return Color.yellow
            case .poll:
                return Color.green
            default:
                return Color.gray
        }
    }
    
    @ViewBuilder
    private func notifIcon() -> some View {
        let size: CGFloat = 60.0 / 4.0
        
        ZStack {
            switch (notif.type) {
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
                case .update:
                    Image(systemName: "pencil.and.scribble")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                case .poll:
                    Image(systemName: "checklist")
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
    
    @ViewBuilder
    private func accountCount() -> some View {
        ZStack {
            Text(String("+\(notif.accounts.count - 1)"))
                .font(.body)
                .scaledToFit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 30, height: 30)
        }
        .frame(width: 40, height: 40)
        .padding(7)
        .background(Color.gray)
        .clipShape(.circle)
        .overlay {
            Circle()
                .stroke(Color.appBackground, lineWidth: 3)
        }
        .fixedSize()
    }
}
