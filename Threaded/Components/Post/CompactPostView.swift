//Made by Lumaa

import SwiftUI

struct CompactPostView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State var status: Status
    @ObservedObject var navigator: Navigator
    
    var pinned: Bool = false
    var detailed: Bool = false
    var quoted: Bool = false
    var imaging: Bool = false
    
    @State private var preferences: UserPreferences = .defaultPreferences
    @State private var initialLike: Bool = false
    
    @State private var isLiked: Bool = false
    @State private var isReposted: Bool = false
    @State private var isBookmarked: Bool = false
    
    @State private var hasQuote: Bool = false
    @State private var quoteStatus: Status? = nil
    
    var body: some View {
        VStack {
            notices
            
            statusPost(status.reblogAsAsStatus ?? status)
            
            if !quoted && !imaging {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: .infinity, height: 1)
                    .padding(.bottom, 3)
            }
        }
        .onAppear {
            do {
                preferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
            } catch {
                print(error)
            }
            
            initialLike = isLiked
        }
        .task {
            await loadEmbeddedStatus(status: status)
            
            if let client = accountManager.getClient() {
                if let newStatus: Status = try? await client.get(endpoint: Statuses.status(id: status.reblog?.id ?? status.id)) {
                    status = newStatus
                }
            }
        }
    }
    
    @ViewBuilder
    func statusPost(_ status: Status) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: Profile picture
            if status.repliesCount > 0 && preferences.experimental.replySymbol {
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.account.username)
                            .font(quoted ? .callout : .body)
                            .multilineTextAlignment(.leading)
                            .bold()
                            .onTapGesture {
                                navigator.navigate(to: .account(acc: status.account))
                            }
                        
                        if status.inReplyToAccountId != nil {
                            if let user = status.mentions.first(where: { $0.id == status.inReplyToAccountId }) {
                                Text("status.replied-to.\(user.username)")
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
                            }
                        }
                    }
                    
                    if !status.content.asRawText.isEmpty {
                        TextEmoji(status.content, emojis: status.emojis, language: status.language)
                            .multilineTextAlignment(.leading)
                            .frame(width: quoted ? 250 : 300, alignment: .topLeading)
                            .lineLimit(quoted ? 3 : nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(quoted ? .caption : .callout)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                navigator.navigate(to: .post(status: status))
                            }
                    }
                    
                    if status.card != nil && status.mediaAttachments.isEmpty && !hasQuote {
                        PostCardView(card: status.card!)
                    }
                    
                    if !status.mediaAttachments.isEmpty {
                        if status.mediaAttachments.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    ForEach(status.mediaAttachments) { attachment in
                                        PostAttachment(attachment: attachment, isFeatured: false, isImaging: imaging)
                                    }
                                }
                            }
                            .scrollClipDisabled()
                        } else {
                            PostAttachment(attachment: status.mediaAttachments.first!, isImaging: imaging)
                        }
                    }
                    
                    if hasQuote {
                        if quoteStatus != nil {
                            QuotePostView(status: quoteStatus!)
                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
                
                //MARK: Action buttons
                if !quoted && !imaging {
                    PostInteractor(status: status.reblogAsAsStatus ?? status, isLiked: $isLiked, isReposted: $isReposted, isBookmarked: $isBookmarked)
                }
                
                // MARK: Status stats
                stats.padding(.top, 5)
            }
            
//            if !imaging {
//                PostMenu(status: status)
//                    .padding([.trailing, .top])
//                    .contentShape(Rectangle())
//            }
        }
    }
    
    var notices: some View {
        ZStack {
            if pinned {
                HStack (alignment:.center, spacing: 5) {
                    Image(systemName: "pin.fill")
                    
                    Text("status.pinned")
                }
                .padding(.leading, 20)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
                .padding(.leading, 35)
            }
            
            if status.reblog != nil {
                HStack (alignment:.center, spacing: 5) {
                    Image(systemName: "bolt.horizontal")
                    
                    Text("status.reposted-by.\(status.account.username)")
                }
                .padding(.leading, 20)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
                .padding(.leading, 30)
            }
        }
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
                        .font(quoted ? .caption : .callout)
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
                        .font(quoted ? .caption : .callout)
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
                        .font(quoted ? .caption : .callout)
                }
                
                if status.reblog!.repliesCount > 0 && (status.reblog!.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                        .font(quoted ? .caption : .callout)
                }
                
                if status.reblog!.favouritesCount > 0 || isLiked {
                    let likeCount: Int = status.reblog!.favouritesCount - (initialLike ? 1 : 0)
                    let incrLike: Int = isLiked ? 1 : 0
                    Text("status.favourites-\(likeCount + incrLike)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText(value: Double(likeCount + incrLike)))
                        .font(quoted ? .caption : .callout)
                        .transaction { t in
                            t.animation = .default
                        }
                }
            }
        }
    }
    
    private func embededStatusURL(_ status: Status) -> URL? {
        let content = status.content
        if let client = accountManager.getClient() {
            if !content.statusesURLs.isEmpty, let url = content.statusesURLs.first, client.hasConnection(with: url) {
                return url
            }
        }
        return nil
    }
    
    func loadEmbeddedStatus(status: Status) async {
        guard let url = embededStatusURL(status), let client = accountManager.getClient() else { hasQuote = false; return }
        
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
}
