//Made by Lumaa

import Foundation
import SwiftUI
import WebKit

@Observable
public class Navigator {
    public static var shared: Navigator = Navigator()

    public var presentedSheet: SheetDestination? = nil
    public var presentedCover: SheetDestination? = nil
    public var selectedTab: TabDestination
    private(set) public var path: [TabDestination : [RouterDestination]] = [:]

    public subscript(_ tab: TabDestination? = nil) -> [RouterDestination] {
        get { self.path[tab ?? self.selectedTab] ?? [] }
        set { self.path[tab ?? self.selectedTab] = newValue }
    }

    public func navigate(to destination: RouterDestination, for tab: TabDestination? = nil) {
        let t: TabDestination = tab ?? self.selectedTab
        if self.path[t] != nil {
            self.path[t]!.append(destination)
        } else {
            self.path[t] = [destination]
        }
    }

    /// Remove in all the tabs' paths (``path``) a certain ``RouterDestination``
    /// - Parameter destination: The ``RouterDestination`` to remove everywhere in ``path``
    public func filter(_ destination: RouterDestination) {
        self.path.forEach { (key, value) in
            if value.contains(destination) {
                self.path[key] = self.path[key]?.filter { $0 != destination } ?? []
            }
        }
    }

    /// Resets the whole ``path``
    public func reset() {
        for tab in TabDestination.allCases {
            self.path[tab] = []
        }
    }

    init(starterTab: TabDestination = .timeline) {
        self.selectedTab = starterTab
    }
}

public enum TabDestination: Int, Identifiable, Hashable, CaseIterable, Sendable {
    case timeline = 0
    case search = 1
    case post = 2
    case activity = 3
    case profile = 4
    
    public var id: String {
        switch self {
            case .timeline:
                return "timeline"
            case .search:
                return "search"
            case .post:
                return "post"
            case .activity:
                return "activity"
            case .profile:
                return "profile"
        }
    }

    @ViewBuilder
    public var label: some View {
        switch self {
            case .timeline:
                Label("tab.timeline", systemImage: "house")
            case .search:
                Label("tab.search", systemImage: "magnifyingglass")
            case .post:
                Label("tab.post", systemImage: "square.and.pencil")
            case .activity:
                Label("tab.activity", systemImage: "heart")
            case .profile:
                Label("tab.profile", systemImage: "person")

        }
    }
}

public enum SheetDestination: Identifiable {
    case welcome
    case shop
    case lockedFeature(_ feature: AppInfo.Feature? = nil)
    case media(attachments: [MediaAttachment], selected: MediaAttachment)
    case aboutSubclub

    case mastodonLogin(logged: Binding<Bool>)
    case post(content: String = "", replyId: String? = nil, editId: String? = nil)
    case profEdit
    case safari(url: URL)
    case shareImage(image: UIImage, status: Status)
    case update
    case filter

    case reportStatus(status: Status)
//    case reportUser

    public var id: String {
        switch self {
            case .welcome:
                return "welcome"
            case .shop:
                return "shop"
            case .lockedFeature:
                return "lockedFeature"
            case .media:
                return "media"
            case .aboutSubclub:
                return "aboutSubclub"

            case .mastodonLogin:
                return "login"
            case .post:
                return "post"
            case .profEdit:
                return "profileEdit"
            case .safari:
                return "safari"
            case .shareImage:
                return "shareImage"
            case .update:
                return "update"
            case .filter:
                return "contentfilter"

            case .reportStatus:
                return "reportStatus"
        }
    }
    
    public var isCover: Bool {
        switch self {
            case .welcome:
                return true
            case .shop:
                return true
            case .lockedFeature:
                return false
            case .media:
                return true
            case .aboutSubclub:
                return false

            case .mastodonLogin:
                return false
            case .post:
                return false
            case .profEdit:
                return false
            case .safari:
                return false
            case .shareImage:
                return false
            case .update:
                return false
            case .filter:
                return false

            case .reportStatus:
                return false
        }
    }
}

extension SheetDestination: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum RouterDestination: Hashable {
    case settings
    case support
    case appearence
    case appicon
    case about
    case privacy
    case restricted
    case filter
    
    case account(acc: Account)
    case post(status: Status)
    case contacts
    case timeline(timeline: TimelineFilter)
}

extension RouterDestination {
    static let allSettings: [RouterDestination] = [.settings, .support, .about, .appearence, .privacy, .restricted, .filter, .appicon]
}

extension View {
    func withAppRouter() -> some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
                case .settings:
                    SettingsView()
                case .support:
                    SupportView()
                case .appearence:
                    AppearenceView()
                case .appicon:
                    IconView()
                case .account(let acc):
                    ProfileView(account: acc)
                case .post(let status):
                    PostDetailsView(status: status)
                case .about:
                    AboutView()
                case .contacts:
                    ContactsView()
                case .privacy:
                    PrivacyView()
                case .restricted:
                    RestrictedView()
                case .timeline(let timeline):
                    PostsView(filter: timeline)
                case .filter:
                    FilterView()
            }
        }
    }
    
    func withSheets(sheetDestination: Binding<SheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            viewSheet(destination: destination)
        }
    }
    
    func withCovers(sheetDestination: Binding<SheetDestination?>) -> some View {
        fullScreenCover(item: sheetDestination) { destination in
            viewCover(destination: destination)
        }
    }
    
    private func viewCover(destination: SheetDestination) -> some View {
        Group {
            switch destination {
                case .welcome:
                    ConnectView()
                case .shop:
                    ShopView()
                case .media(let attachments, let selected):
                    AttachmentView(attachments: attachments, selectedId: selected.id)
                default:
                    EmptySheetView(destId: destination.id)
            }
        }
    }
    
    private func viewSheet(destination: SheetDestination) -> some View {
        Group {
            switch destination {
                case .post(let content, let replyId, let editId):
                    NavigationStack {
                        PostingView(initialString: content, replyId: replyId, editId: editId)
                            .tint(Color(uiColor: UIColor.label))
                    }
                case .lockedFeature(let feature):
                    PlusNecessaryView(feature)
                case .profEdit:
                    EditProfileView()
                case .aboutSubclub:
                    AboutSubclubView()
                case let .mastodonLogin(logged):
                    AddInstanceView(logged: logged)
                        .tint(Color.accentColor)
                case let .safari(url):
                    SafariView(url: url)
                case let .shareImage(image, status):
                    ShareSheet(image: image, status: status)
                case .update:
                    UpdateView()
                case let .reportStatus(status):
                    ReportStatusView(status: status)
                default:
                    EmptySheetView(destId: destination.id)
            }
        }
    }
}

/// This view is visible when the `viewRepresentation(destination: SheetDestination)` doesn't support the given `SheetDestination`
private struct EmptySheetView: View {
    @Environment(\.dismiss) private var dismiss
    var destId: String = ""
    let str: String = .init(localized: "about.version-\(AppInfo.appVersion)")
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.red.gradient)
                .ignoresSafeArea()
            
            VStack {
                ContentUnavailableView(String("Missing view for \"\(destId.isEmpty ? "[EMPTY_DEST_ID]" : destId)\""), systemImage: "exclamationmark.triangle.fill", description: Text(String("Please notify Lumaa as soon as possible!\n\n\(str)")))
                    .foregroundStyle(.white)
                
                Button {
                    dismiss()
                } label: {
                    Text(String("Dismiss"))
                }
                .buttonStyle(LargeButton(filled: true))
            }
        }
    }
}
