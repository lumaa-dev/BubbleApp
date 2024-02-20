//Made by Lumaa

import SwiftUI

//TODO: Bring back "Privacy" with mutelist, blocklist and default visibility

struct SettingsView: View {
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    @StateObject var navigator: Navigator
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Section {
                    Button {
                        navigator.navigate(to: .about)
                    } label: {
                        Label("about", systemImage: "info.circle")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.presentedCover = .shop
                    } label: {
                        Label(String("Threaded+"), systemImage: "plus")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.navigate(to: .support)
                    } label: {
                        Label("setting.support", systemImage: "person.line.dotted.person")
                    }
                    .listRowThreaded()
                    
                    Button {
                        navigator.navigate(to: .appearence)
                    } label: {
                        Label("setting.appearence", systemImage: "rectangle.3.group")
                    }
                    .listRowThreaded()
                    
                    Button {
                        AppAccount.clear()
                        navigator.path = []
                        uniNav.selectedTab = .timeline
                        uniNav.presentedCover = .welcome
                    } label: {
                        Text("logout")
                            .foregroundStyle(.red)
                    }
                    .tint(Color.red)
                    .listRowThreaded()
                }
            }
            .withAppRouter(navigator)
            .withCovers(sheetDestination: $navigator.presentedCover)
            .listThreaded()
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView(navigator: .init())
}
