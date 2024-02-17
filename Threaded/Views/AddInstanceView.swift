//Made by Lumaa

import SwiftUI
import AuthenticationServices

struct AddInstanceView: View {
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.dismiss) private var dismiss
    
    // Instance URL and verify
    @State private var instanceUrl: String = ""
    
    @State private var verifying: Bool = false
    @State private var verified: Bool = false
    @State private var verifyError: Bool = false
    
    @State private var blockList: [String] = []
    @State private var responsability: Bool = false
    @State private var showingResponsability: Bool = false
    @State private var agreedResponsability: Bool = false
    
    @State private var instanceInfo: Instance?
    
    @State private var signInClient: Client?
    @Binding public var logged: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("login.mastodon.instance", text: $instanceUrl)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.continue)
                    .disabled(verifying)
                    .onSubmit {
                        if !verified {
                            verify()
                        }
                    }
                
                if !verifying {
                    if !verified {
                        Button {
                            verify()
                        } label: {
                            Text("login.mastodon.verify")
                                .disabled(instanceUrl.isEmpty)
                        }
                        .buttonStyle(.bordered)
                        
                        if verifyError == true {
                            Text("login.mastodon.verify-error")
                                .foregroundStyle(.red)
                        }
                    } else {
                        Button {
                            Task {
                                await signIn()
                            }
                        } label: {
                            Text("login.mastodon.login")
                                .disabled(instanceUrl.isEmpty)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.white)
                        .foregroundStyle(Color.white)
                }
            }
                
            if verified && instanceInfo != nil {
                Section {
                    VStack(alignment: .leading) {
                        Text(instanceInfo!.title)
                            .font(.headline)
                        Text(instanceInfo!.shortDescription)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("instance.rules")
                            .font(.headline)
                        
                        if !(instanceInfo!.rules?.isEmpty ?? true) {
                            ForEach(instanceInfo!.rules!) { rule in
                                Text(rule.text)
                            }
                        }
                    }
                }
            }
        }
        .task {
            withAnimation {
                verifying = true
            }
            
            blockList = Instance.getBlocklist()
            
            withAnimation {
                verifying = false
            }
        }
        .alert("login.instance.unsafe", isPresented: $showingResponsability, actions: {
            Button(role: .destructive) {
                responsability = true
                agreedResponsability = true
                showingResponsability.toggle()
            } label: {
                Text("login.instance.unsafe.agree")
            }
            
            Button(role: .cancel) {
                responsability = true
                agreedResponsability = false
                showingResponsability.toggle()
            } label: {
                Text("login.instance.unsafe.disagree")
            }
        }, message: {
            Text("login.instance.unsafe.description")
        })
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .onChange(of: instanceUrl) { _, newValue in
            guard !self.verifying else { return }
            verified = false
        }
    }
    
    func verify() {
        withAnimation {
            verifying = true
            verified = false
            verifyError = false
        }
        
        let cleanInstance = instanceUrl
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
        
        if !isInstanceSafe() {
            if responsability == false && agreedResponsability == false {
                responsability = true
                agreedResponsability = false
                showingResponsability = true
                
                withAnimation {
                    verifying = false
                    verified = false
                    verifyError = false
                }
                
                return
            } else if responsability == true && agreedResponsability == true {
                showingResponsability = false
            } else if responsability == true && agreedResponsability == false {
                showingResponsability = true
                
                withAnimation {
                    verifying = false
                    verified = false
                    verifyError = false
                }
                
                return
            }
        } else {
            responsability = false
            agreedResponsability = false
            UserDefaults.standard.removeObject(forKey: "unsafe")
        }
        
        let client = Client(server: cleanInstance)
        
        Task {
            do {
                let instance: Instance = try await client.get(endpoint: Instances.instance)
                
                withAnimation {
                    instanceInfo = instance
                    verifying = false
                    verified = true
                    verifyError = false
                }
            } catch {
                print(error.localizedDescription)
                
                withAnimation {
                    verifying = false
                    verified = false
                    verifyError = true
                }
            }
        }
    }
    
    private func signIn() async {
        let cleanInstance = instanceUrl
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
        
        signInClient = .init(server: cleanInstance)
        if let oauthURL = try? await signInClient?.oauthURL(),
           let url = try? await webAuthenticationSession.authenticate(using: oauthURL, callbackURLScheme: AppInfo.scheme.replacingOccurrences(of: "://", with: "")) {
            await continueSignIn(url: url)
        }
    }
    
    private func continueSignIn(url: URL) async {
        guard let client = signInClient else {
            return
        }
        
        if agreedResponsability && responsability {
            UserDefaults.standard.setValue(true, forKey: "unsafe")
        } else {
            UserDefaults.standard.removeObject(forKey: "unsafe")
        }
        
        do {
            let oauthToken = try await client.continueOauthFlow(url: url)
            let client = Client(server: client.server, oauthToken: oauthToken)
            let account: Account = try await client.get(endpoint: Accounts.verifyCredentials)
            let appAcc = AppAccount(server: client.server, accountName: "\(account.acct)@\(client.server)", oauthToken: oauthToken)
            
            let connections: [String] = try await client.get(endpoint: Instances.peers)
            client.addConnections(connections)
            
            appAcc.saveAsCurrent()
            AccountManager.shared.setClient(client)
            AccountManager.shared.setAccount(account)
            
            signInClient = client
            logged = true
            dismiss()
        } catch {
            print(error)
        }
    }
    
    /// Is the user input instance URL a safe instance
    /// - returns: True, if the instance isn't consider as dangerous
    private func isInstanceSafe() -> Bool {
        let unsafe = blockList.contains(instanceUrl.trimmingCharacters(in: .whitespacesAndNewlines))
        return !unsafe
    }
}

#Preview {
    AddInstanceView(logged: .constant(false))
}
