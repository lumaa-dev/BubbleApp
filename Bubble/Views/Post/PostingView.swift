//Made by Lumaa

import SwiftUI
import SwiftData
import FoundationModels
import UIKit
import PhotosUI

struct PostingView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate

    @Namespace private var stickyGlass

    @Query private var drafts: [StatusDraft]

    private let session: LanguageModelSession = .init(instructions: """
        You are a social media user, you are writing a social media post to publish online only through 500 characters.
        You can use the provided context to write whatever social media post.
        Don't return questions or context, only the ready-to-be-published social media post.
        """)

    public var initialString: String = ""
    public var replyId: String? = nil
    public var editId: String? = nil

    @State private var viewModel: ViewModel = .init()
    @State private var hasKeyboard: Bool = false
    @State private var visibility: Visibility = .pub
    @State private var pref: UserPreferences = .defaultPreferences
    
    @State private var selectingPhotos: Bool = false
    @State private var mediaContainers: [MediaContainer] = []
    @State private var mediaAttributes: [StatusData.MediaAttribute] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var player: AVPlayer?
    
    @State private var hasPoll: Bool = false
    @State private var pollOptions: [String] = ["", ""]
    @State private var pollExpiry: StatusData.PollData.DefaultExpiry = .oneDay
    @State private var multiSelect: Bool = false

    @State private var selectingEmoji: Bool = false
    @State private var makingAlt: MediaContainer? = nil

    @State private var selectingDrafts: Bool = false
    @State private var selectedDraft: StatusDraft? = nil

    @State private var generatingPost: Bool = false
    @State private var loadingContent: Bool = false
    @State private var postingStatus: Bool = false

    private var isInSheet: Bool {
        Navigator.shared.presentedSheet?.id == SheetDestination.post().id
    }

    init(initialString: String, replyId: String? = nil, editId: String? = nil) {
        self.initialString = initialString
        self.replyId = replyId
        self.editId = editId
    }

    private func fromDraft(_ draft: StatusDraft) {
        self.viewModel.postText = .init(string: draft.content)
        self.viewModel.formatText()

        if draft.hasPoll {
            self.hasPoll = true
            self.pollOptions = draft.pollOptions
            self.multiSelect = draft.pollMulti
            self.pollExpiry = StatusData.PollData.DefaultExpiry.getFromInt(draft.pollExpire) ?? .oneDay
        } else {
            self.hasPoll = false
            self.pollOptions = ["", ""]
            self.multiSelect = false
            self.pollExpiry = .oneDay
        }
    }

    var body: some View {
        if accountManager.getAccount() != nil {
            posting
                .background(Color.appBackground)
                .sheet(isPresented: $selectingEmoji) {
                    EmojiSelector(viewModel: viewModel)
                        .presentationDetents([.height(200), .medium])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled(upThrough: .height(200))) // Allow users to move the cursor while adding emojis
                }
                .sheet(item: $makingAlt) { container in
                    AltTextView(container: container, mediaContainers: $mediaContainers, mediaAttributes: $mediaAttributes)
                        .presentationDetents([.height(235), .medium])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $selectingDrafts) {
                    if let selected = selectedDraft {
                        self.fromDraft(selected)
                    }
                } content: {
                    PostDraftView(selectedDraft: $selectedDraft)
                }
        } else {
            loading
                .background(Color.appBackground)
        }
    }
    
    var posting: some View {
        ScrollView {
            VStack(alignment: .leading) {
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
                            .frame(maxWidth: 250)
                            .multilineTextAlignment(.leading)
                            .font(.callout)
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            
                            if !mediaContainers.isEmpty {
                                mediasView(containers: mediaContainers)
                            }
                            
                            if hasPoll {
                                editPollView
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                }
                .onChange(of: selectingEmoji) { _, new in
                    guard new == false else { return }
                    self.hasKeyboard = true
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: appDelegate.windowHeight - 140, alignment: .leading)
        .safeAreaInset(edge: .bottom, alignment: .leading) {
            //MARK: Buttons below
            HStack(alignment: .center) {
                editorButtons

                Spacer()

                postButtons
                    .padding(.horizontal, 18)

                let unpostable: Bool = postingStatus || viewModel.postText.length <= 0
                Button {
                    postText()
                } label: {
                    ZStack {
                        if postingStatus {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .foregroundStyle(Color(uiColor: UIColor.systemBackground))
                                .tint(Color(uiColor: UIColor.systemBackground))
                        } else {
                            Text("status.posting.post")
                                .foregroundStyle(Color(uiColor: UIColor.systemBackground))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6.0)
                    .glassEffect(.regular.interactive(!unpostable).tint(Color(uiColor: UIColor.label)))
                    .disabled(unpostable)
                    .opacity(unpostable ? 0.5 : 1.0)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden()
        .navigationTitle(Text(editId == nil ? "status.posting" : "status.editing"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if isInSheet {
                    Button {
                        dismiss()
                    } label: {
                        Text("status.posting.cancel")
                    }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                privacyPicker
            }
        }
        .onAppear {
            self.pref = try! UserPreferences.loadAsCurrent()
            self.visibility = pref.defaultVisibility
            self.hasKeyboard = self.isInSheet

            if !initialString.isEmpty && editId == nil {
                viewModel.append(text: initialString + " ") // add space for quick typing
            } else {
                viewModel.append(text: initialString) // editing doesn't need quick typing
            }
        }
    }
    
    var privacyPicker: some View {
        Picker("status.posting.visibility", selection: $visibility) {
            ForEach(Visibility.allCases, id: \.self) { item in
                HStack(alignment: .firstTextBaseline) {
                    switch (item) {
                        case .pub:
                            Label("status.posting.visibility.public", systemImage: "text.magnifyingglass")
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.leading)
                        case .unlisted:
                            Label("status.posting.visibility.unlisted", systemImage: "magnifyingglass")
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.leading)
                        case .direct:
                            Label("status.posting.visibility.direct", systemImage: "paperplane")
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.leading)
                        case .priv:
                            Label("status.posting.visibility.private", systemImage: "lock.fill")
                                .foregroundStyle(Color.gray)
                                .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .foregroundStyle(Color.gray)
    }

    // MARK: Post function
    private func postText() {
        Task {
            if let client = accountManager.getClient() {
                postingStatus = true
                
//                for container in mediaContainers {
//                    await upload(container: container)
//                }
                
                var pollData: StatusData.PollData? = nil
                if self.hasPoll {
                    pollData = StatusData.PollData(options: self.pollOptions, multiple: self.multiSelect, expires_in: pollExpiry.rawValue)
                }
                
                let json: StatusData = .init(status: viewModel.postText.string, visibility: visibility, inReplyToId: replyId, mediaIds: mediaContainers.compactMap { $0.mediaAttachment?.id }, poll: pollData, mediaAttributes: mediaAttributes)
                
                let isEdit: Bool = editId != nil
                let endp: Endpoint = isEdit ? Statuses.editStatus(id: editId!, json: json) : Statuses.postStatus(json: json)
                
                let _: Status = isEdit ? try await client.put(endpoint: endp) : try await client.post(endpoint: endp)
                
                postingStatus = false
                HapticManager.playHaptics(haptics: Haptic.success)
                NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
                dismiss()
                
                if isEdit {
                    dismiss()
                }
            }
        }
    }
    
    var editPollView: some View {
        VStack {
            ForEach(0 ..< pollOptions.count, id: \.self) { i in
                let isLast: Bool = pollOptions.count - 1 == i;
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2.5)
                    .frame(width: 300, height: 50)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .overlay {
                        HStack {
                            TextField("status.posting.poll.option-\(i + 1)", text: $pollOptions[i], axis: .horizontal)
                                .font(.subheadline)
                                .padding(.leading, 25)
                                .foregroundStyle(Color(uiColor: UIColor.label))
                            
                            Spacer()
                            
                            HStack(spacing: 5) {
                                Button {
                                    withAnimation(.spring) {
                                        self.pollOptions.append("")
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.callout)
                                        .foregroundStyle(pollOptions.count >= 4 || !isLast ? Color.gray : Color(uiColor: UIColor.label))
                                }
                                .disabled(pollOptions.count >= 4 || !isLast)
                                
                                Button {
                                    withAnimation(.spring) {
                                        if pollOptions.count == 2 {
                                            self.hasPoll = false
                                        } else {
                                            let index: Int = i
                                            self.pollOptions.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.callout)
                                        .foregroundStyle(Color(uiColor: UIColor.label))
                                }
                            }
                            .padding(.trailing, 25)
                        }
                    }
            }
            HStack {
                Button {
                    withAnimation(.spring) {
                        multiSelect.toggle()
                    }
                } label: {
                    Text(multiSelect ? LocalizedStringKey("status.posting.poll.disable-multi") : LocalizedStringKey("status.posting.poll.enable-multi"))
                }
                .buttonStyle(LargeButton(filled: false, height: 7.5))
                
                Spacer()
                
                Picker("status.posting.poll.expiry", selection: $pollExpiry) {
                    ForEach(StatusData.PollData.DefaultExpiry.allCases, id: \.self) { expiry in
                        Text(expiry.description)
                    }
                }
            }
            .frame(width: 300)
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
    private func mediasView(containers: [MediaContainer], actions: Bool = true) -> some View {
        ViewThatFits {
            hMedias(containers, actions: actions)
                .frame(maxHeight: containerHeight)
            
            ScrollView(.horizontal, showsIndicators: false) {
                hMedias(containers, actions: actions)
            }
            .frame(maxHeight: containerHeight)
            .scrollClipDisabled()
        }
    }
    
    @ViewBuilder
    private func hMedias(_ containers: [MediaContainer], actions: Bool) -> some View {
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
                    if actions {
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
                .overlay(alignment: .topLeading) {
                    if actions && container.mediaAttachment != nil {
                        Button {
                            makingAlt = container
                        } label: {
                            Text(String("ALT"))
                                .font(.subheadline.smallCaps())
                                .padding(7.5)
                                .background(Material.ultraThick)
                                .clipShape(Capsule())
                                .padding(5)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: containerHeight)
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
                            .frame(idealWidth: mediaContainers.count == 1 ? 300 : containerWidth, maxWidth: 300)
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
        .frame(idealWidth: mediaContainers.count == 1 ? 300 : containerWidth, maxWidth: 300, idealHeight: containerHeight)
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
        //MARK: Action buttons
        GlassEffectContainer(spacing: 6.0) {
            HStack(spacing: 6.0) {
                if !self.hasPoll {
                    actionButton("photo.badge.plus") {
                        selectingPhotos.toggle()
                    }
                    .glassEffectUnion(id: "action", namespace: self.stickyGlass)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
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
                }

                if mediaContainers.isEmpty || selectedPhotos.isEmpty {
                    actionButton("checklist") {
                        withAnimation(.spring) {
                            self.hasPoll.toggle()
                        }
                    }
                    .glassEffectUnion(id: "action", namespace: self.stickyGlass)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                actionButton("face.smiling") {
                    self.hasKeyboard.toggle()
                    selectingEmoji.toggle()
                }
                .glassEffectUnion(id: "action", namespace: self.stickyGlass)

                actionMenu("apple.intelligence") {
                    ForEach(PostGeneration.allCases) { ai in
                        if ai == .smartReply {
                            Divider()
                        }
                        
                        Button {
                            Task {
                                await self.generateText(type: ai)
                            }
                        } label: {
                            ai.label
                        }
                        .disabled(ai == .smartReply && self.replyId == nil)
                    }
                }
                .glassEffectUnion(id: "action", namespace: self.stickyGlass)
                .disabled(SystemLanguageModel.default.isAvailable || self.generatingPost)
            }
            .padding(.leading, 8.0)
        }
    }

    var postButtons: some View {
        //MARK: Post buttons
        GlassEffectContainer(spacing: 6.0) {
            HStack(spacing: 6.0) {
                actionMenu("plus.square.dashed") {
                    let addDisabled: Bool = self.drafts.count >= 3 && !AppDelegate.premium

                    Button {
                        selectingDrafts.toggle()
                    } label: {
                        Label("status.drafts.open", systemImage: "pencil.and.scribble")
                    }

                    if addDisabled {
                        Divider()
                    }

                    Button {
                        if AppDelegate.premium || drafts.count < 3 {
                            let newDraft: StatusDraft = .init(
                                content: viewModel.postText.string,
                                visibility: visibility
                            )

                            modelContext.insert(newDraft) // save draft
                            self.fromDraft(.empty) // empty the current view

                            HapticManager.playHaptics(haptics: Haptic.success)
                        } else {
                            HapticManager.playHaptics(haptics: Haptic.lock)
                            Navigator.shared.presentedSheet = .lockedFeature(.drafts)
                        }
                    } label: {
                        Label("status.drafts.add", systemImage: "plus.circle.dashed")
                    }
                    .disabled(addDisabled || viewModel.postText.string.isEmpty)

                    if addDisabled {
                        Text("status.drafts.plus")
                    }
                }
                .glassEffectUnion(id: "post", namespace: self.stickyGlass)
            }
        }
    }

    @ViewBuilder
    func actionMenu(_ image: String, @ViewBuilder menu: () -> some View) -> some View {
        Menu {
            menu()
        } label: {
            Image(systemName: image)
                .font(.callout)
                .foregroundStyle(Color(uiColor: UIColor.label))
                .padding(8.0)
                .glassEffect(.regular.interactive())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func actionButton(_ image: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: image)
                .font(.callout)
                .foregroundStyle(Color(uiColor: UIColor.label))
                .padding(8.0)
                .glassEffect(.regular.interactive())
        }
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
                .foregroundStyle(Color(uiColor: UIColor.label))
                .padding(8.0)
                .glassEffect(.regular.interactive())
        }
    }
    
    var profilePicture: some View {
        OnlineImage(url: accountManager.forceAccount().avatar, size: 50, useNuke: true)
            .frame(width: 40, height: 40)
            .padding(.horizontal)
            .clipShape(.circle)
    }

    // MARK: - Foundation Models
    private func generateText(type: PostGeneration) async {
        guard SystemLanguageModel.default.isAvailable, !viewModel.postText.string.isEmpty else { return }

        defer { withAnimation { self.generatingPost = false } }
        withAnimation { self.generatingPost = true }

        var context: String = viewModel.postText.string
        if type == .smartReply, let replyStatus: Status = try? await self.accountManager.forceClient().get(endpoint: Statuses.status(id: self.replyId ?? "-1")) {
            context = replyStatus.content.asRawText
        }

        let stream = session.streamResponse(to: type.prompt(context: context), options: .init(temperature: type.temperature))

        do {
            viewModel.postText = .init()

            for try await partial in stream {
                viewModel.postText = .init(string: partial)
            }

            let complete: String = try await stream.collect().content
            viewModel.postText = .init(string: complete)
        } catch {
            print("[FoundationModel] \(error)")
        }
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
    
    @Observable public class ViewModel: NSObject, ObservableObject {
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
    
    struct AltTextView: View {
        @Environment(AccountManager.self) private var accountManager: AccountManager
        @Environment(\.dismiss) private var dismiss
        
        var container: MediaContainer
        @Binding var mediaContainers: [MediaContainer]
        @Binding var mediaAttributes: [StatusData.MediaAttribute]
        
        @State private var tasking: Bool = false
        @State private var applying: Bool = false
        @State private var alt: String = ""
        @FocusState private var altFocused: Bool
        
        var body: some View {
            NavigationStack {
                List {
                    TextField(String(""), text: $alt, prompt: Text("posting.alt.prompt"), axis: .vertical)
                        .labelsHidden()
                        .keyboardType(.asciiCapable)
                        .focused($altFocused)
                        .frame(maxHeight: 200)
                }
                .onAppear {
                    if let mediaAttachment = container.mediaAttachment {
                        if let past = mediaAttachment.description, !past.isEmpty {
                            alt = past
                        }
                    }
                }
                .navigationTitle(Text("posting.alt.header"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            applying = true
                            if let mediaAttachment = container.mediaAttachment {
                                if let str = mediaAttachment.description, !str.isEmpty {
                                    Task {
                                        await editDescription(container: container, description: alt)
                                        applying = false
                                        dismiss()
                                    }
                                } else {
                                    Task {
                                        await addDescription(container: container, description: alt)
                                        applying = false
                                        dismiss()
                                    }
                                }
                                HapticManager.playHaptics(haptics: Haptic.success)
                            }
                        } label: {
                            if applying {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                .onAppear {
                    altFocused = true
                }
            }
        }
        
        private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                DispatchQueue.main.async {
                    completion(UIImage(data: data))
                }
            }.resume()
        }
        
        private func addDescription(container: MediaContainer, description: String) async {
            guard let client = accountManager.getClient(), let attachment = container.mediaAttachment else { return }
            if let index = indexOf(container: container) {
                do {
                    let media: MediaAttachment = try await client.put(endpoint: Media.media(id: attachment.id,
                                                                                            json: .init(description: description)))
                    mediaContainers[index] = MediaContainer(
                        id: container.id,
                        image: nil,
                        movieTransferable: nil,
                        gifTransferable: nil,
                        mediaAttachment: media,
                        error: nil
                    )
                } catch {}
            }
        }
        
        private func editDescription(container: MediaContainer, description: String) async {
            guard let attachment = container.mediaAttachment else { return }
            if indexOf(container: container) != nil {
                mediaAttributes.append(StatusData.MediaAttribute(id: attachment.id, description: description, thumbnail: nil, focus: nil))
            }
        }
        
        private func indexOf(container: MediaContainer) -> Int? {
            mediaContainers.firstIndex(where: { $0.id == container.id })
        }
    }
}

extension AttributedString {
    var string: String {
        String(self.characters[...])
    }
}
