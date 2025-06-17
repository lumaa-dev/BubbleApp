//Made by Lumaa

import SwiftUI

struct ContactRow: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    var cont: MessageContact = .placeholder()
    @State private var multiPeopleSheet: Bool = false
    
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
                            multiPeopleSheet.toggle()
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
                            Navigator.shared.navigate(to: .account(acc: cont.accounts[0]))
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
                    guard let client = accountManager.getClient() else { return }
                    
                    if cont.unread {
                        Task {
                            do {
                                _ = try await client.post(endpoint: Conversations.read(id: cont.id))
                            } catch {
                                print(error)
                            }
                        }
                    }
                    
                    Navigator.shared.navigate(to: cont.lastStatus == nil ? .account(acc: cont.accounts[0]) : .post(status: cont.lastStatus!))
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
                ForEach(cont.accounts) { acc in
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
