//Made by Lumaa

import SwiftUI
import UIKit
import SafariServices

/// A SwiftUI representation of SFSafariViewController.
struct SfSafariView: UIViewControllerRepresentable {
    /// The URL to be opened in the Safari view.
    let url: URL
    
    /// Creates and returns a new instance of SFSafariViewController.
    /// - Parameter context: The context in which the Safari view controller is being created.
    /// - Returns: An instance of SFSafariViewController with the specified URL.
    func makeUIViewController(context: UIViewControllerRepresentableContext<SfSafariView>) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor.white
        
        return safari
    }
    
    /// Updates the Safari view controller when needed.
    /// - Parameters:
    ///   - uiViewController: The existing SFSafariViewController instance.
    ///   - context: The context in which the Safari view controller is being updated.
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SfSafariView>) {
        
    }
}
