//Made by Lumaa

import SwiftUI

struct AccountView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @Namespace var accountAnims
    @Namespace var animPicture
    @State private var biggerPicture: Bool = false
    
    @State var isCurrent: Bool = false
    @State var account: Account
    @State var navigator: Navigator = Navigator()
    
    @State private var canFollow: Bool? = nil
    @State private var initialFollowing: Bool = false
    @State private var isFollowing: Bool = false
    @State private var accountFollows: Bool = false
    
    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]?
    @State private var statusesPinned: [Status]?
    @State private var lastSeen: Int?
    
    private let animPicCurve = Animation.smooth(duration: 0.25, extraBounce: 0.0)
    
    var body: some View {
        if isCurrent {
            if accountManager.getClient() != nil {
                NavigationStack(path: $navigator.path) {
                    accountView
                        .withSheets(sheetDestination: $navigator.presentedSheet)
                        .onAppear {
                            account = accountManager.forceAccount()
                        }
                }
            } else {
                ZStack {
                    Color.appBackground
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        } else {
            accountView
        }
    }
    
    var accountView: some View {
        ZStack (alignment: .center) {
            if account != Account.placeholder() {
                if biggerPicture {
                    big
                        .navigationBarBackButtonHidden()
                        .toolbar(.hidden, for: .navigationBar)
                } else {
                    wholeSmall
                        .offset(y: isCurrent ? 50 : 0)
                        .overlay(alignment: .top) {
                            if isCurrent {
                                HStack {
                                    Button {
                                        navigator.navigate(to: .privacy)
                                    } label: {
                                        Image(systemName: "globe")
                                            .font(.title2)
                                    }
                                    
                                    Spacer() // middle seperation
                                    
                                    Button {
                                        navigator.navigate(to: .settings)
                                    } label: {
                                        Image(systemName: "text.alignright")
                                            .font(.title2)
                                    }
                                }
                                .tint(Color(uiColor: UIColor.label))
                                .safeAreaPadding()
                                .background(Color.appBackground)
                            }
                        }
                }
            } else {
                loading
            }
        }
        .task {
            await updateRelationship()
            initialFollowing = isFollowing
        }
        .refreshable {
            if let client = accountManager.getClient() {
                if let ref: Account = try? await client.get(endpoint: Accounts.accounts(id: account.id)) {
                    account = ref
                    
                    await updateRelationship()
                    loadingStatuses = true
                    statuses = try? await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil))
                    statusesPinned = try? await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: true))
                    loadingStatuses = false
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.automatic, for: .navigationBar)
    }
    
    // MARK: - Headers
    
    var wholeSmall: some View {
        ScrollView {
            VStack {
                VStack (alignment: .leading) {
                    unbig
                    
                    Text(account.note.asRawText)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 5)
                    
                    let followCount = (account.followersCount ?? 0 - (initialFollowing ? 1 : 0)) + (isFollowing ? 1 : 0)
                    Text("account.followers-\(followCount)")
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.leading)
                        .font(.callout)
                    
                    if canFollow != nil && (canFollow ?? true) == true {
                        HStack (spacing: 5) {
                            Button {
                                Task {
                                    await followAccount()
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(isFollowing ? "account.unfollow" : accountFollows ? "account.follow-back" : "account.follow")
                                        .font(.callout)
                                    Spacer()
                                }
                            }
                            .buttonStyle(LargeButton(filled: true, height: 10))
                            
                            Button {
                                if let server = account.acct.split(separator: "@").last {
                                    navigator.presentedSheet = .post(content: "@\(account.username)@\(server)")
                                } else {
                                    let client = accountManager.getClient()
                                    navigator.presentedSheet = .post(content: "@\(account.username)@\(client?.server ?? "???")")
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("account.mention")
                                        .font(.callout)
                                    Spacer()
                                }
                            }
                            .buttonStyle(LargeButton(filled: false, height: 10))
                        }
                    }
                }
                .padding(.horizontal)
                
                VStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: .infinity, height: 1)
                        .padding(.bottom, 3)
                    
                    statusesList
                }
            }
            .safeAreaPadding(.vertical)
            .padding(.horizontal)
        }
        .withAppRouter(navigator)
    }
    
    var statusesList: some View {
        LazyVStack {
            if statuses != nil {
                if !(statusesPinned?.isEmpty ?? true) {
                    ForEach(statusesPinned!, id: \.id) { status in
                        CompactPostView(status: status, navigator: navigator, pinned: true)
                    }
                }
                if !statuses!.isEmpty {
                    ForEach(statuses!, id: \.id) { status in
                        CompactPostView(status: status, navigator: navigator)
                            .onDisappear() {
                                lastSeen = statuses!.firstIndex(where: { $0.id == status.id })
                            }
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            if statuses == nil {
                if let client = accountManager.getClient() {
                    Task {
                        loadingStatuses = true
                        statuses = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil))
                        statusesPinned = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: true))
                        loadingStatuses = false
                    }
                }
            }
        }
        .onChange(of: lastSeen ?? 0) { _, new in
            guard statuses != nil && new >= statuses!.count - 6 && !loadingStatuses else { return }
            if let client = accountManager.getClient(), let lastStatus = statuses!.last {
                Task {
                    loadingStatuses = true
                    if let newStatuses: [Status] = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: lastStatus.id, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil)) {
                        statuses?.append(contentsOf: newStatuses)
                    }
                    loadingStatuses = false
                }
            }
        }
    }
    
    func followAccount() async {
        if let client = accountManager.getClient() {
            Task {
                let endpoint: Endpoint = isFollowing ? Accounts.unfollow(id: account.id) : Accounts.follow(id: account.id, notify: false, reblogs: true)
                HapticManager.playHaptics(haptics: Haptic.tap)
                try await client.post(endpoint: endpoint) // Notify off until APNs? | Reblogs on by default (later changeable)
                isFollowing = !isFollowing
            }
        }
    }
    
    func updateRelationship() async {
        if let client = accountManager.getClient() {
            if let currentAccount: Account = try? await client.get(endpoint: Accounts.verifyCredentials) {
                canFollow = currentAccount.id != account.id
                guard canFollow == true else { return }
                if let relationship: [Relationship] = try? await client.get(endpoint: Accounts.relationships(ids: [account.id])) {
                    isFollowing = relationship.first!.following
                    accountFollows = relationship.first!.followedBy
                }
            } else {
                canFollow = false
            }
        }
    }
    
    var loading: some View {
        ScrollView {
            VStack {
                unbig
                    .redacted(reason: .placeholder)
                
                HStack {
                    Text(account.note.asRawText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .redacted(reason: .placeholder)
                    
                    Spacer()
                }
            }
            .safeAreaPadding(.vertical)
            .padding(.horizontal)
        }
    }
    
    var unbig: some View {
        HStack {
            if account.displayName != nil {
                VStack(alignment: .leading) {
                    Text(account.displayName!)
                        .font(.title2.bold())
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    let server = account.acct.split(separator: "@").last
                    let client = accountManager.getClient()
                    
                    HStack(alignment: .center) {
                        if server != nil {
                            if server! != account.username {
                                Text("\(account.username)")
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                
                                Text("\(server!.description)")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                                    .multilineTextAlignment(.leading)
                                    .pill()
                            } else {
                                Text("\(account.username)")
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                
                                Text("\(client?.server ?? "???")")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                                    .multilineTextAlignment(.leading)
                                    .pill()
                            }
                        } else {
                            Text("\(account.username)")
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(client?.server ?? "???")")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.leading)
                                .pill()
                        }
                    }
                }
            } else {
                Text(account.acct)
                    .font(.headline)
            }
            
            Spacer()
            
            profilePicture
                .frame(width: 75, height: 75)
        }
    }
    
    var big: some View {
        ZStack (alignment: .center) {
            Rectangle()
                .fill(Material.ultraThin)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(animPicCurve) {
                        biggerPicture.toggle()
                    }
                }
            
            profilePicture
                .frame(width: 300, height: 300)
        }
        .zIndex(20)
    }
    
    var profilePicture: some View {
        OnlineImage(url: account.avatar, size: biggerPicture ? 300 : 50, useNuke: true)
            .clipShape(.circle)
            .matchedGeometryEffect(id: animPicture, in: accountAnims)
            .onTapGesture {
                withAnimation(animPicCurve) {
                    biggerPicture.toggle()
                }
            }
    }
}

private extension View {
    func pill() -> some View {
        self
            .padding([.horizontal], 10)
            .padding([.vertical], 5)
            .background(Color(uiColor: UIColor.label).opacity(0.1))
            .clipShape(.capsule)
    }
}
