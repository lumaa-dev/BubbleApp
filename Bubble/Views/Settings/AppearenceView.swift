//Made by Lumaa

import SwiftUI

// TODO: Show/hide profile header

struct AppearenceView: View {
    @ObservedObject private var userPreferences: UserPreferences = .defaultPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Picker(LocalizedStringKey("setting.appearence.displayed-name"), selection: $userPreferences.displayedName) {
                ForEach(UserPreferences.DisplayedName.allCases, id: \.self) { displayCase in
                    switch (displayCase) {
                        case .username:
                            Text("setting.appearence.displayed-name.username")
                                .tag(UserPreferences.DisplayedName.username)
                        case .displayName:
                            Text("setting.appearence.displayed-name.display-name")
                                .tag(UserPreferences.DisplayedName.displayName)
                        case .both:
                            Text("setting.appearence.displayed-name.both")
                                .tag(UserPreferences.DisplayedName.both)
                    }
                }
            }
            .pickerStyle(.inline)
            .listRowThreaded()
            
            Picker(LocalizedStringKey("setting.appearence.pfp-shape"), selection: $userPreferences.profilePictureShape) {
                ForEach(UserPreferences.ProfilePictureShape.allCases, id: \.self) { displayCase in
                    switch (displayCase) {
                        case .circle:
                            Text("setting.appearence.pfp-shape.circle")
                                .tag(UserPreferences.ProfilePictureShape.circle)
                        case .rounded:
                            Text("setting.appearence.pfp-shape.rounded")
                                .tag(UserPreferences.ProfilePictureShape.rounded)
                    }
                }
            }
            .pickerStyle(.inline)
            .listRowThreaded()
            
            Picker(LocalizedStringKey("setting.appearence.browser"), selection: $userPreferences.browserType) {
                ForEach(UserPreferences.BrowserType.allCases, id: \.self) { type in
                    switch (type) {
                        case .inApp:
                            Text("setting.appearence.browser.in-app")
                                .tag(UserPreferences.BrowserType.inApp)
                        case .outApp:
                            Text("setting.appearence.browser.out-app")
                                .tag(UserPreferences.BrowserType.outApp)
                    }
                }
            }
            .pickerStyle(.inline)
            .listRowThreaded()
            
            if userPreferences.showExperimental {
                Section(header: Text("experimental")) {
                    Toggle(LocalizedStringKey("setting.appearence.reply-symbols"), isOn: $userPreferences.experimental.replySymbol)
                        .listRowThreaded()
                }
            }
        }
        .listThreaded()
        .navigationTitle("setting.appearence")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            loadOld()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    loadOld()
                    dismiss()
                } label: {
                    Text("settings.cancel")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    do {
                        try userPreferences.saveAsCurrent()
                        dismiss()
                    } catch {
                        print(error)
                    }
                } label: {
                    Text("settings.done")
                }
            }
        }
    }
    
    private func loadOld() {
        do {
            let oldPreferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
            
            userPreferences.displayedName = oldPreferences.displayedName
            userPreferences.profilePictureShape = oldPreferences.profilePictureShape
            userPreferences.browserType = oldPreferences.browserType
            
            userPreferences.experimental.replySymbol = oldPreferences.experimental.replySymbol
        } catch {
            print(error)
            dismiss()
        }
    }
}

#Preview {
    AppearenceView()
}
