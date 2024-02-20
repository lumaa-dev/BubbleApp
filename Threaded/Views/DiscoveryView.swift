//Made by Lumaa

import SwiftUI

struct DiscoveryView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @State private var navigator: Navigator = Navigator()
    
    @State private var searchQuery: String = ""
    @State private var results: [String : SearchResults] = [:]
    @State private var querying: Bool = false
    
    let allTokens = [Token(id: "accounts", name: String(localized: "discovery.search.users"), image: "person.3.fill"), Token(id: "statuses", name: String(localized: "discovery.search.posts"), image: "note.text"), Token(id: "hashtags", name: String(localized: "discovery.search.tags"), image: "tag.fill")]
    @State private var currentTokens = [Token]()
    
    @State private var suggestedAccounts: [Account] = []
    @State private var suggestedAccountsRelationShips: [Relationship] = []
    @State private var trendingTags: [Tag] = []
    @State private var trendingStatuses: [Status] = []
    @State private var trendingLinks: [Card] = []
    
    // TODO: "Read" button
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            ScrollView {
                if results != [:] && !querying {
                    SearchResultView(searchResults: results[searchQuery] ?? .init(accounts: [], statuses: [], hashtags: []), query: searchQuery)
                    
                    Spacer()
                        .foregroundStyle(Color.white)
                        .padding()
                } else if querying {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                
                VStack(alignment: .leading) {
                    Text("discovery.suggested.users")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    accountsView
                    
                    Text("discovery.trending.tags")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    tagsView
                    
                    Text("discovery.app")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    appView
                        .padding(.horizontal)
                    
                    Text("discovery.trending.posts")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    statusView
                }
            }
            .listThreaded()
            .submitLabel(.search)
            .task(id: searchQuery) {
                if !searchQuery.isEmpty {
                    querying = true
                    await search()
                    querying = false
                } else {
                    querying = false
                    results = [:]
                }
            }
            .onChange(of: currentTokens) { old, new in
                guard new.count > 1 else { return }
                let newToken = new.last ?? allTokens[1]
                
                currentTokens = [newToken]
            }
            .searchable(text: $searchQuery, tokens: $currentTokens, suggestedTokens: .constant(allTokens), prompt: Text("discovery.search.prompt")) { token in
                Label(token.name, systemImage: token.image)
            }
            .withAppRouter(navigator)
            .navigationTitle(Text("discovery"))
        }
        .environmentObject(navigator)
        .task {
            await fetchTrending()
        }
    }
    
    var accountsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(suggestedAccounts) { account in
                    VStack {
                        ProfilePicture(url: account.avatar, size: 64)
                        
                        Text(account.displayName?.replacing(/:.+:/, with: "") ?? account.username)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .lineLimit(1)
                        
                        Text("@\(account.username)")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        
                        Spacer()
                        
                        Button {
                            guard let client = accountManager.getClient() else { return }
                            
                            Task {
                                do {
                                    let better: Account = try await client.get(endpoint: Accounts.accounts(id: account.id))
                                    navigator.navigate(to: .account(acc: better))
                                } catch {
                                    print(error)
                                }
                            }
                        } label: {
                            Text("account.view")
                        }
                        .buttonStyle(LargeButton(filled: true, height: 7.5))
                    }
                    .padding(.vertical)
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 15.0))
                }
                .scrollTargetLayout()
            }
        }
        .padding(.horizontal)
        .scrollClipDisabled()
        .defaultScrollAnchor(.leading)
    }
    
    var tagsView: some View {
        VStack(spacing: 7.5) {
            ForEach(trendingTags) { tag in
                HStack {
                    VStack(alignment: .leading) {
                        Text("#\(tag.name)")
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .bold()
                        Text("tag.posts-\(tag.totalUses)")
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                            .foregroundStyle(Color.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        navigator.navigate(to: .timeline(timeline: .hashtag(tag: tag.name, accountId: nil)))
                    } label: {
                        Text("tag.read")
                    }
                    .buttonStyle(LargeButton(filled: true, height: 7.5, disabled: true))
                    .disabled(true)
                }
                .padding()
            }
        }
    }
    
    var statusView: some View {
        VStack(spacing: 7.5) {
            ForEach(trendingStatuses) { status in
                CompactPostView(status: status)
                    .padding(.vertical)
                    .environmentObject(navigator)
            }
        }
    }
    
    var appView: some View {
        VStack(spacing: 7.5) {
            AccountRow(acct: "Threaded@mastodon.online") {
                Text("accounts.official")
                    .font(.headline.bold().width(.condensed))
                    .foregroundStyle(.green)
            }
            AccountRow(acct: "lumaa@mastodon.online") {
                Text("accounts.developer")
                    .font(.headline.bold().width(.condensed))
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func search() async {
        guard let client = accountManager.getClient(), !searchQuery.isEmpty else { return }
        do {
            try await Task.sleep(for: .milliseconds(250))
            let results: SearchResults = try await client.get(endpoint: Search.search(query: searchQuery, type: currentTokens.first?.id, offset: nil, following: nil), forceVersion: .v2)
//            let relationships: [Relationship] = try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map(\.id)))
//            results.relationships = relationships
            withAnimation {
                self.results[searchQuery] = results
            }
        } catch {
            print(error)
        }
    }
    
    private func fetchTrending() async {
        guard let client = accountManager.getClient() else { return }
        do {
            let data = try await fetchTrendingsData(client: client)
            suggestedAccounts = data.suggestedAccounts
            trendingTags = data.trendingTags
            trendingStatuses = data.trendingStatuses
            trendingLinks = data.trendingLinks
            
            trendingTags = trendingTags.sorted(by: { $0.totalUses > $1.totalUses })
            
            suggestedAccountsRelationShips = try await client.get(endpoint: Accounts.relationships(ids: suggestedAccounts.map(\.id)))
        } catch {
            print(error)
        }
    }
    
    private func fetchTrendingsData(client: Client) async throws -> TrendingData {
        async let suggestedAccounts: [Account] = client.get(endpoint: Accounts.suggestions)
        async let trendingTags: [Tag] = client.get(endpoint: Trends.tags)
        async let trendingStatuses: [Status] = client.get(endpoint: Trends.statuses(offset: nil))
        async let trendingLinks: [Card] = client.get(endpoint: Trends.links)
        return try await .init(suggestedAccounts: suggestedAccounts, trendingTags: trendingTags, trendingStatuses: trendingStatuses, trendingLinks: trendingLinks)
    }
    
    private struct TrendingData {
        let suggestedAccounts: [Account]
        let trendingTags: [Tag]
        let trendingStatuses: [Status]
        let trendingLinks: [Card]
    }
    
    struct Token: Identifiable, Equatable {
        var id: String
        var name: String
        var image: String
    }
}
