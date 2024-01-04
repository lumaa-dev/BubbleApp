//Made by Lumaa

import SwiftUI

struct AppearenceView: View {
    @ObservedObject private var userPreferences: UserPreferences = .defaultPreferences
    @Environment(Navigator.self) private var navigator: Navigator
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
            do {
                let oldPreferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
                
                userPreferences.displayedName = oldPreferences.displayedName
                userPreferences.profilePictureShape = oldPreferences.profilePictureShape
                
                userPreferences.experimental.replySymbol = oldPreferences.experimental.replySymbol
            } catch {
                print(error)
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    do {
                        let oldPreferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
                        
                        userPreferences.displayedName = oldPreferences.displayedName
                        userPreferences.profilePictureShape = oldPreferences.profilePictureShape
                        
                        userPreferences.experimental.replySymbol = oldPreferences.experimental.replySymbol
                        
                        dismiss()
                    } catch {
                        print(error)
                        dismiss()
                    }
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
}

#Preview {
    AppearenceView()
}
