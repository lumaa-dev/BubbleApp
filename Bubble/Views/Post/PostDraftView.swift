// Made by Lumaa

import SwiftUI
import SwiftData

struct PostDraftView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction

    @Query private var drafts: [StatusDraft]

    @Binding var selectedDraft: StatusDraft?

    var body: some View {
        NavigationStack {
            if drafts.count > 0 {
                List {
                    ForEach(drafts, id: \.self) { draft in
                        Button {
                            selectedDraft = draft
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                TextEmoji(HTMLString(stringValue: draft.content), emojis: accountManager.forceAccount().emojis)
                                    .lineLimit(3, reservesSpace: true)
                                    .font(.callout)

//                            Label("status.drafts.attachments-\(draft.attachments.count)", systemImage: draft.attachments.count > 1 ? "photo.on.rectangle.angled" : "photo")
//                                .multilineTextAlignment(.leading)
//                                .font(.caption)
//                                .foregroundStyle(Color.gray)
//                                .lineLimit(1, reservesSpace: false)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(7.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                        .listRowThreaded()
                    }
                }
                .listThreaded()
            } else {
                ContentUnavailableView("status.drafts.empty", systemImage: "plus.circle.dashed")
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents(drafts.count > 0 ? [.large] : [.medium, .large])
    }
}
