//Made by Lumaa

import Foundation

@Observable
public class AccountManager: ObservableObject {
    private var client: Client?
    private var account: Account?
    
    public static var shared: AccountManager = AccountManager()
    
    init(client: Client? = nil, account: Account? = nil) {
        self.client = client
        self.account = account
    }
    
    public func clear() {
        self.client = nil
        self.account = nil
    }
    
    public func setClient(_ client: Client) {
        self.client = client
    }
    
    public func getClient() -> Client? {
        return client
    }
    
    public func setAccount(_ account: Account) {
        self.account = account
    }
    
    public func getAccount() -> Account? {
        return account
    }
    
    public func forceClient() -> Client {
        guard client != nil else { fatalError("Client is not existant in that context") }
        return client!
    }
    
    public func forceAccount() -> Account {
        guard account != nil else { fatalError("Account is not existant in that context") }
        return account!
    }
    
    public func fetchAccount() async -> Account? {
        guard client != nil else { fatalError("Client is not existant in that context") }
        account = try? await client!.get(endpoint: Accounts.verifyCredentials)
        return account
    }
}
