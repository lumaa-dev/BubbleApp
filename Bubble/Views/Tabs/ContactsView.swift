//Made by Lumaa

import SwiftUI

struct ContactsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @State private var contacts: [MessageContact] = []
    @State private var fetching: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                ForEach(contacts) { contact in
                    ContactRow(cont: contact)
                        .contextMenu {
                            if contact.lastStatus != nil {
                                ControlGroup {
                                    Button {
                                        guard let client = accountManager.getClient() else { return }
                                        Task {
                                            do {
                                                let endpoint = contact.lastStatus!.favourited ?? false ? Statuses.unfavorite(id: contact.lastStatus!.id) : Statuses.favorite(id: contact.lastStatus!.id)
                                                
                                                _ = try await client.post(endpoint: endpoint)
                                            } catch {
                                                print(error)
                                            }
                                        }
                                    } label: {
                                        Label(contact.lastStatus!.favourited ?? false ? "status.action.unlike" : "status.action.like", systemImage: contact.lastStatus!.favourited ?? false ? "heart.slash.fill" : "heart")
                                    }
                                    
                                    Button {
                                        guard let client = accountManager.getClient() else { return }
                                        Task {
                                            do {
                                                let endpoint = contact.lastStatus!.bookmarked ?? false ? Statuses.unbookmark(id: contact.lastStatus!.id) : Statuses.bookmark(id: contact.lastStatus!.id)
                                                
                                                _ = try await client.post(endpoint: endpoint)
                                            } catch {
                                                print(error)
                                            }
                                        }
                                    } label: {
                                        Label(contact.lastStatus!.bookmarked ?? false ? "status.action.unbookmark" : "status.action.bookmark", systemImage: contact.lastStatus!.bookmarked ?? false ? "bookmark.slash.fill" : "bookmark")
                                    }
                                }
                                
                                Divider()
                            }
                            
                            if contact.unread {
                                Button {
                                    guard let client = accountManager.getClient() else { return }
                                    Task {
                                        do {
                                            _ = try await client.post(endpoint: Conversations.read(id: contact.id))
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Label("activity.messages.read", systemImage: "eye")
                                }
                            }
                        }
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(Text("activity.messages"))
        .onAppear {
            guard !fetching else { return }
            
            fetching = true
            Task {
                await fetchContacts()
            }
            fetching = false
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
    
    func fetchContact(convId: String) async -> MessageContact? {
        guard let client = accountManager.getClient() else { return nil }
        
        do {
            let msgs: [MessageContact] = try await client.get(endpoint: Conversations.conversations(maxId: convId))
            guard !msgs.isEmpty else { return nil } // Could not find conversation
            
            if contacts.contains(where: { $0.id == (msgs.first?.id ?? "") }) {
                let index: Int = contacts.firstIndex(where: { $0.id == (msgs.first?.id ?? "") }) ?? -1
                contacts[index] = msgs.first ?? .placeholder()
            }
            
            return msgs.first
        } catch {
            print(error)
        }
        
        return nil
    }
}
