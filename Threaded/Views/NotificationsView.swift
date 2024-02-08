//Made by Lumaa

import SwiftUI
import TipKit

struct NotificationsView: View {
    @Environment(AccountManager.self) private var accountManager
    
    @State private var navigator: Navigator = Navigator()
    @State private var notifications: [Notification] = []
    @State private var loadingNotifs: Bool = true
    @State private var lastId: Int? = nil
    private let notifLimit = 50
    
    @State private var messages: [Notification] = []
    private var msgBadge: Int {
        messages.map({ $0.account.id }).uniqued().count
    }
    
    private let msgTip: MsgTip = .init()
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            if !notifications.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(notifications) { notif in
                            NotificationRow(notif: notif)
                                .onDisappear() {
                                    guard !notifications.isEmpty else { return }
                                    lastId = notifications.firstIndex(where: { $0.id == notif.id })
                                }
                        }
                        
                        if loadingNotifs {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .padding(.vertical)
                        }
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
                .environmentObject(navigator)
                .withAppRouter(navigator)
                .background(Color.appBackground)
                .refreshable {
                    await fetchNotifications(lastId: nil)
                }
                .navigationTitle(String(localized: "activity"))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            msgTip.invalidate(reason: .actionPerformed)
                        } label: {
                            Image(systemName: "paperplane")
                                .foregroundStyle(Color(uiColor: UIColor.label))
                                .overlay(alignment: .topTrailing) {
                                    if msgBadge > 0 {
                                        Text("\(msgBadge)")
                                            .foregroundStyle(Color.white)
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 5, y: -7)
                                    }
                                }
                        }
                        .popoverTip(msgTip, arrowEdge: .top)
                        .tipViewStyle(HeadlineTipViewStyle(headlineType: .meta))
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
            let notifs: [Notification] = try await client.get(endpoint: Notifications.notifications(minId: nil, maxId: nil, types: nil, limit: lastId != nil ? notifLimit : 30))
            guard !notifs.isEmpty else { return }
            
            if notifications.isEmpty {
                notifications = notifs
            } else {
                notifications.append(contentsOf: notifs)
            }
            
            filterMessages()
        } catch {
            print(error)
        }
    }
    
    func filterMessages() {
        guard !notifications.isEmpty else { return }
        messages = notifications.filter({ $0.status?.visibility == .direct })
        notifications.removeAll(where: { $0.status?.visibility == .direct })
    }
    
    struct MsgTip: Tip {
        var title: Text = Text("activity.tip.messages.title")
        var message: Text? = Text("activity.tip.messages.desc")
        var id: String = "fr.lumaa.Threaded.MsgTip"
        var image: Image? = Image(systemName: "paperplane")
    }
}

public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}