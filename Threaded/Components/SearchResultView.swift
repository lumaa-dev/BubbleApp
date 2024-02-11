//Made by Lumaa

import SwiftUI

struct SearchResultView: View {
    @EnvironmentObject private var navigator: Navigator
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    var searchResults: SearchResults
    var query: String
    
    var body: some View {
        if !searchResults.isEmpty {
            VStack(alignment: .leading) {
                if !searchResults.accounts.isEmpty {
                    Text("discovery.results.users")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    accountsView
                }
                
                if searchResults.statuses.count > 0 {
                    Text("discovery.results.posts")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    statusesView
                }
                
                if searchResults.hashtags.count > 0 {
                    Text("discovery.results.tags")
                        .multilineTextAlignment(.leading)
                        .font(.title.bold())
                        .padding(.horizontal)
                    
                    tagsView
                }
            }
        } else {
            ContentUnavailableView.search(text: query)
        }
    }
    
    var accountsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(searchResults.accounts) { account in
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
            ForEach(searchResults.hashtags) { tag in
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
                        // do stuff
                    } label: {
                        Text("tag.read")
                    }
                    .buttonStyle(LargeButton(filled: true, height: 7.5))
                }
                .padding()
            }
        }
    }
    
    var statusesView: some View {
        VStack(spacing: 7.5) {
            ForEach(searchResults.statuses) { status in
                CompactPostView(status: status)
                    .padding(.vertical)
            }
        }
    }
}
