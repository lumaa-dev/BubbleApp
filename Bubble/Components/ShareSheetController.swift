//Made by Lumaa

import Foundation
import SwiftUI
import UIKit
import LinkPresentation

/// Share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let status: Status
    
    class ActivityPreview: NSObject, UIActivityItemSource {
        let image: UIImage
        let status: Status
        
        init(image: UIImage, status: Status) {
            self.image = image
            self.status = status
        }
        
        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            image
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            nil
        }
        
        func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
            let metadata = LPLinkMetadata()
            metadata.imageProvider = NSItemProvider(object: image)
            metadata.title = status.reblogAsAsStatus?.content.asRawText ?? status.content.asRawText + String("\n\n\(status.url ?? AppInfo.website)")
            return metadata
        }
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image, ActivityPreview(image: image, status: status)], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
