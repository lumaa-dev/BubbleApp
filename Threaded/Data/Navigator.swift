//Made by Lumaa

import Foundation
import SwiftUI

@Observable
public class Navigator: ObservableObject {
    public var path: [RouterDestination] = []
    public var presentedSheet: SheetDestination?
    public var presentedCover: SheetDestination?
    public var selectedTab: TabDestination = .timeline
    
    public func navigate(to: RouterDestination) {
        path.append(to)
    }
    
    public func removeSettingsOfPath() {
        self.path = self.path.filter({ !RouterDestination.allSettings.contains($0) })
    }
}

public class UniversalNavigator: Navigator {
    public var client: Client?
    
    public func handle(url: URL) -> OpenURLAction.Result {
        guard let client = self.client else { return .systemAction }
        let path: String = url.absoluteString.replacingOccurrences(of: AppInfo.scheme, with: "") // remove all path
        let urlPath: URL = URL(string: path)!
        
        if client.isAuth && client.hasConnection(with: url) {
            if urlPath.lastPathComponent.starts(with: "@") {
                Task {
                    do {
                        let search: SearchResults = try await client.get(endpoint: Search.search(query: urlPath.lastPathComponent, type: "accounts", offset: nil, following: nil), forceVersion: .v2)
                        let acc: Account = search.accounts.first ?? .placeholder()
                        self.navigate(to: .account(acc: acc))
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        return .handled
    }
}

public enum TabDestination: Identifiable {
    case timeline
    case search
    case activity
    case profile
    
    public var id: String {
        switch self {
            case .timeline:
                return "timeline"
            case .search:
                return "search"
            case .activity:
                return "activity"
            case .profile:
                return "profile"
        }
    }
}

public enum SheetDestination: Identifiable {
    case welcome
    case shop
    case media(attachments: [MediaAttachment], selected: MediaAttachment)
    
    case mastodonLogin(logged: Binding<Bool>)
    case post(content: String = "", replyId: String? = nil, editId: String? = nil)
    case safari(url: URL)
    case shareImage(image: UIImage, status: Status)
    case update
    
    public var id: String {
        switch self {
            case .welcome:
                return "welcome"
            case .shop:
                return "shop"
            case .media:
                return "media"
                
            case .mastodonLogin:
                return "login"
            case .post:
                return "post"
            case .safari:
                return "safari"
            case .shareImage:
                return "shareImage"
            case .update:
                return "update"
        }
    }
    
    public var isCover: Bool {
        switch self {
            case .welcome:
                return true
            case .shop:
                return true
            case .media:
                return true
                
            case .mastodonLogin:
                return false
            case .post:
                return false
            case .safari:
                return false
            case .shareImage:
                return false
            case .update:
                return false
        }
    }
}

public enum RouterDestination: Hashable {
    case settings
    case support
    case appearence
    case about
    case privacy
    
    case account(acc: Account)
    case post(status: Status)
    case contacts
    case timeline(timeline: TimelineFilter?)
}

extension RouterDestination {
    static let allSettings: [RouterDestination] = [.settings, .support, .about, .appearence]
}

extension View {
    func withAppRouter(_ navigator: Navigator) -> some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
                case .settings:
                    SettingsView(navigator: navigator)
                case .support:
                    SupportView()
                case .appearence:
                    AppearenceView()
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
                case .timeline(let timeline):
                    PostsView(filter: timeline ?? .home, showHero: false)
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
                case let .mastodonLogin(logged):
                    AddInstanceView(logged: logged)
                        .tint(Color.accentColor)
                case let .safari(url):
                    SfSafariView(url: url)
                        .ignoresSafeArea()
                case let .shareImage(image, status):
                    ShareSheet(image: image, status: status)
                case .update:
                    UpdateView()
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
