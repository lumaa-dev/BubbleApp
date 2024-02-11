//Made by Lumaa

import Foundation
import SwiftUI

@Observable
public class Navigator: ObservableObject {    
    public var path: [RouterDestination] = []
    public var presentedSheet: SheetDestination?
    public var presentedCover: SheetDestination?
    public var selectedTab: TabDestination = .timeline
    
    public var showTabbar: Bool = true
    
    public func navigate(to: RouterDestination) {
        path.append(to)
        if path.contains(where: { $0 == .settings }) {
            toggleTabbar(false)
        } else {
            toggleTabbar(true)
        }
    }
    
    public func removeSettingsOfPath() {
        self.path = self.path.filter({ !RouterDestination.allSettings.contains($0) })
    }
    
    
    /// Defines the visibility of the main tab bar in from `ContentView`
    /// - Parameter bool: `true` shows the tab bar and `false` hides the tab bar
    public func toggleTabbar(_ bool: Bool? = nil) {
        print("\((bool ?? !self.showTabbar) ? "shown" : "hide") the tab bar")
        withAnimation(.easeInOut(duration: 0.4)) {
            self.showTabbar = bool ?? !self.showTabbar
        }
    }
}

public class UniversalNavigator: Navigator {}

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
    
    case mastodonLogin(logged: Binding<Bool>)
    case post(content: String = "", replyId: String? = nil, editId: String? = nil)
    case safari(url: URL)
    case shareImage(image: UIImage, status: Status)
    
    public var id: String {
        switch self {
            case .welcome:
                return "welcome"
            case .shop:
                return "shop"
                
            case .mastodonLogin:
                return "login"
            case .post:
                return "post"
            case .safari:
                return "safari"
            case .shareImage:
                return "shareImage"
        }
    }
    
    public var isCover: Bool {
        switch self {
            case .welcome:
                return true
            case .shop:
                return true
                
            case .mastodonLogin:
                return false
            case .post:
                return false
            case .safari:
                return false
            case .shareImage:
                return false
        }
    }
}

public enum RouterDestination: Hashable {
    case settings
    case privacy
    case appearence
    case account(acc: Account)
    case post(status: Status)
    case about
    case contacts
    case timeline(timeline: TimelineFilter?)
}

extension RouterDestination {
    static let allSettings: [RouterDestination] = [.settings, .privacy, .about, .appearence]
}

extension View {
    func withAppRouter(_ navigator: Navigator) -> some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
                case .settings:
                    SettingsView(navigator: navigator)
                case .privacy:
                    PrivacyView()
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
    
    @available(*, deprecated, renamed: "withSheets", message: "These two cannot support themselves")
    func withOver(sheetDestination: Binding<SheetDestination?>) -> some View {
        self
            .withCovers(sheetDestination: sheetDestination)
            .withSheets(sheetDestination: sheetDestination)
    }
    
    @available(*, deprecated,  message: "Causes bugs with sheets to display as covers")
    private func viewRepresentation(destination: SheetDestination, isCover: Bool) -> some View {
        Group {
            if destination.isCover {
                switch destination {
                    case .welcome:
                        ConnectView()
                    case .shop:
                        ShopView()
                    default:
                        EmptySheetView(destId: destination.id)
                }
            } else {
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
                    default:
                        EmptySheetView(destId: destination.id)
                }
            }
        }
    }
    
    private func viewCover(destination: SheetDestination) -> some View {
        Group {
            switch destination {
                case .welcome:
                    ConnectView()
                case .shop:
                    ShopView()
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
