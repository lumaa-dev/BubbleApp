//Made by Lumaa

import SwiftUI

struct PostDetailsView: View {
    @Environment(Navigator.self) private var navigator: Navigator
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    var detailedStatus: Status
    
    @State private var statuses: [Status] = []
    @State private var scrollId: String? = nil
    @State private var initialLike: Bool = false
    
    @State private var isLiked: Bool = false
    @State private var isReposted: Bool = false
    @State private var isBookmarked: Bool = false
    
    @State private var hasQuote: Bool = false
    @State private var quoteStatus: Status? = nil
    
    init(status: Status) {
        self.detailedStatus = status
    }
    
    var body: some View {
        ScrollView(.vertical) {
            ScrollViewReader { proxy in
                VStack(alignment: .leading) {
                    if statuses.isEmpty {
                        statusPost(detailedStatus)
                        
//                        Spacer()
                    } else {
                        ForEach(statuses) { status in
                            if status.id == detailedStatus.id {
                                statusPost(detailedStatus)
                                    .padding(.horizontal, 15)
                                    .padding(statuses.first!.id == detailedStatus.id ? .bottom : .vertical)
                                    .onAppear {
                                        proxy.scrollTo("\(detailedStatus.id)@\(detailedStatus.account.id)", anchor: .bottom)
                                    }
                            } else {
                                CompactPostView(status: status, navigator: navigator)
                            }
                        }
                    }
                }
                .task {
                    await fetchStatusDetail()
                }
            }
        }
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .safeAreaPadding()
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func statusPost(_ status: AnyStatus) -> some View {
        VStack(alignment: .leading) {
            HStack {
                profilePicture
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: status.account))
                    }
                
                Text(status.account.username)
                    .multilineTextAlignment(.leading)
                    .bold()
                    .onTapGesture {
                        navigator.navigate(to: .account(acc: status.account))
                    }
            }
            
            VStack(alignment: .leading) {
                // MARK: Status main content
                VStack(alignment: .leading, spacing: 10) {
                    if !status.content.asRawText.isEmpty {
                        TextEmoji(status.content, emojis: status.emojis, language: status.language)
                            .multilineTextAlignment(.leading)
                            .frame(width: 300, alignment: .topLeading)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                            .id("\(detailedStatus.id)@\(detailedStatus.account.id)")
                    }
                    
                    if status.card != nil && status.mediaAttachments.isEmpty {
                        PostCardView(card: status.card!)
                    }
                    
                    if !status.mediaAttachments.isEmpty {
                        ForEach(status.mediaAttachments) { attachment in
                            PostAttachment(attachment: attachment)
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
                PostInteractor(status: status as! Status, isLiked: $isLiked, isReposted: $isReposted, isBookmarked: $isBookmarked)
                
                // MARK: Status stats
                stats.padding(.top, 5)
            }
        }
    }
    
    private func fetchStatusDetail() async {
        guard let client = accountManager.getClient() else { return }
        do {
            let data = try await fetchContextData(client: client, statusId: detailedStatus.id)
            
            var statusesContext = data.context.ancestors
            statusesContext.append(data.status)
            statusesContext.append(contentsOf: data.context.descendants)
            
            statuses = statusesContext
        } catch {
            if let error = error as? ServerError, error.httpCode == 404 {
                _ = navigator.path.popLast()
            }
        }
    }
    
    private func fetchContextData(client: Client, statusId: String) async throws -> ContextData {
        async let status: Status = client.get(endpoint: Statuses.status(id: statusId))
        async let context: StatusContext = client.get(endpoint: Statuses.context(id: statusId))
        return try await .init(status: status, context: context)
    }
    
    struct ContextData {
        let status: Status
        let context: StatusContext
    }
    
    var profilePicture: some View {
        if detailedStatus.reblog != nil {
            OnlineImage(url: detailedStatus.reblog!.account.avatar, size: 50, useNuke: true)
                .frame(width: 40, height: 40)
                .padding(.trailing)
                .clipShape(.circle)
        } else {
            OnlineImage(url: detailedStatus.account.avatar, size: 50, useNuke: true)
                .frame(width: 40, height: 40)
                .padding(.trailing)
                .clipShape(.circle)
        }
    }
    
    var stats: some View {
        //MARK: I acknowledge the existance of a count bug here
        if detailedStatus.reblog == nil {
            HStack {
                if detailedStatus.repliesCount > 0 {
                    Text("status.replies-\(detailedStatus.repliesCount)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
                
                if detailedStatus.repliesCount > 0 && (detailedStatus.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                }
                
                if detailedStatus.favouritesCount > 0 || isLiked {
                    let likeCount: Int = detailedStatus.favouritesCount - (initialLike ? 1 : 0)
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
                if detailedStatus.reblog!.repliesCount > 0 {
                    Text("status.replies-\(detailedStatus.reblog!.repliesCount)")
                        .monospacedDigit()
                        .foregroundStyle(.gray)
                }
                
                if detailedStatus.reblog!.repliesCount > 0 && (detailedStatus.reblog!.favouritesCount > 0 || isLiked) {
                    Text("•")
                        .foregroundStyle(.gray)
                }
                
                if detailedStatus.reblog!.favouritesCount > 0 || isLiked {
                    let likeCount: Int = detailedStatus.reblog!.favouritesCount - (initialLike ? 1 : 0)
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
        let content = detailedStatus.content
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
}
