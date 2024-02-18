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
                return MovieFileTransferable(url: receivedTransferrable.localURL)
            }
            FileRepresentation(importedContentType: .video) { receivedTransferrable in
                return MovieFileTransferable(url: receivedTransferrable.localURL)
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
                return GifFileTranseferable(url: receivedTransferrable.localURL)
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
                return ImageFileTranseferable(url: receivedTransferrable.localURL)
            }
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

public extension ReceivedTransferredFile {
    var localURL: URL {
        if self.isOriginalFile {
            return file
        }
        let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(self.file.pathExtension)")
        try? FileManager.default.copyItem(at: self.file, to: copy)
        return copy
    }
    
}
public extension URL {
    func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            mimeType
        } else {
            "application/octet-stream"
        }
    }
    
    static let placeholder: URL = URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg")!
}
