//Made by Lumaa

import SwiftUI

struct EmojiSelector: View {
    @Environment(AccountManager.self) private var accountManager
    
    @State private var loading: Bool = true
    @State private var emojiContainers: [CategorizedEmojiContainer] = []
    
    @Binding var viewModel: PostingView.ViewModel
    
    var body: some View {
        if loading {
            ProgressView()
                .ignoresSafeArea()
                .task {
                    await fetchCustomEmojis()
                }
        } else if !loading && !emojiContainers.isEmpty {
            ScrollView(.vertical, showsIndicators: false) {
                ForEach(emojiContainers) { container in
                    LazyVGrid(columns: [.init(.adaptive(minimum: 40, maximum: 40))]) {
                        Section {
                            ForEach(container.emojis) { emoji in
                                Button {
                                    viewModel.append(text: ":\(emoji.shortcode):")
                                } label: {
                                    OnlineImage(url: emoji.url, size: 40, priority: .low)
                                }
                                .buttonStyle(NoTapAnimationStyle())
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.vertical)
        } else {
            ContentUnavailableView("status.posting.no-emojis", systemImage: "network.slash")
        }
    }
    
    struct CategorizedEmojiContainer: Identifiable, Equatable {
        let id = UUID().uuidString
        let categoryName: String
        var emojis: [Emoji]
    }
    
    private func fetchCustomEmojis() async {
        typealias EmojiContainer = CategorizedEmojiContainer
        
        guard let client = accountManager.getClient() else { return }
        do {
            let customEmojis: [Emoji] = try await client.get(endpoint: CustomEmojis.customEmojis) ?? []
            var emojiContainers: [EmojiContainer] = []
            
            customEmojis.reduce([String: [Emoji]]()) { currentDict, emoji in
                var dict = currentDict
                let category = emoji.category ?? "Custom"
                
                if let emojis = dict[category] {
                    dict[category] = emojis + [emoji]
                } else {
                    dict[category] = [emoji]
                }
                
                return dict
            }.sorted(by: { lhs, rhs in
                if rhs.key == "Custom" { false }
                else if lhs.key == "Custom" { true }
                else { lhs.key < rhs.key }
            }).forEach { key, value in
                emojiContainers.append(.init(categoryName: key, emojis: value))
            }
            
            self.emojiContainers = emojiContainers
        } catch {}
    }
}
