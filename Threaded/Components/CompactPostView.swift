//Made by Lumaa

import SwiftUI

struct CompactPostView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    var status: Status
    @ObservedObject var navigator: Navigator
    var pinned: Bool = false
    
    @State private var initialLike: Bool = false
    @State private var isLiked: Bool = false
    @State private var isReposted: Bool = false
    @State private var hasQuote: Bool = false
    @State private var quoteStatus: Status? = nil
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                if pinned {
                    pinnedNotice
                        .padding(.leading, 35)
                }
                
                if status.reblog != nil {
                    repostNotice
                        .padding(.leading, 30)
                }
                
                statusPost(status.reblog ?? status)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: .infinity, height: 1)
                .padding(.bottom, 3)
        }
        .onAppear {
            isLiked = status.reblog != nil ? status.reblog!.favourited ?? false : status.favourited ?? false
            initialLike = isLiked
            isReposted = status.reblog != nil ? status.reblog!.reblogged ?? false : status.reblogged ?? false
            
            let likeCount: Int = status.favouritesCount - (initialLike ? 1 : 0)
            let incrLike: Int = isLiked ? 1 : 0
            print("original: \(status.favouritesCount)\nmin1: \(likeCount)\nincr1: \(likeCount + incrLike)")
        }
        .task {
            await loadEmbeddedStatus()
        }
    }
    
    func likePost() async throws {
        if let client = accountManager.getClient() {
            guard client.isAuth else { fatalError("Client is not authenticated") }
            let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
            let endpoint = !isLiked ? Statuses.favorite(id: statusId) : Statuses.unfavorite(id: statusId)
            
            isLiked = !isLiked
            let newStatus: Status = try await client.post(endpoint: endpoint)
            if isLiked != newStatus.favourited {
                isLiked = newStatus.favourited ?? !isLiked
            }
        }
    }
    
    func repostPost() async throws {
        if let client = accountManager.getClient() {
            guard client.isAuth else { fatalError("Client is not authenticated") }
            let statusId: String = status.reblog != nil ? status.reblog!.id : status.id
            let endpoint = !isReposted ? Statuses.reblog(id: statusId) : Statuses.unreblog(id: statusId)
            
            isReposted = !isReposted
            let newStatus: Status = try await client.post(endpoint: endpoint)
            if isReposted != newStatus.reblogged {
                isReposted = newStatus.reblogged ?? !isReposted
            }
        }
    }
    
    @ViewBuilder
    func statusPost(_ status: AnyStatus) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: Profile picture
            if status.repliesCount > 0 {
                VStack {
                    profilePicture
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.account))
                        }
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2.5)
                        .clipShape(.capsule)
                        .padding([.vertical], 5)
                    
                    Spacer()
                    
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .padding(.bottom, 2.5)
                }
            } else {
                profilePicture
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: status.account))
                    }
            }
            
            VStack(alignment: .leading) {
                // MARK: Status main content
                VStack(alignment: .leading, spacing: 10) {
                    Text(status.account.username)
                        .multilineTextAlignment(.leading)
                        .bold()
                        .onTapGesture {
                            navigator.navigate(to: .account(acc: status.account))
                        }
                    
                    if !status.content.asRawText.isEmpty {
                        TextEmoji(status.content, emojis: status.emojis, language: status.language)
                            .multilineTextAlignment(.leading)
                            .frame(width: 300, alignment: .topLeading)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                    }
                    
                    if status.card != nil {
                        PostCardView(card: status.card!)
                    }
                    
//                    if hasQuote {
//                        if quoteStatus != nil {
//                            QuotePostView(status: quoteStatus!)
//                        } else {
//                            ProgressView()
//                                .progressViewStyle(.circular)
//                        }
//                    }
                }
                
                //MARK: Action buttons
                HStack(spacing: 13) {
                    asyncActionButton(isLiked ? "heart.fill" : "heart") {
                        do {
                            try await likePost()
                            HapticManager.playHaptics(haptics: Haptic.tap)
                        } catch {
                            HapticManager.playHaptics(haptics: Haptic.error)
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    actionButton("bubble.right") {
                        print("reply")
                        navigator.presentedSheet = .post()
                    }
                    asyncActionButton(isReposted ? "bolt.horizontal.fill" : "bolt.horizontal") {
                        do {
                            try await repostPost()
                            HapticManager.playHaptics(haptics: Haptic.tap)
                        } catch {
                            HapticManager.playHaptics(haptics: Haptic.error)
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                    ShareLink(item: URL(string: status.url ?? "https://joinmastodon.org/")!) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                    .tint(Color(uiColor: UIColor.label))
                }
                .padding(.top)
                
                // MARK: Status stats
                stats.padding(.top, 5)
            }
        }
    }
    
    var pinnedNotice: some View {
        HStack (alignment:.center, spacing: 5) {
            Image(systemName: "pin.fill")
            
            Text("status.pinned")
        }
        .padding(.leading, 20)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .font(.caption)
        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
    }
    
    var repostNotice: some View {
        HStack (alignment:.center, spacing: 5) {
            Image(systemName: "bolt.horizontal")
            
            Text("status.reposted-by.\(status.account.username)")
        }
        .padding(.leading, 20)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .font(.caption)
        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
    }
    
    var profilePicture: some View {
        if status.reblog != nil {
            OnlineImage(url: status.reblog!.account.avatar, size: 50, useNuke: true)
                .frame(width: 40, height: 40)
                .padding(.horizontal)
                .clipShape(.circle)
        } else {
            OnlineImage(url: status.account.avatar, size: 50, useNuke: true)
                .frame(width: 40, height: 40)
                .padding(.horizontal)
                .clipShape(.circle)
        }
    }
    
    var stats: some View {
        //MARK: I acknowledge the existance of a count bug here
        if status.reblog == nil {
            HStack {
                if status.repliesCount > 0 {
                    Text("status.replies-\(status.repliesCount)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
                
                if status.repliesCount > 0 && (status.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                }
                
                if status.favouritesCount > 0 || isLiked {
                    let likeCount: Int = status.favouritesCount - (initialLike ? 1 : 0)
                    let incrLike: Int = isLiked ? 1 : 0
                    Text("status.favourites-\(likeCount + incrLike)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText(value: Double(likeCount + incrLike)))
                        .transaction { t in
                            t.animation = .default
                        }
                }
            }
        } else {
            HStack {
                if status.reblog!.repliesCount > 0 {
                    Text("status.replies-\(status.reblog!.repliesCount)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
                
                if status.reblog!.repliesCount > 0 && (status.reblog!.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                }
                
                if status.reblog!.favouritesCount > 0 || isLiked {
                    let likeCount: Int = status.reblog!.favouritesCount - (initialLike ? 1 : 0)
                    let incrLike: Int = isLiked ? 1 : 0
                    Text("status.favourites-\(likeCount + incrLike)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText(value: Double(likeCount + incrLike)))
                        .transaction { t in
                            t.animation = .default
                        }
                }
            }
        }
    }
    
    private func embededStatusURL() -> URL? {
        let content = status.content
        if let client = accountManager.getClient() {
            if !content.statusesURLs.isEmpty, let url = content.statusesURLs.first, client.hasConnection(with: url) {
                return url
            }
        }
        return nil
    }
    
    func loadEmbeddedStatus() async {
        guard let url = embededStatusURL(), let client = accountManager.getClient() else { hasQuote = false; return }
        
        do {
            hasQuote = true
            if url.absoluteString.contains(client.server), let id = Int(url.lastPathComponent) {
                quoteStatus = try await client.get(endpoint: Statuses.status(id: String(id)))
            } else {
                let results: SearchResults = try await client.get(endpoint: Search.search(query: url.absoluteString, type: "statuses", offset: 0, following: nil), forceVersion: .v2)
                quoteStatus = results.statuses.first
            }
        } catch {
            hasQuote = false
            quoteStatus = nil
        }
    }
    
    @ViewBuilder
    func actionButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: image)
                .font(.title2)
        }
        .tint(Color(uiColor: UIColor.label))
    }
    
    @ViewBuilder
    func asyncActionButton(_ image: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Image(systemName: image)
                .font(.title2)
        }
        .tint(Color(uiColor: UIColor.label))
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(Status.placeholders()) { status in
                CompactPostView(status: status, navigator: Navigator())
                    .environment(Client.init(server: AppInfo.defaultServer))
            }
        }
    }
}
