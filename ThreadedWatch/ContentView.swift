//Made by Lumaa

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var givenAccounts: [GivenAccount] = []
    private let connectivity: SessionDelegator = .init()
    
    @State private var fetching: Bool = false
    @State private var currentAccount: (UIImage, Int)? = nil
    
    var body: some View {
        NavigationStack {
            TabView {
                if givenAccounts.isEmpty || givenAccounts.count < 1 {
                    ContentUnavailableView("iphone.login", systemImage: "iphone", description: Text("iphone.login.description"))
                        .containerBackground(Color.yellow.gradient, for: .tabView)
                        .scrollDisabled(true)
                } else {
                    ForEach(givenAccounts, id: \.bearerToken) { acc in
                        ZStack {
                            if currentAccount == nil {
                                ProgressView()
                                    .task {
                                        self.currentAccount = await getData(givenAccount: acc)
                                    }
                            } else {
                                let username: String = String(acc.acct.split(separator: "@")[0])
                                let server: String = String(acc.acct.split(separator: "@")[1])
                                
                                VStack {
                                    Image(uiImage: currentAccount!.0)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .padding(.top, 7.5)
                                        .onDisappear() {
                                            guard !fetching else { print("Fetching..."); return }
                                            self.currentAccount = nil
                                        }
                                    
                                    Text(String("@\(username)"))
                                        .font(.title2.bold())
                                    Text(server)
                                        .font(.caption)
                                        .foregroundStyle(Color.gray)
                                    
                                    ScrollView(.horizontal) {
                                        HStack {
                                            VStack {
                                                Text(currentAccount!.1, format: .number.notation(.compactName))
                                                    .font(.headline)
                                                
                                                Text("account.followers")
                                                    .font(.caption)
                                                    .foregroundStyle(Color.gray)
                                            }
                                            .safeAreaPadding()
                                        }
                                    }
                                    .padding(.top, 7.5)
                                }
                            }
                        }
                    }
                }
            }
            .tabViewStyle(.verticalPage(transitionStyle: .blur))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            connectivity.initialize()
            self.refresh()
        }
    }
    
    private func refresh() {
        self.givenAccounts = self.getAccounts()
        
        if connectivity.isWorking {
            withAnimation {
                self.givenAccounts.append(contentsOf: connectivity.allMessage.filter({ !self.givenAccounts.contains($0) }))
                if let _givenAccounts = connectivity.lastMessage, self.givenAccounts.isEmpty {
                    self.givenAccounts = [_givenAccounts] // fallback
                }
            }
        }
        
        self.givenAccounts = self.givenAccounts.uniqued()
        self.saveCurrentModels()
    }
    
    private func getAccounts() -> [GivenAccount] {
        guard let modelContainer: ModelContainer = try? ModelContainer(for: LoggedAccount.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false)) else { return [] }
        let modelContext = ModelContext(modelContainer)
        let loggedAccounts: [LoggedAccount]? = try? modelContext.fetch(FetchDescriptor<LoggedAccount>())
        let given: [GivenAccount] = loggedAccounts?.map({ $0.toGiven() }) ?? []
        
        return given
    }
    
    private func getData(givenAccount: GivenAccount) async -> (UIImage, Int) {
        let server = givenAccount.acct.split(separator: "@")[1]
        let client: Client = Client(server: String(server), oauthToken: OauthToken(accessToken: givenAccount.bearerToken, tokenType: "Bearer", scope: "", createdAt: .nan))
        
        var pfp: UIImage
        do {
            fetching = true
            let acc = try await client.getString(endpoint: Accounts.verifyCredentials, forceVersion: .v1)
            fetching = false
            
            if let serialized: [String : Any] = try JSONSerialization.jsonObject(with: acc.data(using: String.Encoding.utf8) ?? Data()) as? [String : Any] {
                let avatar: String = serialized["avatar"] as! String
                let task = try await URLSession.shared.data(from: URL(string: avatar)!)
                pfp = UIImage(data: task.0) ?? UIImage()
                
                let followers: Int = serialized["followers_count"] as! Int
                return (pfp, followers)
            }
        } catch {
            print(error)
        }
        return (UIImage(), 0)
    }
    
    private func saveModel(model: LoggedAccount) {
        guard let modelContainer: ModelContainer = try? ModelContainer(for: LoggedAccount.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false)) else { return }
        let modelContext = ModelContext(modelContainer)
        modelContext.insert(model)
    }
    
    private func saveCurrentModels() {
        for given in self.givenAccounts {
            saveModel(model: given.toLogged())
        }
    }
}

#Preview {
    ContentView()
}
