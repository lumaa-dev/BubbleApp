//Made by Lumaa

import SwiftUI

struct ContactsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @EnvironmentObject private var navigator: Navigator
    
    @State private var contacts: [MessageContact] = []
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                ForEach(contacts) { contact in
                    ContactRow(cont: contact)
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(Text("activity.messages"))
        .task {
            await fetchContacts()
        }
    }
    
    func fetchContacts(lastId: Int? = nil) async {
        guard let client = accountManager.getClient() else { return }
        
        if lastId != nil {
            guard lastId! >= contacts.count - 6 else { return }
        }
        
        do {
            let msgs: [MessageContact] = try await client.get(endpoint: Conversations.conversations(maxId: nil))
            guard !msgs.isEmpty else { return }
            
            if contacts.isEmpty {
                contacts = msgs
            } else {
                contacts.append(contentsOf: msgs)
            }
        } catch {
            print(error)
        }
    }
}
