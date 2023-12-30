//Made by Lumaa

import Foundation
import SwiftUI

// Doesn't seem to work?
struct AsyncImageTransferable: Codable, Transferable {
    let url: URL
    
    func fetchAsImage() async -> Image {
        let data = try? await URLSession.shared.data(from: url).0
        guard let data, let uiimage = UIImage(data: data) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: uiimage)
    }
    
    // MARK: A synchronous exporter should be used
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { media in
            await media.fetchAsImage()
        }
    }
}
