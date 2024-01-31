//Made by Lumaa

import SwiftUI

struct NotificationsView: View {
    @Environment(AccountManager.self) private var accountManager
    
    @State private var navigator: Navigator = Navigator()
    @State private var notifications: [Notification] = []
    @State private var loadingNotifs: Bool = false
    @State private var lastId: Int? = nil
    private let notifLimit = 50
    
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            if !notifications.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading) {
                        ForEach(notifications) { notif in
                            NotificationRow(notif: notif)
                                .onDisappear() {
                                    guard !notifications.isEmpty else { return }
                                    lastId = notifications.firstIndex(where: { $0.id == notif.id })
                                }
                        }
                    }
                    .refreshable {
                        notifications = []
                        await fetchNotifications(lastId: nil)
                    }
                    .onChange(of: lastId ?? 0) { _, new in
                        guard !loadingNotifs else { return }
                        Task {
                            loadingNotifs = true
                            await fetchNotifications(lastId: new)
                            loadingNotifs = false
                        }
                    }
                }
            } else if loadingNotifs == false && notifications.isEmpty {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    ContentUnavailableView("activity.no-notifications", systemImage: "bolt.heart")
                }
            } else if loadingNotifs == true && notifications.isEmpty {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
        .task {
            loadingNotifs = true
            await fetchNotifications(lastId: nil)
            loadingNotifs = false
        }
    }
    
    func fetchNotifications(lastId: Int? = nil) async {
        guard let client = accountManager.getClient() else { return }
        
        if lastId != nil {
            guard lastId! >= notifications.count - 6 else { return }
        }
        
        do {
            let allCases = Notification.NotificationType.allCases.map({ $0.rawValue })
            let notifs: [Notification] = try await client.get(endpoint: Notifications.notifications(minId: nil, maxId: nil, types: nil, limit: lastId != nil ? notifLimit : 30))
            guard !notifs.isEmpty else { return }
            
            if notifications.isEmpty {
                notifications = notifs
            } else {
                notifications.append(contentsOf: notifs)
            }
        } catch {
            print(error)
        }
    }
}
