//Made by Lumaa

import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// Dimillian fixed it - https://mastodon.social/@dimillian/111708477095374920

struct ShareableOnlineImage: Codable, Transferable {
    let url: URL
    
    func fetchAsImage() -> Image {
        let data = try? Data(contentsOf: url)
        guard let data, let uiimage = UIImage(data: data) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: uiimage)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { media in
            media.fetchAsImage()
        }
    }
}

extension PostingView {
    final class MovieFileTransferable: Transferable, Sendable {
        let url: URL
        
        init(url: URL) {
            self.url = url
            _ = url.startAccessingSecurityScopedResource()
        }
        
        deinit {
            url.stopAccessingSecurityScopedResource()
        }
        
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(importedContentType: .movie) { receivedTransferrable in
                return MovieFileTransferable(url: receivedTransferrable.file)
            }
            FileRepresentation(importedContentType: .video) { receivedTransferrable in
                return MovieFileTransferable(url: receivedTransferrable.file)
            }
        }
    }
    
    final class GifFileTranseferable: Transferable, Sendable {
        let url: URL
        
        init(url: URL) {
            self.url = url
            _ = url.startAccessingSecurityScopedResource()
        }
        
        deinit {
            url.stopAccessingSecurityScopedResource()
        }
        
        var data: Data? {
            try? Data(contentsOf: url)
        }
        
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(importedContentType: .gif) { receivedTransferrable in
                return GifFileTranseferable(url: receivedTransferrable.file)
            }
        }
    }
}

extension PostingView {
    final class ImageFileTranseferable: Transferable, Sendable {
        public let url: URL
        
        init(url: URL) {
            self.url = url
            _ = url.startAccessingSecurityScopedResource()
        }
        
        deinit {
            url.stopAccessingSecurityScopedResource()
        }
        
        public static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(importedContentType: .image) { receivedTransferrable in
                return ImageFileTranseferable(url: receivedTransferrable.file)
            }
        }
    }
}
