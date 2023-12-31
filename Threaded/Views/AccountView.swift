//Made by Lumaa

import SwiftUI

struct AccountView: View {
    @Environment(Client.self) private var client: Client
    
    @Namespace var accountAnims
    @Namespace var animPicture
    
    @State private var navigator: Navigator = Navigator()
    @State private var biggerPicture: Bool = false
    @State private var location: CGPoint = .zero
    
    @State var account: Account
    @State var statuses: [Status]?
    @State var statusesPinned: [Status]?
    private let animPicCurve = Animation.smooth(duration: 0.25, extraBounce: 0.0)
    
    var body: some View {
        ZStack (alignment: .center) {
            if account != Account.placeholder() {
                if biggerPicture {
                    big
                } else {
                    wholeSmall
                }
            } else {
                loading
            }
        }
        .refreshable {
            if let ref: Account = try? await client.get(endpoint: Accounts.accounts(id: account.id)) {
                account = ref
                
                statuses = try? await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil))
                statusesPinned = try? await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: true))
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
                unbig
                
                HStack {
                    Text(account.note.asRawText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: .infinity, height: 1)
                    .padding(.bottom, 3)
                
                statusesList
            }
            .safeAreaPadding(.vertical)
            .padding(.horizontal)
        }
        .withAppRouter()
    }
    
    var statusesList: some View {
        VStack {
            if statuses != nil {
                if !(statusesPinned?.isEmpty ?? true) {
                    ForEach(statusesPinned!, id: \.id) { status in
                        CompactPostView(status: status, navigator: navigator, pinned: true)
                    }
                }
                if !statuses!.isEmpty {
                    ForEach(statuses!, id: \.id) { status in
                        CompactPostView(status: status, navigator: navigator)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            if statuses == nil {
                Task {
                    statuses = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: nil))
                    statusesPinned = try await client.get(endpoint: Accounts.statuses(id: account.id, sinceId: nil, tag: nil, onlyMedia: nil, excludeReplies: nil, pinned: true))
                }
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
        .withAppRouter()
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
                                
                                Text("\(client.server)")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                                    .multilineTextAlignment(.leading)
                                    .pill()
                            }
                        } else {
                            Text("\(account.username)")
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(client.server)")
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
        OnlineImage(url: account.avatar)
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
