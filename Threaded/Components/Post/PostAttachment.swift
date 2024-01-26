//Made by Lumaa

import SwiftUI
import UIKit
import AVKit

struct PostAttachment: View {
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate
    var attachment: MediaAttachment
    
    var isFeatured: Bool = true
    var isImaging: Bool = false
    
    @State private var player: AVPlayer?
    
    var appLayoutWidth: CGFloat = 10
    var availableWidth: CGFloat {
        appDelegate.windowWidth * 0.8
    }
    var availableHeight: CGFloat {
        appDelegate.windowHeight
    }
    private let imageMaxHeight: CGFloat = 300
    
    
    var body: some View {
        let mediaSize: CGSize = size(for: attachment) ?? .init(width: imageMaxHeight, height: imageMaxHeight)
        let newSize = imageSize(from: mediaSize)
        
        if !isImaging {
            GeometryReader { _ in
                // Audio later because it's a lil harder
                if attachment.supportedType == .image {
                    if let url = attachment.url {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: !isFeatured ? imageMaxHeight / 1.5 : newSize.width, height: !isFeatured ? imageMaxHeight: newSize.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        } placeholder: {
                            ZStack(alignment: .center) {
                                Color.gray
                                
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                } else if attachment.supportedType == .gifv {
                    ZStack(alignment: .center) {
                        if player != nil {
                            NoControlsPlayerViewController(player: player!)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Color.gray
                            
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                    .onAppear {
                        if let url = attachment.url {
                            player = AVPlayer(url: url)
                            player?.audiovisualBackgroundPlaybackPolicy = .pauses
                            player?.isMuted = true
                            player?.play()
                            
                            guard let player else { return }
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                                Task { @MainActor in
                                    player.seek(to: CMTime.zero)
                                    player.play()
                                }
                            }
                        }
                    }
                    .onDisappear() {
                        guard player != nil else { return }
                        player?.pause()
                    }
                    
                } else if attachment.supportedType == .video {
                    ZStack {
                        if player != nil {
                            VideoPlayer(player: player)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Color.gray
                            
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                    .onAppear {
                        if let url = attachment.url {
                            player = AVPlayer(url: url)
                            player?.audiovisualBackgroundPlaybackPolicy = .pauses
                            player?.isMuted = false
                            player?.play()
                        }
                    }
                    .onDisappear() {
                        guard player != nil else { return }
                        player?.pause()
                    }
                }
            }
            .frame(width: !isFeatured ? imageMaxHeight / 1.5 : newSize.width, height: !isFeatured ? imageMaxHeight: newSize.height)
            .clipped()
            .clipShape(.rect(cornerRadius: 15))
            .contentShape(Rectangle())
        } else {
            imaging
        }
    }
    
    @ViewBuilder
    var imaging: some View {
        let mediaSize: CGSize = size(for: attachment) ?? .init(width: imageMaxHeight, height: imageMaxHeight)
        let newSize = imageSize(from: mediaSize)
        
        GeometryReader { _ in
            // Audio later because it's a lil harder
            if let url = attachment.previewUrl {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: !isFeatured ? imageMaxHeight / 1.5 : newSize.width, height: !isFeatured ? imageMaxHeight: newSize.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                } placeholder: {
                    ZStack(alignment: .center) {
                        Color.gray
                        
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
        }
        .frame(width: !isFeatured ? imageMaxHeight / 1.5 : newSize.width, height: !isFeatured ? imageMaxHeight: newSize.height)
        .clipped()
        .clipShape(.rect(cornerRadius: 15))
        .contentShape(Rectangle())
    }
    
    private func size(for media: MediaAttachment) -> CGSize? {
        guard let width = media.meta?.original?.width,
              let height = media.meta?.original?.height
        else { return nil }
        
        return .init(width: CGFloat(width), height: CGFloat(height))
    }
    
    private func imageSize(from: CGSize) -> CGSize {
        let boxWidth = availableWidth - appLayoutWidth
        let boxHeight = availableHeight * 0.8 // use only 80% of window height to leave room for text
        
        if from.width <= boxWidth, from.height <= boxHeight {
            // intrinsic size of image fits just fine
            return from
        }
        
        // shrink image proportionally to fit inside the box
        let xRatio = boxWidth / from.width
        let yRatio = boxHeight / from.height
        if xRatio < yRatio {
            return .init(width: boxWidth, height: from.height * xRatio)
        } else {
            return .init(width: from.width * yRatio, height: boxHeight)
        }
    }
}

class NoControlsAVPlayerViewController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showsPlaybackControls = false
    }
}

struct NoControlsPlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func updateUIViewController(_ uiViewController: NoControlsAVPlayerViewController, context: Context) {
        // update
    }
    
    func makeUIViewController(context: Context) -> NoControlsAVPlayerViewController {
        let customPlayerVC = NoControlsAVPlayerViewController()
        customPlayerVC.player = player // Set the AVPlayer
        return customPlayerVC
    }
}
