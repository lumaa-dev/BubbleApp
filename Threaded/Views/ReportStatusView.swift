// Made by Lumaa

import SwiftUI

struct ReportStatusView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction

    var status: Status

    @State private var comment: String = ""
    @State private var confirmationAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("status.report.comment", text: $comment, axis: .vertical)
                        .frame(maxHeight: 300)

                    Button {
                        confirmationAlert.toggle()
                    } label: {
                        Text("status.report")
                            .foregroundStyle(Color.red)
                            .bold()
                    }
                }

                Section(header: Text("status.report.preview"), footer: Text("status.report.preview.footer")) {
                    StatusPreview(status: status)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("status.report.cancel")
                    }
                }

//                ToolbarItem(placement: .confirmationAction) {
//                    Button {
//                        confirmationAlert.toggle()
//                    } label: {
//                        Text("status.report")
//                            .foregroundStyle(Color.red)
//                    }
//                }
            }
            .alert(
                "general.report.confirm",
                isPresented: $confirmationAlert,
                actions: {
                    Button(role: .destructive) {
                        Task {
                            if comment.isEmpty {
                                await reportStatus()
                            } else {
                                await reportStatus(comment: comment)
                            }
                            HapticManager.playHaptics(haptics: Haptic.success)
                            dismiss()
                        }
                    } label: {
                        Text("general.report.confirm.ok")
                    }

                    Button(role: .cancel) {} label: {
                        Text("general.report.confirm.cancel")
                    }
                },
                message: { Text("general.report.confirm.message") }
            )
            .navigationTitle(Text("status.report.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func reportStatus(comment: String = "*No information was given*") async {
        if let client = accountManager.getClient() {
            _ = try? await client
                .post(
                    endpoint: Statuses
                        .report(
                            accountId: status.account.id,
                            statusId: status.id,
                            comment: comment
                        )
                )
        }
    }

    struct StatusPreview: View {
        var status: Status

        var body: some View {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading) {
                    // MARK: Status main content
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(status.account.acct)")
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                                .bold()

                            if status.inReplyToAccountId != nil {
                                if let user = status.mentions.first(where: { $0.id == status.inReplyToAccountId }) {
                                    Text("status.replied-to.\(user.username)")
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.3))
                                }
                            }
                        }

                        if !status.content.asRawText.isEmpty {
                            TextEmoji(status.content, emojis: status.emojis, language: status.language)
                                .multilineTextAlignment(.leading)
                                .frame(width: 300, alignment: .topLeading)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.callout)
                                .contentShape(Rectangle())
                        }

                        attachmnts
                    }
                }
            }
        }

        @ViewBuilder
        var attachmnts: some View {
            if !status.mediaAttachments.isEmpty {
                if status.mediaAttachments.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            ForEach(status.mediaAttachments) { attachment in
                                PostAttachment(attachment: attachment, isFeatured: false)
                                    .blur(radius: status.sensitive ? 15.0 : 0)
                            }
                        }
                    }
                    .scrollClipDisabled()
                } else {
                    PostAttachment(attachment: status.mediaAttachments.first!)
                }
            }
        }
    }
}

#Preview("FR") {
    ReportStatusView(status: .placeholder())
        .environment(AccountManager())
        .environment(\.locale, Locale(identifier: "fr-fr"))
}

#Preview("Sheet") {
    ZStack {
        Text(String("Hello world!"))
    }
    .interactiveDismissDisabled()
    .presentationDragIndicator(.hidden)
    .sheet(isPresented: .constant(true)) {
        ReportStatusView(status: .placeholder())
            .environment(AccountManager())
    }
}
