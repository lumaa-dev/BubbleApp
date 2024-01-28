//Made by Lumaa

import SwiftUI
import UniformTypeIdentifiers

struct PostMenu: View {
    @Environment(Navigator.self) private var navigator
    @Environment(AccountManager.self) private var accountManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    
    var status: Status
    
    private var isOwner: Bool {
        if let acc = accountManager.getAccount() {
            return status.account.id == acc.id
        }
        return false
    }
    
    var body: some View {
        Menu {
            if isOwner {
                Button(role: .destructive) {
                    Task {
                        await deleteStatus()
                    }
                } label: {
                    Label("status.menu.delete", systemImage: "trash")
                }
                
                Button {
                    navigator.presentedSheet = .post(content: status.reblogAsAsStatus?.content.asRawText ?? status.content.asRawText, replyId: nil, editId: status.reblogAsAsStatus?.id ?? status.id)
                } label: {
                    Label("status.menu.edit", systemImage: "pencil.and.scribble")
                }
                
                Divider()
            }
            
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
            } label: {
                Label("status.menu.share", systemImage: "paperplane")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Color.white.opacity(0.3))
                .font(.body)
        }
    }
    
    @MainActor
    private func createImage() {
        let view = HStack {
            CompactPostView(status: status, navigator: Navigator(), imaging: true)
                .padding(15)
                .background(Color.appBackground)
        }
        .environment(\.colorScheme, colorScheme == .dark ? .dark : .light)
        .environment(AccountManager())
        .environment(Navigator())
        .environment(AppDelegate())
        
        let render = ImageRenderer(content: view)
        render.scale = displayScale
        render.isOpaque = false
        
        if let image = render.uiImage {
            navigator.presentedSheet = .shareImage(image: image, status: status)
        }
    }
    
    private func deleteStatus() async {
        if let client = accountManager.getClient() {
            _ = try? await client.delete(endpoint: Statuses.status(id: status.id))
            if navigator.path.last == .post(status: status) {
                dismiss()
            }
        }
    }
}
