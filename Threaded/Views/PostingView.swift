//Made by Lumaa

import SwiftUI
import UIKit
import PhotosUI

struct PostingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(Navigator.self) private var navigator: Navigator
    
    public var initialString: String = ""
    public var replyId: String? = nil
    public var editId: String? = nil
    
    @State private var viewModel: PostingView.ViewModel = PostingView.ViewModel()
    
    @State private var visibility: Visibility = .pub
    @State private var selectedPhotos: PhotosPickerItem?
    
    @State private var postingStatus: Bool = false
    
    var body: some View {
        if accountManager.getAccount() != nil {
            posting
        } else {
            loading
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
                            .multilineTextAlignment(.leading)
                            .font(.callout)
                            .foregroundStyle(Color(uiColor: UIColor.label))
                        
                        editorButtons
                            .padding(.vertical)
                    }
                    
                    Spacer()
                }
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
                    Task {
                        if let client = accountManager.getClient() {
                            postingStatus = true
                            let json: StatusData = .init(status: viewModel.postText.string, visibility: visibility, inReplyToId: replyId)
                            
                            let isEdit: Bool = editId != nil
                            let endp: Endpoint = isEdit ? Statuses.editStatus(id: editId!, json: json) : Statuses.postStatus(json: json)
                            
                            let newStatus: Status = try await client.post(endpoint: endp)
                            postingStatus = false
                            HapticManager.playHaptics(haptics: Haptic.success)
                            dismiss()
                            navigator.navigate(to: .post(status: newStatus))
                        }
                    }
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
    
    var loading: some View {
        ProgressView()
            .foregroundStyle(.white)
            .progressViewStyle(.circular)
    }
    
    var editorButtons: some View {
        HStack(spacing: 18) {
            PhotosPicker(selection: $selectedPhotos, matching: .any(of: [.images, .videos]), label: {
                Image(systemName: "photo.badge.plus")
                    .font(.callout)
                    .foregroundStyle(.gray)
            })
            .tint(Color.blue)
            
            actionButton("number") {
                DispatchQueue.main.async {
                    viewModel.append(text: "#")
                }
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
