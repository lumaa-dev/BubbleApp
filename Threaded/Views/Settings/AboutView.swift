//Made by Lumaa

import SwiftUI

struct AboutView: View {
    @ObservedObject private var userPreferences: UserPreferences = .defaultPreferences
    @EnvironmentObject private var navigator: Navigator
    
    var body: some View {
        List {
            Section(footer: Text("about.version-\(AppInfo.appVersion)")) {
                NavigationLink {
                    aboutApp
                } label: {
                    Text("about.app")
                }
                .listRowThreaded()
                
                Toggle("setting.experimental.activate", isOn: $userPreferences.showExperimental)
                    .listRowThreaded()
                    .tint(Color(uiColor: UIColor.label))
                    .disabled(!AppDelegate.hasPlus())
                    .onAppear {
                        do {
                            let oldPreferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
                            
                            userPreferences.showExperimental = oldPreferences.showExperimental && AppDelegate.hasPlus()
                        } catch {
                            print(error)
                        }
                    }
            }
        }
        .listThreaded()
        .navigationTitle("about")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            do {
                if !userPreferences.showExperimental {
                    userPreferences.experimental = .init()
                }
                try userPreferences.saveAsCurrent()
            } catch {
                print(error)
            }
        }
    }
    
    var aboutApp: some View {
        // TODO: Change this entire ugly thing
        List {
            Text("about.app.details")
                .multilineTextAlignment(.leading)
                .listRowThreaded()
            Text("about.app.third-party")
                .multilineTextAlignment(.leading)
                .listRowThreaded()
        }
        .padding(.horizontal)
        .listThreaded(tint: Color.blue)
        .navigationTitle("about.app")
        .navigationBarTitleDisplayMode(.large)
    }
}
