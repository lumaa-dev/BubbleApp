//Made by Lumaa

import SwiftUI
import UIKit
import AVKit

struct AttachmentView: View {
    @Namespace private var glassUnion

    @Environment(\.dismiss) private var dismiss
    @Environment(AppDelegate.self) private var appDelegate
    
    var attachments: [MediaAttachment]
    @State var selectedId: String = ""
    
    private var selectedAttachment: MediaAttachment? {
        guard !selectedId.isEmpty else { return nil }
        return attachments.filter({ $0.id == selectedId })[0]
    }

    private var canMute: Bool {
        guard let selectedAttachment else { return false }
        return selectedAttachment.supportedType != .gifv
    }

    @State private var player: AVPlayer? {
        didSet {
            timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.35, preferredTimescale: 600), queue: .main) { time in
                self.videoCurrent = time.seconds
                if let duration = self.player?.currentItem?.duration.seconds, duration > 0 {
                    self.videoMax = duration
                }
            }
        }
    }
    @State private var timeObserver: Any?

    @State private var videoPlaying: Bool = false
    @State private var videoMuted: Bool = false
    @State private var videoCurrent: Double = 0.0
    @State private var videoMax: Double = 0.0

    @State private var readAlt: Bool = false
    @State private var hasSwitch: Bool = false
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    
    @State private var currentPos: CGSize = .zero
    @State private var totalPos: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            ZStack(alignment: .center) {
                Color.appBackground
                    .ignoresSafeArea()
                
                if !attachments.isEmpty {
                    TabView(selection: $selectedId) {
                        ForEach(attachments) { atchmnt in
                            ZStack {
                                if atchmnt.supportedType == .image {
                                    AsyncImage(url: atchmnt.url, content: { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: size.width)
                                            .ignoresSafeArea()
                                    }, placeholder: {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.gray)
                                                .frame(width: size.width - 10, height: size.width - 10)
                                            
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                        
                                    })
                                    .tag(atchmnt.id)
                                    .ignoresSafeArea()
                                } else if atchmnt.supportedType == .video {
                                    ZStack {
                                        if player != nil {
                                            VideoPlayer(player: player)
                                                .scaledToFit()
                                                .frame(width: size.width)
                                                .ignoresSafeArea()
                                        } else {
                                            Color.gray
                                            
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                    }
                                    .onAppear {
                                        if let url = atchmnt.url {
                                            player = AVPlayer(url: url)
                                            player?.preventsDisplaySleepDuringVideoPlayback = true
                                            player?.audiovisualBackgroundPlaybackPolicy = .pauses

                                            AVManager.duckOther = true

                                            withAnimation {
                                                player?.isMuted = false
                                                videoMuted = false
                                            }

                                            player?.play()
                                            videoPlaying = true
                                        }
                                    }
                                    .onDisappear() {
                                        AVManager.duckOther = false

                                        guard player != nil else { return }

                                        if let timeObserver = timeObserver, let player {
                                            player.removeTimeObserver(timeObserver)
                                        }

                                        player?.pause()
                                        videoPlaying = false
                                    }
                                } else if atchmnt.supportedType == .gifv {
                                    ZStack(alignment: .center) {
                                        if player != nil {
                                            VideoPlayer(player: player)
                                                .scaledToFit()
                                                .frame(width: size.width)
                                                .ignoresSafeArea()
                                        } else {
                                            Color.gray
                                            
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                    }
                                    .onAppear {
                                        if let url = atchmnt.url {
                                            player = AVPlayer(url: url)
                                            player?.preventsDisplaySleepDuringVideoPlayback = true
                                            player?.audiovisualBackgroundPlaybackPolicy = .pauses

                                            AVManager.duckOther = false

                                            withAnimation {
                                                player?.isMuted = true
                                                videoMuted = true
                                            }

                                            player?.play()
                                            videoPlaying = true

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
                                        AVManager.duckOther = false

                                        guard player != nil else { return }

                                        if let timeObserver = timeObserver, let player {
                                            player.removeTimeObserver(timeObserver)
                                        }

                                        player?.pause()
                                    }
                                }
                            }
                            .offset(x: currentPos.width + totalPos.width, y: currentPos.height + totalPos.height)
                            .scaleEffect(currentZoom + totalZoom)
                        }
                    }
                    .ignoresSafeArea()
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    .onAppear {
                        UIScrollView.appearance().isScrollEnabled = false
                        if selectedId.isEmpty {
                            selectedId = attachments[0].id
                        }
                    }
                    .onChange(of: selectedId) { _, new in
                        currentZoom = 0.0
                        totalZoom = 1.0
                        currentPos = .zero
                        totalPos = .zero
                    }
                } else {
                    ContentUnavailableView("attachment.no-attachments", systemImage: "rectangle.slash")
                        .foregroundStyle(.white)
                }
            }
            .alert(String("ALT"), isPresented: $readAlt, actions: {
                Button(role: .cancel) {
                    readAlt.toggle()
                } label: {
                    Text("attachment.alt.action")
                }
            }, message: {
                Text(selectedAttachment?.description ?? "No ALT text here.")
            })
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        if (totalZoom + value.magnification - 1 > 1) {
                            currentZoom = value.magnification - 1
                        } else {
                            withAnimation(.spring.speed(2.0)) {
                                currentPos = .zero
                                totalPos = .zero
                            }
                        }
                    }
                    .onEnded { value in
                        totalZoom += currentZoom
                        totalZoom = max(1, totalZoom)
                        currentZoom = 0
                        withAnimation(.spring.speed(2.0)) {
                            totalZoom = min(5, totalZoom)
                        }
                    }
            )
            .highPriorityGesture(
                DragGesture()
                    .onChanged { gesture in
                        if totalZoom > 1.1 {
                            var fixedGesture = gesture.translation
                            fixedGesture.width = fixedGesture.width / (self.currentZoom + self.totalZoom)
                            fixedGesture.height = fixedGesture.height / (self.currentZoom + self.totalZoom)
                            currentPos = fixedGesture
                        } else {
                            guard !hasSwitch && attachments.count > 1 else { return }
                            if gesture.translation.width >= 40 || gesture.translation.width <= -40 {
                                let currentIndex = attachments.firstIndex(where: { $0.id == selectedId }) ?? 0
                                let newIndex = gesture.translation.width >= 20 ? loseIndex(currentIndex - 1, max: attachments.count - 1) : loseIndex(currentIndex + 1, max: attachments.count - 1)
                                selectedId = attachments[newIndex].id
                                hasSwitch = true
                            }
                        }
                    }
                    .onEnded { gesture in
                        totalPos.width += currentPos.width
                        totalPos.height += currentPos.height
                        currentPos = .zero
                        hasSwitch = false
                    }
            )
            .accessibilityZoomAction { action in
                if action.direction == .zoomIn {
                    totalZoom += 1
                } else {
                    totalZoom -= 1
                }
                totalZoom = max(1, totalZoom)
            }
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("attachment.close")
                        .pill()
                }
                .padding()
            }
            .overlay(alignment: .topTrailing) {
                self.topBar
            }
            .overlay(alignment: .bottom) {
                self.bottomBar
            }
        }
    }

    @ViewBuilder
    private var topBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                if !(selectedAttachment?.description?.isEmpty ?? true) {
                    Button {
                        readAlt.toggle()
                    } label: {
                        Text(String("ALT"))
                            .font(.body)
                    }
                    .pill(disabled: selectedAttachment?.description?.isEmpty ?? true)
                }

                Button {
                    if AppDelegate.premium {
                        Task {
                            let imgData = try await URLSession.shared.data(from: selectedAttachment?.url ?? URL.placeholder)
                            if let img = UIImage(data: imgData.0) {
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                            }
                        }
                    } else {
                        Navigator.shared.presentedSheet = .lockedFeature(.downloadAttachment)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .pill(union: "topbar", namespace: self.glassUnion)

                Menu {
                    Button {
                        withAnimation(.spring.speed(2.0)) {
                            currentPos = .zero
                            totalPos = .zero
                            currentZoom = 0.0
                            totalZoom = 1.0
                        }
                    } label: {
                        Label("attachment.reset-move", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                    }

                    Divider()

                    Button {
                        let currentIndex = attachments.firstIndex(where: { $0.id == selectedId }) ?? 0
                        let newIndex = loseIndex(currentIndex - 1, max: attachments.count - 1)
                        selectedId = attachments[newIndex].id
                    } label: {
                        Label("attachment.previous-image", systemImage: "arrowshape.left")
                    }
                    .disabled(attachments.count <= 1)

                    Button {
                        let currentIndex = attachments.firstIndex(where: { $0.id == selectedId }) ?? 0
                        let newIndex = loseIndex(currentIndex + 1, max: attachments.count - 1)
                        selectedId = attachments[newIndex].id
                    } label: {
                        Label("attachment.next-image", systemImage: "arrowshape.right")
                    }
                    .disabled(attachments.count <= 1)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .pill(union: "topbar", namespace: self.glassUnion)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let media = selectedAttachment {
            if media.supportedType != .image, player != nil {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            if videoCurrent >= videoMax {
                                player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1)) { _ in
                                    AVManager.duckOther = true
                                    player?.play()

                                    withAnimation {
                                        videoPlaying = true
                                    }
                                }
                            } else {
                                if videoPlaying {
                                    player?.pause()
                                    AVManager.duckOther = false
                                } else {
                                    player?.play()
                                    AVManager.duckOther = true
                                }
                            }

                            withAnimation {
                                videoPlaying.toggle()
                            }
                        } label: {
                            Image(systemName: videoPlaying || videoCurrent >= videoMax ? "pause.fill" : "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12.5, height: 12.5, alignment: .center)
                                .contentTransition(.symbolEffect(.replace.offUp.wholeSymbol, options: .nonRepeating))
                        }
                        .pill()

                        progressBar
                            .padding(3.5)
                            .pill(interactable: false)

                        Button {
                            if videoMuted {
                                player?.isMuted = false
                            } else {
                                player?.isMuted = true
                            }

                            withAnimation {
                                videoMuted.toggle()
                            }
                        } label: {
                            Image(systemName: videoMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15, alignment: .center)
                                .contentTransition(.symbolEffect(.replace.offUp.wholeSymbol, options: .nonRepeating))
                        }
                        .pill(disabled: !canMute)
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if let _ = player?.currentTime(), let _ = player?.currentItem?.duration {
            GeometryReader { geo in
                let size: CGSize = geo.size

                Rectangle()
                    .fill(Color.gray)
                    .frame(maxWidth: size.width, maxHeight: 5)
                    .zIndex(2)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: videoMax <= 0 ? 0 : (videoCurrent / videoMax) * size.width, height: 5, alignment: .leading)
                            .zIndex(3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3.0))
            }
            .frame(maxWidth: .infinity, maxHeight: 5.0)
        }
    }

    private func loseIndex(_ index: Int, max: Int) -> Int {
        if index < 0 {
            return max
        } else if index > max {
            return 0
        }
        return index
    }
}

private extension View {
    func pill(union: String? = nil, namespace: Namespace.ID? = nil, disabled: Bool = false, interactable: Bool = true) -> some View {
        let base = self
            .foregroundStyle(Color(uiColor: UIColor.label))
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .clipShape(Capsule())
            .glassEffect(.regular.interactive(interactable), in: .capsule, isEnabled: !disabled && interactable)
            .disabled(disabled)

        if let namespace, let union {
            return AnyView(base.glassEffectUnion(id: union, namespace: namespace))
        } else {
            return AnyView(base)
        }
    }
}

#Preview {
    AttachmentView(attachments: [.init(id: "ABC", type: "image", url: URL(string: "https://i.stack.imgur.com/HX3Aj.png"), previewUrl: URL.placeholder, description: String("This displays the TabView with a page indicator at the bottom"), meta: nil), .init(id: "DEF", type: "image", url: URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg"), previewUrl: URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg"), description: nil, meta: nil)])
        .environment(AppDelegate())
}
