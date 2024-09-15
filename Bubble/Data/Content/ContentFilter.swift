//Made by Lumaa

import Foundation
import SwiftUI
import SwiftData

/// A content filter designed for posts and its author
protocol PostFilter {
    var type: ContentFilter.FilterContentType { get }
    var categoryName: String { get }
    var content: [String] { get set }
    var post: Status? { get set }
    
    func setContent(_ content: [String])
    func filter(_ post: Status, type: ContentFilter.FilterType) -> Bool
    func filter(_ post: Status, type: ContentFilter.FilterType, manualEdit: @escaping (String) -> Void) -> Bool
}

extension PostFilter {
    func willFilter(_ content: String) -> Bool {
        return self.content.contains(where: { $0 == content.lowercased() })
    }
    
    func willFilter(_ content: HTMLString) -> Bool {
        let string = content.asRawText
        let words: [String] = string.split(separator: " ").map({ String($0) })
        return self.willFilter(words)
    }
    
    func willFilter(_ content: [String]) -> Bool {
        for word in content {
            if self.content.contains(where: { $0 == word.lowercased() }) {
                return true
            }
        }
        return false
    }
    
    func willFilter(_ content: String) -> String? {
        if self.content.contains(where: { $0 == content.lowercased() }) {
            return content
        }
        return nil
    }
    
    func willFilter(_ content: HTMLString) -> [String] {
        let string = content.asMarkdown
        let words: [String] = string.split(separator: " ").map({ String($0) })
        return self.willFilter(words)
    }
    
    func willFilter(_ content: [String]) -> [String] {
        var sensitive: [String] = []
        for word in content {
            if self.content.contains(where: { $0 == word.lowercased() }) {
                sensitive.append(word)
            }
        }
        return sensitive
    }
}

class ContentFilter {
    static let defaultFilter: ContentFilter.WordFilter = .init(categoryName: "Default", words: [])
    
    class WordFilter: PostFilter {
        let type: ContentFilter.FilterContentType = .words
        let categoryName: String
        var content: [String]
        var post: Status?
        
        init(categoryName: String, words: [String]) {
            self.categoryName = categoryName
            let rearranged: [String] = words.compactMap({ $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }).uniqued()
            self.content = rearranged
        }
        
        init(model: ModelFilter) {
            self.categoryName = model.name
            self.content = model.sensitive
        }
        
        func setContent(_ content: [String]) {
            let rearranged: [String] = content.compactMap({ $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }).uniqued()
            self.content = rearranged
        }
        
        func filter(_ post: Status, type: ContentFilter.FilterType = .remove) -> Bool {
            self.setPost(post)
            if type == .censor {
                let sensitives: [String] = self.willFilter(post.content)
                for word in sensitives {
                    post.content.asMarkdown = self.post!.content.asMarkdown.replacingOccurrences(of: word, with: "***")
                    post.content.asSafeMarkdownAttributedString = self.post!.content.asSafeMarkdownAttributedString.replacing(word, with: "")
                }
                
                return !sensitives.isEmpty
            } else {
                let includesSensitive: Bool = self.willFilter(post.content)
                return includesSensitive
            }
        }
        
        func filter(_ post: Status, type: ContentFilter.FilterType = .remove, manualEdit: @escaping (String) -> Void = {_ in}) -> Bool {
            self.setPost(post)
            if type == .censor {
                let sensitives: [String] = self.willFilter(post.content)
                for word in sensitives {
                    manualEdit(word)
                }
                
                return !sensitives.isEmpty
            } else {
                let includesSensitive: Bool = self.willFilter(post.content)
                return includesSensitive
            }
        }
        
        private func setPost(_ post: Status?) {
            if let p = post {
                self.post = p
            }
        }
    }
    
    class URLFilter: PostFilter {
        var type: ContentFilter.FilterContentType = .url
        let categoryName: String
        var content: [String]
        var post: Status?
        
        init(categoryName: String, urls: [URL]) {
            self.categoryName = categoryName
            let rearranged: [String] = urls.compactMap({ $0.host() ?? "https://example.com" }).uniqued()
            self.content = rearranged
        }
        
        init(model: ModelFilter) {
            self.categoryName = model.name
            self.content = model.sensitive
        }
        
        func setContent(_ content: [String]) {
            let rearranged: [String] = content.compactMap({ $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }).uniqued()
            self.content = rearranged
        }
        
        func setContent(_ content: [URL]) {
            let rearranged: [String] = content.compactMap({ $0.host() ?? "example.com" }).uniqued()
            self.content = rearranged
        }
        
        func filter(_ post: Status, type: ContentFilter.FilterType = .remove) -> Bool {
            self.setPost(post)
            if type == .censor {
                let sensitives: [String] = self.willFilter(post.content)
                for word in sensitives {
                    post.content.asMarkdown = self.post!.content.asMarkdown.replacingOccurrences(of: word, with: "***")
                    post.content.asSafeMarkdownAttributedString = self.post!.content.asSafeMarkdownAttributedString.replacing(word, with: "")
                }
                
                return !sensitives.isEmpty
            } else {
                let includesSensitive: Bool = self.willFilter(post.content)
                return includesSensitive
            }
        }
        
        func filter(_ post: Status, type: ContentFilter.FilterType = .remove, manualEdit: @escaping (String) -> Void = {_ in}) -> Bool {
            self.setPost(post)
            if type == .censor {
                let sensitives: [String] = self.willFilter(post.content)
                for word in sensitives {
                    manualEdit(word)
                }
                
                return !sensitives.isEmpty
            } else {
                let includesSensitive: Bool = self.willFilter(post.content)
                return includesSensitive
            }
        }
        
        private func setPost(_ post: Status?) {
            if let p = post {
                self.post = p
            }
        }
    }
    
    enum FilterContentType: String, Codable {
        case words = "words"
        case url = "url"
    }
    
    enum FilterType: String, CaseIterable {
        case censor
        case remove
        
        var localized: String {
            switch self {
                case .censor:
                    String(localized: "status.content-filter.censor")
                case .remove:
                    String(localized: "status.content-filter.remove")
            }
        }
        
        @ViewBuilder
        var label: some View {
            switch self {
                case .censor:
                    Label(self.localized, systemImage: "asterisk")
                case .remove:
                    Label(self.localized, systemImage: "text.badge.xmark")
            }
        }
    }
}

@Model
class ModelFilter {
    let name: String
    let sensitive: [String]
    let type: ContentFilter.FilterContentType
    
    init(name: String, sensitive: [String], type: ContentFilter.FilterContentType = .words) {
        self.name = name
        self.sensitive = sensitive
        self.type = type
    }
    
    init(postFilter: PostFilter) {
        self.name = postFilter.categoryName
        self.sensitive = postFilter.content
        self.type = postFilter.type
    }
}

extension NSAttributedString {
    func replacing(_ placeholder: String, with valueString: String) -> NSAttributedString {
        if let range = self.string.range(of: placeholder) {
            let nsRange = NSRange(range, in: self.string) // Corrected to use self.string
            let mutableText = NSMutableAttributedString(attributedString: self)
            mutableText.replaceCharacters(in: nsRange, with: valueString)
            return mutableText as NSAttributedString
        }
        return self
    }
}

extension AttributedString {
    func replacing(_ placeholder: String, with valueString: String) -> AttributedString {
        let ns = NSAttributedString(self)
        let replaced = ns.replacing(placeholder, with: valueString)
        return AttributedString(replaced)
    }
}
