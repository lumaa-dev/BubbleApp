//Made by Lumaa

import SwiftUI

struct EditProfileView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var navigator: Navigator
    
    @State private var display: String = ""
    @State private var bio: String = ""
    @State private var fields: [EditField] = []
    @State private var nsfw: Bool = false
    @State private var bot: Bool = false
    @State private var `private`: Bool = false
    @State private var discoverable: Bool = false
    
    @State private var applying: Bool = false
    
    var body: some View {
        if accountManager.getAccount() !== nil {
            NavigationStack {
                form
            }
        } else {
            ProgressView()
                .onAppear {
                    dismiss()
                }
        }
    }
    
    var form: some View {
        Form {
            Section(header: Text("account.edit.info")) {
                TextField("account.edit.display", text: $display, axis: .horizontal)
                
                TextField("account.edit.bio", text: $bio, axis: .vertical)
                    .frame(maxHeight: 200)
            }
            
            Section(header: Text("account.edit.fields")) {
                ForEach($fields) { $field in
                    VStack(alignment: .leading) {
                        if $field.canEdit.wrappedValue {
                            TextField("account.edit.field.name", text: $field.name)
                                .bold()
                            TextField("account.edit.field.value", text: $field.value)
                        } else {
                            Text($field.name.wrappedValue)
                                .bold()
                            Text($field.value.wrappedValue)
                        }
                    }
                }
                .onMove { i, ii in
                    fields.move(fromOffsets: i, toOffset: ii)
                }
                .onDelete { i in
                    fields.remove(atOffsets: i)
                }
                
                if fields.count < 4 {
                    Button {
                        withAnimation(.spring) {
                            fields.append(.init(name: "", value: ""))
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.multicolor)
                            
                            Text("account.edit.fields.add")
                                .foregroundStyle(Color.green)
                        }
                    }
                }
            }
            
            Section(header: Text("account.edit.properties")) {
                Toggle("account.edit.private", isOn: $private)
                    .tint(.green)
                Toggle("account.edit.sensitive", isOn: $nsfw)
                    .tint(.green)
                Toggle("account.edit.bot", isOn: $bot)
                    .tint(.green)
                Toggle("account.edit.discoverable", isOn: $discoverable)
                    .tint(.green)
            }
        }
        .formThreaded()
        .scrollDismissesKeyboard(.immediately)
        .task {
            if let acc = await accountManager.fetchAccount() {
                display = acc.displayName ?? ""
                bio = acc.note.asRawText
                fields = acc.fields.map({ .init(name: $0.name, value: $0.value.asRawText) })
                `private` = acc.locked
                nsfw = acc.source?.sensitive ?? false
                bot = acc.bot
                discoverable = acc.discoverable ?? true
            } else {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("account.edit.cancel")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        applying = true
                        if let acc = accountManager.getAccount(), let client = accountManager.getClient() {
                            let data = UpdateCredentialsData(displayName: display, note: bio, source: .init(privacy: acc.source?.privacy ?? Visibility.pub, sensitive: nsfw), bot: bot, locked: `private`, discoverable: discoverable, fieldsAttributes: fields.map { .init(name: $0.name, value: $0.value) })
                            
                            _ = try await client.patch(endpoint: Accounts.updateCredentials(json: data))
                            HapticManager.playHaptics(haptics: Haptic.success)
                            dismiss()
                        }
                        applying = false
                    }
                } label: {
                    if applying {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("account.edit.apply")
                            .bold()
                    }
                }
                .disabled(applying)
            }
        }
        .interactiveDismissDisabled()
        .navigationTitle(Text("account.edit"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .presentationDetents([.medium, .large])
    }
}

private extension View {
    func formThreaded(tint: Color = Color(uiColor: UIColor.label)) -> some View {
        self
            .scrollContentBackground(.hidden)
            .tint(tint)
            .background(Color.appBackground)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .listStyle(.insetGrouped)
    }
}

class EditField: Identifiable {
    let id: UUID = UUID()
    public var name: String =  ""
    public var value: String = ""
    public var canEdit: Bool = true
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    init(name: String, value: String, canEdit: Bool = true) {
        self.name = name
        self.value = value
        self.canEdit = canEdit
    }
}

#Preview {
    EditProfileView()
}
