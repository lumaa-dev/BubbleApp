//Made by Lumaa

import SwiftUI
import UIKit
import PhotosUI

struct PostingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    public var initialString: String = ""
    public var replyId: String? = nil
    public var editId: String? = nil
    
    @State private var viewModel: PostingView.ViewModel = PostingView.ViewModel()
    
    @State private var hasKeyboard: Bool = true
    @State private var visibility: Visibility = .pub
    
    @State private var selectingPhotos: Bool = false
    @State private var mediaContainers: [MediaContainer] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var player: AVPlayer?
    
    @State private var selectingEmoji: Bool = false
    
    @State private var loadingContent: Bool = false
    @State private var postingStatus: Bool = false
    
    init(initialString: String, replyId: String? = nil, editId: String? = nil) {
        self.initialString = initialString
        self.replyId = replyId
        self.editId = editId
    }
    
    var body: some View {
        if accountManager.getAccount() != nil {
            ViewThatFits {
                posting
                    .background(Color.appBackground)
                    .sheet(isPresented: $selectingEmoji) {
                        EmojiSelector(viewModel: $viewModel)
                            .presentationDetents([.height(200), .medium])
                            .presentationDragIndicator(.visible)
                            .presentationBackgroundInteraction(.enabled(upThrough: .height(200))) // Allow users to move the cursor while adding emojis
                    }
                
                ScrollView(.vertical, showsIndicators: false) {
                    posting
                        .background(Color.appBackground)
                        .sheet(isPresented: $selectingEmoji) {
                            EmojiSelector(viewModel: $viewModel)
                                .presentationDetents([.height(200), .medium])
                                .presentationDragIndicator(.visible)
                                .presentationBackgroundInteraction(.enabled(upThrough: .height(200))) // Allow users to move the cursor while adding emojis
                        }
                }
            }
        } else {
            loading
                .background(Color.appBackground)
        }
    }
    
    var posting: some View {
        VStack {
            HStack(alignment: .top, spacing: 0) {
                // MARK: Profile picture
                profilePicture
                
                VStack(alignment: .leading) {
                    // MARK: Status main content
                    VStack(alignment: .leading, spacing: 10) {
                        Text("@\(accountManager.forceAccount().username)")
                            .multilineTextAlignment(.leading)
                            .bold()
                        
                        DynamicTextEditor($viewModel.postText, getTextView: { textView in
                            viewModel.textView = textView
                        })
                        .placeholder(String(localized: "status.posting.placeholder"))
                        .setKeyboardType(.twitter)
                        .onFocus {
                            selectingEmoji = false
                        }
                        .multilineTextAlignment(.leading)
                        .font(.callout)
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        
                        if !mediaContainers.isEmpty {
                            mediasView(containers: mediaContainers)
                        }
                        
                        editorButtons
                            .padding(.vertical)
                    }
                    
                    Spacer()
                }
            }
            .onChange(of: selectingEmoji) { _, new in
                guard new == false else { return }
                viewModel.textView?.becomeFirstResponder()
            }
            
            HStack {
                Picker("status.posting.visibility", selection: $visibility) {
                    ForEach(Visibility.allCases, id: \.self) { item in
                        HStack(alignment: .firstTextBaseline) {
                            switch (item) {
                                case .pub:
                                    Text("status.posting.visibility.public")
                                        .foregroundStyle(Color.gray)
                                case .unlisted:
                                    Text("status.posting.visibility.unlisted")
                                        .foregroundStyle(Color.gray)
                                case .direct:
                                    Text("status.posting.visibility.direct")
                                        .foregroundStyle(Color.gray)
                                case .priv:
                                    Text("status.posting.visibility.private")
                                        .foregroundStyle(Color.gray)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .foregroundStyle(Color.gray)
                .frame(width: 200, alignment: .leading)
                .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button {
                    postText()
                } label: {
                    if postingStatus {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .foregroundStyle(Color.appBackground)
                            .tint(Color.appBackground)
                    } else {
                        Text("status.posting.post")
                    }
                }
                .disabled(postingStatus || viewModel.postText.length <= 0)
                .buttonStyle(LargeButton(filled: true, height: 7.5, disabled: postingStatus || viewModel.postText.length <= 0))
            }
            .padding()
        }
        .navigationBarBackButtonHidden()
        .navigationTitle(Text(editId == nil ? "status.posting" : "status.editing"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("status.posting.cancel")
                }
            }
        }
        .onAppear {
            if !initialString.isEmpty && editId == nil {
                viewModel.append(text: initialString + " ") // add space for quick typing
            } else {
                viewModel.append(text: initialString) // editing doesn't need quick typing
            }
        }
    }
    
    private func postText() {
        Task {
            if let client = accountManager.getClient() {
                postingStatus = true
                
                for container in mediaContainers {
                    await upload(container: container)
                }
                
                let json: StatusData = .init(status: viewModel.postText.string, visibility: visibility, inReplyToId: replyId, mediaIds: mediaContainers.compactMap { $0.mediaAttachment?.id }, mediaAttributes: mediaAttributes)
                
                let isEdit: Bool = editId != nil
                let endp: Endpoint = isEdit ? Statuses.editStatus(id: editId!, json: json) : Statuses.postStatus(json: json)
                
                let _: Status = isEdit ? try await client.put(endpoint: endp) : try await client.post(endpoint: endp)
                
                postingStatus = false
                HapticManager.playHaptics(haptics: Haptic.success)
                dismiss()
                
                if isEdit {
                    dismiss()
                }
            }
        }
    }
    
    var loading: some View {
        ProgressView()
            .foregroundStyle(.white)
            .progressViewStyle(.circular)
    }
    
    private let containerWidth: CGFloat = 300
    private let containerHeight: CGFloat = 450
    
    @ViewBuilder
    private func mediasView(containers: [MediaContainer]) -> some View {
        ViewThatFits {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                ForEach(containers) { container in
                    ZStack(alignment: .topLeading) {
                        if let img = container.image {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: mediaContainers.count == 1 ? nil : containerWidth, maxWidth: 450)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                                .clipShape(.rect(cornerRadius: 15))
                                .contentShape(Rectangle())
                        } else if let attachment = container.mediaAttachment {
                            attchmntView(attachment: attachment)
                        } else if let video = container.movieTransferable {
                            vidView(url: video.url)
                        } else if let gif = container.gifTransferable {
                            vidView(url: gif.url)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        Button {
                            deleteAction(container: container)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline)
                                .padding(10)
                                .background(Material.ultraThick)
                                .clipShape(Circle())
                                .padding(5)
                        }
                    }
                }
            }
            .frame(maxHeight: containerHeight)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ForEach(containers) { container in
                        ZStack(alignment: .topLeading) {
                            if let img = container.image {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minWidth: mediaContainers.count == 1 ? nil : containerWidth, maxWidth: 500)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(.rect(cornerRadius: 15))
                                    .contentShape(Rectangle())
                            } else if let attachment = container.mediaAttachment {
                                attchmntView(attachment: attachment)
                            } else if let video = container.movieTransferable {
                                vidView(url: video.url)
                            } else if let gif = container.gifTransferable {
                                vidView(url: gif.url)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            Button {
                                deleteAction(container: container)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.subheadline)
                                    .padding(10)
                                    .background(Material.ultraThick)
                                    .clipShape(Circle())
                                    .padding(5)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: containerHeight)
            .scrollClipDisabled()
        }
    }
    
    @ViewBuilder
    private func attchmntView(attachment: MediaAttachment) -> some View {
        GeometryReader { _ in
            // Audio later because it's a lil harder
            if attachment.supportedType == .image {
                if let url = attachment.url {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: mediaContainers.count == 1 ? nil : containerWidth, maxWidth: 600)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(.gray.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(.rect(cornerRadius: 15))
                            .contentShape(Rectangle())
                    } placeholder: {
                        ZStack(alignment: .center) {
                            Color.gray
                            
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
            } else if attachment.supportedType == .gifv || attachment.supportedType == .video {
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
            }
        }
        .frame(minWidth: mediaContainers.count == 1 ? nil : containerWidth, maxWidth: 600)
        .clipShape(.rect(cornerRadius: 15))
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func vidView(url: URL) -> some View {
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
        .onDisappear() {
            guard player != nil else { return }
            player?.pause()
        }
    }
    
    var editorButtons: some View {
        HStack(spacing: 18) {
            actionButton("photo.badge.plus") {
                selectingPhotos.toggle()
            }
            .photosPicker(isPresented: $selectingPhotos, selection: $selectedPhotos, maxSelectionCount: 4, matching: .any(of: [.images, .videos]), photoLibrary: .shared())
            .onChange(of: selectedPhotos) { oldValue, _ in
                if selectedPhotos.count > 4 {
                    selectedPhotos = selectedPhotos.prefix(4).map { $0 }
                }
                
                let removedIDs = oldValue
                    .filter { !selectedPhotos.contains($0) }
                    .compactMap(\.itemIdentifier)
                mediaContainers.removeAll { removedIDs.contains($0.id) }
                
                let newPickerItems = selectedPhotos.filter { !oldValue.contains($0) }
                print("newPickerItems: \(newPickerItems.count)")
                if !newPickerItems.isEmpty {
                    loadingContent = true
                    Task {
                        for item in newPickerItems {
                            initImage(for: item)
                        }
                    }
                }
            }
            .tint(Color.blue)
            
            actionButton("number") {
                DispatchQueue.main.async {
                    viewModel.append(text: "#")
                }
            }
            
            let smileSf = colorScheme == .light ? "face.smiling" : "face.smiling.inverse"
            actionButton(smileSf) {
                viewModel.textView?.resignFirstResponder()
                selectingEmoji.toggle()
            }
        }
    }
    
    @ViewBuilder
    func actionButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: image)
                .font(.callout)
        }
        .tint(Color.gray)
    }
    
    @ViewBuilder
    func asyncActionButton(_ image: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Image(systemName: image)
                .font(.callout)
        }
        .tint(Color.gray)
    }
    
    var profilePicture: some View {
        OnlineImage(url: accountManager.forceAccount().avatar, size: 50, useNuke: true)
            .frame(width: 40, height: 40)
            .padding(.horizontal)
            .clipShape(.circle)
    }
    
    //MARK: - Image manipulations
    
    private func indexOf(container: MediaContainer) -> Int? {
        mediaContainers.firstIndex(where: { $0.id == container.id })
    }
    
    func initImage(for pickerItem: PhotosPickerItem) {
        Task(priority: .high) {
            if let container = await makeMediaContainer(from: pickerItem) {
                self.mediaContainers.append(container)
                await upload(container: container)
                self.loadingContent = false
            }
        }
    }
    
    func initImage(for container: MediaContainer) {
        Task(priority: .high) {
            self.mediaContainers.append(container)
            self.loadingContent = false
        }
    }
    
    nonisolated func makeMediaContainer(from pickerItem: PhotosPickerItem) async -> PostingView.MediaContainer? {
        await withTaskGroup(of: MediaContainer?.self, returning: MediaContainer?.self) { taskGroup in
            taskGroup.addTask(priority: .high) { await Self.makeImageContainer(from: pickerItem) }
            taskGroup.addTask(priority: .high) { await Self.makeGifContainer(from: pickerItem) }
            taskGroup.addTask(priority: .high) { await Self.makeMovieContainer(from: pickerItem) }
            
            for await container in taskGroup {
                if let container {
                    taskGroup.cancelAll()
                    return container
                }
            }
            
            return nil
        }
    }
    
    private static func makeGifContainer(from pickerItem: PhotosPickerItem) async -> PostingView.MediaContainer? {
        guard let gifFile = try? await pickerItem.loadTransferable(type: GifFileTranseferable.self) else { return nil }
        
        return PostingView.MediaContainer(id: pickerItem.itemIdentifier ?? UUID().uuidString, image: nil, movieTransferable: nil, gifTransferable: gifFile, mediaAttachment: nil, error: nil)
    }
    
    private static func makeMovieContainer(from pickerItem: PhotosPickerItem) async -> PostingView.MediaContainer? {
        guard let movieFile = try? await pickerItem.loadTransferable(type: MovieFileTransferable.self) else { return nil }
        
        return PostingView.MediaContainer(id: pickerItem.itemIdentifier ?? UUID().uuidString, image: nil, movieTransferable: movieFile, gifTransferable: nil, mediaAttachment: nil, error: nil)
    }
    
    private static func makeImageContainer(from pickerItem: PhotosPickerItem) async -> PostingView.MediaContainer? {
        guard let imageFile = try? await pickerItem.loadTransferable(type: ImageFileTranseferable.self) else { return nil }
        
        let compressor = Compressor()
        
        guard let compressedData = await compressor.compressImageFrom(url: imageFile.url),
              let image = UIImage(data: compressedData)
        else { return nil }
        
        return PostingView.MediaContainer(id: pickerItem.itemIdentifier ?? UUID().uuidString, image: image, movieTransferable: nil, gifTransferable: nil, mediaAttachment: nil, error: nil)
    }
    
    func upload(container: PostingView.MediaContainer) async {
        if let index = indexOf(container: container) {
            let originalContainer = mediaContainers[index]
            guard originalContainer.mediaAttachment == nil else { return }
            let newContainer = MediaContainer(id: originalContainer.id, image: originalContainer.image, movieTransferable: originalContainer.movieTransferable, gifTransferable: nil, mediaAttachment: nil, error: nil)
            mediaContainers[index] = newContainer
            do {
                let compressor = Compressor()
                if let image = originalContainer.image {
                    let imageData = try await compressor.compressImageForUpload(image)
                    let uploadedMedia = try await uploadMedia(data: imageData, mimeType: "image/jpeg")
                    if let index = indexOf(container: newContainer) {
                        mediaContainers[index] = PostingView.MediaContainer(id: originalContainer.id, image: nil, movieTransferable: nil, gifTransferable: nil, mediaAttachment: uploadedMedia, error: nil)
                    }
                    if let uploadedMedia, uploadedMedia.url == nil {
                        scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
                    }
                } else if let videoURL = originalContainer.movieTransferable?.url,
                          let compressedVideoURL = await compressor.compressVideo(videoURL),
                          let data = try? Data(contentsOf: compressedVideoURL)
                {
                    let uploadedMedia = try await uploadMedia(data: data, mimeType: compressedVideoURL.mimeType())
                    if let index = indexOf(container: newContainer) {
                        mediaContainers[index] = PostingView.MediaContainer(id: originalContainer.id, image: nil, movieTransferable: originalContainer.movieTransferable, gifTransferable: nil, mediaAttachment: uploadedMedia, error: nil)
                    }
                    if let uploadedMedia, uploadedMedia.url == nil {
                        scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
                    }
                } else if let gifData = originalContainer.gifTransferable?.data {
                    let uploadedMedia = try await uploadMedia(data: gifData, mimeType: "image/gif")
                    if let index = indexOf(container: newContainer) {
                        mediaContainers[index] = PostingView.MediaContainer(id: originalContainer.id, image: nil, movieTransferable: nil, gifTransferable: originalContainer.gifTransferable, mediaAttachment: uploadedMedia, error: nil)
                    }
                    if let uploadedMedia, uploadedMedia.url == nil {
                        scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
                    }
                }
            } catch {
                if let index = indexOf(container: newContainer) {
                    mediaContainers[index] = PostingView.MediaContainer(id: originalContainer.id, image: originalContainer.image, movieTransferable: nil, gifTransferable: nil, mediaAttachment: nil, error: error)
                }
            }
        }
    }
    
    private func scheduleAsyncMediaRefresh(mediaAttachement: MediaAttachment) {
        Task {
            repeat {
                if let client = accountManager.getClient(),
                   let index = mediaContainers.firstIndex(where: { $0.mediaAttachment?.id == mediaAttachement.id })
                {
                    guard mediaContainers[index].mediaAttachment?.url == nil else {
                        return
                    }
                    do {
                        let newAttachement: MediaAttachment = try await client.get(endpoint: Media.media(id: mediaAttachement.id, json: nil))
                        if newAttachement.url != nil {
                            let oldContainer = mediaContainers[index]
                            mediaContainers[index] = MediaContainer(id: mediaAttachement.id, image: oldContainer.image, movieTransferable: oldContainer.movieTransferable, gifTransferable: oldContainer.gifTransferable, mediaAttachment: newAttachement, error: nil)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                try? await Task.sleep(for: .seconds(5))
            } while !Task.isCancelled
        }
    }
    
    func addDescription(container: PostingView.MediaContainer, description: String) async {
        guard let client = accountManager.getClient(), let attachment = container.mediaAttachment else { return }
        if let index = indexOf(container: container) {
            do {
                let media: MediaAttachment = try await client.put(endpoint: Media.media(id: attachment.id,
                                                                                        json: .init(description: description)))
                mediaContainers[index] = MediaContainer(id: container.id, image: nil, movieTransferable: nil, gifTransferable: nil, mediaAttachment: media, error: nil)
            } catch { print(error) }
        }
    }
    
    private var mediaAttributes: [StatusData.MediaAttribute] = []
    mutating func editDescription(container: PostingView.MediaContainer, description: String) async {
        guard let attachment = container.mediaAttachment else { return }
        if indexOf(container: container) != nil {
            mediaAttributes.append(StatusData.MediaAttribute(id: attachment.id, description: description, thumbnail: nil, focus: nil))
        }
    }
    
    private func uploadMedia(data: Data, mimeType: String) async throws -> MediaAttachment? {
        guard let client = accountManager.getClient() else { return nil }
        return try await client.mediaUpload(endpoint: Media.medias, version: .v2, method: "POST", mimeType: mimeType, filename: "file", data: data)
    }
    
    /// Removes an image from the editor
    private func deleteAction(container: MediaContainer) {
        selectedPhotos.removeAll(where: {
            if let id = $0.itemIdentifier {
                return id == container.id
            }
            return false
        })
        mediaContainers.removeAll {
            $0.id == container.id
        }
    }
    
    @Observable public class ViewModel: NSObject {
        init(text: String = "") {
            self.postText = NSMutableAttributedString(string: text)
        }
        
        var selectedRange: NSRange {
            get {
                guard let textView else {
                    return .init(location: 0, length: 0)
                }
                return textView.selectedRange
            }
            set {
                textView?.selectedRange = newValue
            }
        }
        
        var postText: NSMutableAttributedString {
            didSet {
                let range = selectedRange
                formatText()
                textView?.attributedText = postText
                selectedRange = range
            }
        }
        var textView: UITextView?
        
        func append(text: String) {
            let string = postText
            string.mutableString.insert(text, at: selectedRange.location)
            postText = string
            selectedRange = NSRange(location: selectedRange.location + text.utf16.count, length: 0)
        }
        
        func formatText() {
            postText.addAttributes([.foregroundColor : UIColor.label, .font: UIFont.preferredFont(forTextStyle: .callout), .backgroundColor: UIColor.clear, .underlineColor: UIColor.clear], range: NSMakeRange(0, postText.string.utf16.count))
        }
    }
}

extension PostingView {
    struct MediaContainer: Identifiable, Sendable {
        let id: String
        let image: UIImage?
        let movieTransferable: MovieFileTransferable?
        let gifTransferable: GifFileTranseferable?
        let mediaAttachment: MediaAttachment?
        let error: Error?
    }
}
