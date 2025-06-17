//Made by Lumaa

import SwiftUI

struct AboutView: View {
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate
    @Environment(\.openURL) private var openURL: OpenURLAction
    @ObservedObject private var userPreferences: UserPreferences = .defaultPreferences
    
    var body: some View {
        List {
            Section(footer: Text("about.version-\(AppInfo.appVersion)")) {
                Section {
                    NavigationLink {
                        aboutApp
                    } label: {
                        Text("about.app")
                    }
                    .listRowThreaded()
                    
                    Button {
                        if let url = URL(string: "https://lumaa.fr/?utm_source=BubbleApp") {
                            openURL(url)
                        }
                    } label: {
                        Text("about.lumaa")
                    }
                    .listRowThreaded()
                }

                Section {
                    Text("about.other")
                        .textCase(.lowercase)
                        .font(.callout.lowercaseSmallCaps())
                        .foregroundStyle(Color.gray)
                        .listRowBackground(Color.appBackground)

                    Button {
                        Navigator.shared.presentedSheet = .aboutSubclub
                    } label: {
                        Text("about.subclub")
                    }
                    .listRowThreaded()
                }

                Section {
                    Text(String("Bubble+"))
                        .textCase(.lowercase)
                        .font(.callout.lowercaseSmallCaps())
                        .foregroundStyle(Color.gray)
                        .listRowBackground(Color.appBackground)

                    Toggle("setting.experimental.activate", isOn: $userPreferences.showExperimental)
                        .listRowThreaded()
                        .tint(Color(uiColor: UIColor.label))
                        .disabled(!AppDelegate.premium)
                        .onAppear {
                            do {
                                let oldPreferences = try UserPreferences.loadAsCurrent()

                                userPreferences.showExperimental = oldPreferences.showExperimental && AppDelegate.premium
                            } catch {
                                print(error)
                            }
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
        ScrollView {
            VStack(alignment: .center) {
                Image("HeroIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                
                Text(String("Bubble"))
                    .font(.title.bold())
                
                Text(String("© Lumaa 2023-2025"))
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                
                Spacer()
                    .frame(height: 40)
                
                Text("about.app.details")
                    .multilineTextAlignment(.leading)
                    .frame(width: appDelegate.windowWidth - 50, alignment: .topLeading)
                    .padding()
                    .background(Material.bar)
                    .clipShape(.rect(cornerRadius: 7.5))
                
                Spacer()
                    .frame(height: 10)
                
                Text("about.app.third-party")
                    .multilineTextAlignment(.leading)
                    .frame(width: appDelegate.windowWidth - 50, alignment: .topLeading)
                    .padding()
                    .background(Material.bar)
                    .clipShape(.rect(cornerRadius: 7.5))
            }
            .padding()
        }
        .background(Color("AppBackground"))
        .navigationTitle("about.app")
        .navigationBarTitleDisplayMode(.inline)
    }
}
