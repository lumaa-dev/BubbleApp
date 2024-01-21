//Made by Lumaa

import SwiftUI

struct PostMenu: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(Navigator.self) private var navigator
    @Environment(\.displayScale) private var displayScale
    
    var status: Status
    
    var body: some View {
        Menu {
            Button(role: .destructive) {
                print("Delete")
            } label: {
                Label("status.menu.delete", systemImage: "trash")
            }
            
            Button {
                print("Edit")
            } label: {
                Label("status.menu.edit", systemImage: "pencil.and.scribble")
            }
            
            Divider()
            
            Menu {
                ShareLink(item: URL(string: status.url ?? "https://joinmastodon.org/")!) {
                    Label("status.menu.share-link", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    Task {
                        await createImage()
                    }
                } label: {
                    Label("status.menu.share-image", systemImage: "photo")
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
            navigator.presentedSheet = .shareImage(image: image)
        }
    }
}
