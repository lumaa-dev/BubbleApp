//Made by Lumaa

import SwiftUI
import TipKit

struct NotificationsView: View {
    @Environment(AccountManager.self) private var accountManager
    
    @State private var navigator: Navigator = Navigator()
    @State private var notifications: [GroupedNotification] = []
    @State private var loadingNotifs: Bool = true
    @State private var lastId: Int? = nil
    private let notifLimit = 50
    
    @State private var messages: [MessageContact] = []
    private var msgBadge: Int {
        messages.filter({ $0.unread == true }).count
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
                            navigator.navigate(to: .contacts)
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
        .environmentObject(navigator)
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
            var notifs: [Notification] = try await client.get(endpoint: Notifications.notifications(minId: nil, maxId: notifications.last?.id, types: nil, limit: lastId != nil ? notifLimit : 30))
            guard !notifs.isEmpty else { return }
            
            notifs = notifs.filter({ $0.supportedType != .mention && $0.status?.visibility != .direct })
            
            if notifications.isEmpty {
                notifications = notifs.toGrouped()
            } else {
                notifications.append(contentsOf: notifs.toGrouped())
            }
            
            await getBadge()
        } catch {
            print(error)
        }
    }
    
    func getBadge() async {
        guard let client = accountManager.getClient() else { return }
        
        do {
            let msgs: [MessageContact] = try await client.get(endpoint: Conversations.conversations(maxId: nil))
            guard !msgs.isEmpty else { return }
            
            messages = msgs
        } catch {
            print(error)
        }
    }
    
    struct MsgTip: Tip {
        var title: Text = Text("activity.tip.messages.title")
        var message: Text? = Text("activity.tip.messages.desc")
        var id: String = "fr.lumaa.Threaded.MsgTip"
        var image: Image? = Image(systemName: "paperplane")
    }
}
