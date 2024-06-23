//Made by Lumaa

import SwiftUI

struct PostInteractor: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(UniversalNavigator.self) private var navigator
    
    var status: Status
    
    @Binding var isLiked: Bool
    @Binding var isReposted: Bool
    @Binding var isBookmarked: Bool
    
    var body: some View {
        ViewThatFits {
            HStack(spacing: 13) {
                asyncActionButton(isLiked ? "heart.fill" : "heart", color: isLiked ? Color.pink : Color(uiColor: UIColor.label)) {
                    do {
                        HapticManager.playHaptics(haptics: Haptic.tap)
                        try await likePost()
                    } catch {
                        HapticManager.playHaptics(haptics: Haptic.error)
                        print("Error: \(error.localizedDescription)")
                    }
                }
                actionButton("bubble.right") {
                    navigator.presentedSheet = .post(content: "@\(status.account.acct)", replyId: status.id)
                }
                asyncActionButton(isReposted ? "bolt.horizontal.fill" : "bolt.horizontal") {
                    do {
                        HapticManager.playHaptics(haptics: Haptic.tap)
                        try await repostPost()
                    } catch {
                        HapticManager.playHaptics(haptics: Haptic.error)
                        print("Error: \(error.localizedDescription)")
                    }
                }
                asyncActionButton(isBookmarked ? "bookmark.fill" : "bookmark") {
                    do {
                        HapticManager.playHaptics(haptics: Haptic.tap)
                        try await bookmarkPost()
                    } catch {
                        HapticManager.playHaptics(haptics: Haptic.error)
                        print("Error: \(error.localizedDescription)")
                    }
                }
                
                Spacer()
                
                ShareLink(item: URL(string: status.url ?? "https://joinmastodon.org/")!) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22))
                        .padding(.horizontal)
                }
                .tint(Color(uiColor: UIColor.label))
            }
            
            HStack(spacing: 13) {
                asyncActionButton(isLiked ? "heart.fill" : "heart", color: isLiked ? Color.pink : Color(uiColor: UIColor.label)) {
                    do {
                        HapticManager.playHaptics(haptics: Haptic.tap)
                        try await likePost()
                    } catch {
                        HapticManager.playHaptics(haptics: Haptic.error)
                        print("Error: \(error.localizedDescription)")
                    }
                }
                actionButton("bubble.right") {
                    navigator.presentedSheet = .post(content: "@\(status.account.acct)", replyId: status.id)
                }
                asyncActionButton(isReposted ? "bolt.horizontal.fill" : "bolt.horizontal") {
                    do {
                        HapticManager.playHaptics(haptics: Haptic.tap)
                        try await repostPost()
                    } catch {
                        HapticManager.playHaptics(haptics: Haptic.error)
                        print("Error: \(error.localizedDescription)")
                    }
                }
                asyncActionButton(isBookmarked ? "bookmark.fill" : "bookmark") {
                    do {
                        HapticManager.playHaptics(haptics: Haptic.tap)
                        try await bookmarkPost()
                    } catch {
                        HapticManager.playHaptics(haptics: Haptic.error)
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
        .padding(.top)
        .onAppear {
            syncInteractors(status: status)
        }
    }
    
    func syncInteractors(status: Status) {
        isLiked = status.reblog != nil ? status.reblog!.favourited ?? false : status.favourited ?? false
        isReposted = status.reblog != nil ? status.reblog!.reblogged ?? false : status.reblogged ?? false
        isBookmarked = status.reblog != nil ? status.reblog!.bookmarked ?? false : status.bookmarked ?? false
    }
    
    func likePost() async throws {
        if let client = accountManager.getClient() {
            guard client.isAuth else { fatalError("Client is not authenticated") }
            let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
            let endpoint = !isLiked ? Statuses.favorite(id: statusId) : Statuses.unfavorite(id: statusId)
            
            isLiked = !isLiked
            let newStatus: Status = try await client.post(endpoint: endpoint)
            syncInteractors(status: newStatus)
        }
    }
    
    func repostPost() async throws {
        if let client = accountManager.getClient() {
            guard client.isAuth else { fatalError("Client is not authenticated") }
            let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
            let endpoint = !isReposted ? Statuses.reblog(id: statusId) : Statuses.unreblog(id: statusId)
            
            isReposted = !isReposted
            let newStatus: Status = try await client.post(endpoint: endpoint)
            syncInteractors(status: newStatus)
        }
    }
    
    func bookmarkPost() async throws {
        if let client = accountManager.getClient() {
            guard client.isAuth else { fatalError("Client is not authenticated") }
            let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
            let endpoint = !isBookmarked ? Statuses.bookmark(id: statusId) : Statuses.unbookmark(id: statusId)
            
            isBookmarked = !isBookmarked
            let newStatus: Status = try await client.post(endpoint: endpoint)
            syncInteractors(status: newStatus)
        }
    }
    
    @ViewBuilder
    func actionButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: image)
                .font(.system(size: 22))
        }
        .tint(Color(uiColor: UIColor.label))
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    func asyncActionButton(_ image: String, action: @escaping () async -> Void) -> some View {
        asyncActionButton(image, color: Color(uiColor: UIColor.label), action: action)
    }
    
    @ViewBuilder
    func asyncActionButton(_ image: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Image(systemName: image)
                .font(.system(size: 22))
                .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
        }
        .tint(color)
        .contentShape(Rectangle())
    }
}

#Preview {
    CompactPostView(status: .placeholder())
        .environment(Navigator())
        .environment(UserPreferences.defaultPreferences)
        .environment(UniversalNavigator())
        .environment(AccountManager.shared)
}
