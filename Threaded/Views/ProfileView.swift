//Made by Lumaa

import SwiftUI

struct ProfileView: View {
    @Environment(Client.self) private var client: Client
    
    @Namespace var accountAnims
    @Namespace var animPicture
    
    @State private var navigator: Navigator = Navigator()
    @State private var biggerPicture: Bool = false
    @State private var location: CGPoint = .zero
    
    @State var account: Account
    private let isCurrent: Bool = true
    private let animPicCurve = Animation.smooth(duration: 0.25, extraBounce: 0.0)
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
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
        }
        .refreshable {
            if isCurrent {
                do {
                    if let saved: AppAccount = try AppAccount.loadAsCurrent() {
                        let cli: Client = Client(server:  saved.server, oauthToken: saved.oauthToken)
                        let acc: Account? = try await client.get(endpoint: Accounts.verifyCredentials)
                        account = acc ?? Account.placeholder()
                    }
                } catch {
                    print(error)
                }
            } else {
                if let ref: Account = try? await client.get(endpoint: Accounts.accounts(id: account.id)) {
                    account = ref
                }
            }
        }
        .environment(navigator)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: UIColor.systemBackground), for: .navigationBar)
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
            }
            .safeAreaPadding(.vertical)
            .padding(.horizontal)
            .offset(y: 50)
            .overlay(alignment: .top) {
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
                .safeAreaPadding()
                .background(Color(uiColor: UIColor.systemBackground))
            }
        }
        .withAppRouter()
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
            .offset(y: 50)
            .overlay(alignment: .top) {
                HStack {
                    Button {
                        navigator.navigate(to: .privacy)
                    } label: {
                        Image(systemName: "globe")
                            .font(.title2)
                    }
                    .disabled(true)
                    
                    Spacer() // middle seperation
                    
                    Button {
                        navigator.navigate(to: .settings)
                    } label: {
                        Image(systemName: "text.alignright")
                            .font(.title2)
                    }
                    .disabled(true)
                }
                .safeAreaPadding()
                .background(Color(uiColor: UIColor.systemBackground))
            }
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
