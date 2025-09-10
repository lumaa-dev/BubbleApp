//Made by Lumaa

import SwiftUI
import UniformTypeIdentifiers

struct PostMenu: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    
    var status: Status
    private var pref: UserPreferences {
        try! UserPreferences.loadAsCurrent()
    }
    
    private var isOwner: Bool {
        if let acc = accountManager.getAccount() {
            return status.reblogAsAsStatus?.account.id ?? status.account.id == acc.id
        }
        return false
    }

    var body: some View {
        Menu {
            ShareLink(item: URL(string: status.url ?? "https://joinmastodon.org/")!) {
                Label("status.menu.share-link", systemImage: "square.and.arrow.up")
            }

            Button {
                Task {
                    createImage()
                }
            } label: {
                Label("status.menu.share-image", systemImage: "photo")
            }

            Divider()

            Button {
                UIPasteboard.general.setValue(status.reblogAsAsStatus?.content.asRawText ?? status.content.asRawText, forPasteboardType: UTType.plainText.identifier)
            } label: {
                Label("status.menu.copy-text", systemImage: "list.clipboard")
            }

            if isOwner {
                altClients
            }
        } label: {
            Label("status.menu.share", systemImage: "paperplane")
        }

        Divider()

        ownerAct

        Button(role: .destructive) {
            Navigator.shared.presentedSheet = .reportStatus(status: status)
        } label: {
            Label("status.menu.report", systemImage: "exclamationmark.triangle.fill")
        }
    }

    @ViewBuilder
    private var ownerAct: some View {
        if isOwner {
            Button(role: .destructive) {
                Task {
                    await deleteStatus()
                }
            } label: {
                Label("status.menu.delete", systemImage: "trash")
            }

            Button {
                Navigator.shared.presentedSheet = .post(content: status.reblogAsAsStatus?.content.asRawText ?? status.content.asRawText, replyId: nil, editId: status.reblogAsAsStatus?.id ?? status.id)
            } label: {
                Label("status.menu.edit", systemImage: "pencil.and.scribble")
            }

            Divider()
        }
    }

    @ViewBuilder
    private var altClients: some View {
        let content: String = status.reblogAsAsStatus?.content.asRawText ?? status.content.asRawText

        Menu {
            Button {
                openURL(URL(string: AltClients.IvoryApp.createPost(content))!)
            } label: {
                Text(AltClients.IvoryApp.name)
            }

            Button {
                openURL(URL(string: AltClients.ThreadsApp.createPost(content))!)
            } label: {
                Text(AltClients.ThreadsApp.name)
            }

            Button {
                openURL(URL(string: AltClients.XApp.createPost(content))!)
            } label: {
                Text(AltClients.XApp.name)
            }
        } label: {
            Label("status.cross-post.alts", systemImage: "shuffle")
        }
    }

    @MainActor
    private func createImage() {
        let view = HStack {
            CompactPostView(status: status, imaging: true)
                .padding(15)
                .background(Color.appBackground)
        }
        .environment(\.colorScheme, colorScheme == .dark ? .dark : .light)
        .environment(AccountManager())
        .environment(AppDelegate())
        .environment(pref)
        
        let render = ImageRenderer(content: view)
        render.scale = displayScale
        render.isOpaque = false
        
        if let image = render.uiImage {
            Navigator.shared.presentedSheet = .shareImage(image: image, status: status)
        }
    }
    
    private func deleteStatus() async {
        if let client = accountManager.getClient() {
            _ = try? await client.delete(endpoint: Statuses.status(id: status.id))
            Navigator.shared.filter(.post(status: status))
        }
    }
}
