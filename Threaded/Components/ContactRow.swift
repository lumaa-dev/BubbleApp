//Made by Lumaa

import SwiftUI

struct ContactRow: View {
    @EnvironmentObject private var navigator: Navigator
    
    var cont: MessageContact = .placeholder()
    
    private var title: String {
        let named = cont.accounts.map { $0.displayName }
        let stringed = named.map { $0 == named.first ? "\($0!)" : ", \($0!)" }.joined()
        return stringed
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                if cont.accounts.count > 1 {
                    ProfilePicture(url: cont.accounts[0].avatar, size: 60)
                        .padding(.trailing)
                        .overlay(alignment: .bottomTrailing) {
                            ProfilePicture(url: cont.accounts[1].avatar, size: 35)
                                .clipShape(.circle)
                                .overlay {
                                    Circle()
                                        .stroke(Color.appBackground, lineWidth: 3)
                                }
                                .fixedSize()
                                .offset(x: -5, y: 5)
                        }
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            // open sheet to select proper account
                        }
                } else {
                    ProfilePicture(url: cont.accounts[0].avatar, size: 60)
                        .padding(.trailing)
                        .overlay(alignment: .bottomTrailing) {
                            notifIcon()
                                .offset(x: -5, y: 5)
                        }
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: cont.accounts[0]))
                        }
                }
                
                VStack(alignment: .leading) {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    
                    if cont.lastStatus != nil {
                        TextEmoji(cont.lastStatus!.content, emojis: cont.lastStatus!.emojis)
                            .multilineTextAlignment(.leading)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                            .lineLimit(3, reservesSpace: true)
                        
                        if cont.lastStatus!.mediaAttachments.count > 0 {
                            Label("activity.status.attachments-\(cont.lastStatus!.mediaAttachments.count)", systemImage: "photo.on.rectangle.angled")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .lineLimit(1, reservesSpace: false)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    navigator.navigate(to: cont.lastStatus == nil ? .account(acc: cont.accounts[0]) : .post(status: cont.lastStatus!))
                }
                
                if cont.unread {
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(cont.unread ? Color.gray.opacity(0.3) : Color.appBackground)
        }
    }
    
    @ViewBuilder
    private func notifIcon() -> some View {
        let size: CGFloat = 60.0 / 4.0
        
        ZStack {
            Image(systemName: "tray.full")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .frame(minWidth: 30)
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
