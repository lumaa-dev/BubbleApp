//Made by Lumaa

import SwiftUI
import Nuke
import NukeUI

struct OnlineImage: View {
    var url: URL?
    var size: CGFloat? = 500
    var maxSize: CGFloat? = 500
    var priority: ImageRequest.Priority = .normal
    var useNuke: Bool = true
    
    var body: some View {
        if useNuke {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(idealWidth: size, maxWidth: maxSize)
                } else if state.error != nil {
                    ContentUnavailableView("error.loading-image", systemImage: "rectangle.slash")
                } else {
                    Rectangle()
                        .fill(Color.gray)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                }
            }
            .priority(priority)
            .processors([.resize(width: size ?? 500)])
        } else {
            AsyncImage(url: url) { element in
                element
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(minWidth: size, maxWidth: maxSize, alignment: .topLeading)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
            }
        }
    }
    
    init(url: URL? = nil, useNuke: Bool) {
        self.url = url
        self.size = 500
        self.priority = .normal
        self.useNuke = useNuke
    }
    
    /// Creates a new OnlineImage using Nuke or not, default priority is .normal
    init(url: URL? = nil, size: CGFloat, useNuke: Bool) {
        self.url = url
        self.size = size
        self.priority = .normal
        self.useNuke = useNuke
    }
    
    /// Creates a new OnlineImage using Nuke, using the selected priority
    init(url: URL? = nil, size: CGFloat, priority: ImageRequest.Priority) {
        self.url = url
        self.size = size
        self.priority = priority
        self.useNuke = true
    }
    
    init(url: URL? = nil, maxSize: CGFloat, useNuke: Bool) {
        self.url = url
        self.maxSize = maxSize
        self.size = nil
        self.priority = .normal
        self.useNuke = useNuke
    }
    
    /// Creates a new OnlineImage using Nuke, using the selected priority
    init(url: URL? = nil, maxSize: CGFloat, priority: ImageRequest.Priority) {
        self.url = url
        self.maxSize = maxSize
        self.size = nil
        self.priority = priority
        self.useNuke = true
    }
    
    init(url: URL? = nil, size: CGFloat, maxSize: CGFloat, useNuke: Bool) {
        self.url = url
        self.maxSize = maxSize
        self.size = size
        self.priority = .normal
        self.useNuke = useNuke
    }
    
    /// Creates a new OnlineImage using Nuke, using the selected priority
    init(url: URL? = nil, size: CGFloat, maxSize: CGFloat, priority: ImageRequest.Priority) {
        self.url = url
        self.maxSize = maxSize
        self.size = size
        self.priority = priority
        self.useNuke = true
    }
    
    /// Change the priority of the Nuke OnlineImage
    mutating func setPriority(_ priority: ImageRequest.Priority) {
        guard self.useNuke == true else { return }
        self.priority = priority
    }
}
