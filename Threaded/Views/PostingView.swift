//Made by Lumaa

import SwiftUI
import UIKit
import PhotosUI

struct PostingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(Navigator.self) private var navigator: Navigator
    
    var initialString: String = ""
    @State private var postText: NSMutableAttributedString = .init(string: "")
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
                        Text(accountManager.forceAccount().username)
                            .multilineTextAlignment(.leading)
                            .bold()
                        
                        DynamicTextEditor($postText)
                            .placeholder(String(localized: "status.posting.placeholder"))
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
                            let postedStatus: Status = try await client.post(endpoint: Statuses.postStatus(json: .init(status: postText.string, visibility: visibility)))
                            postingStatus = false
                            dismiss()
                            // navigate to post
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
                .disabled(postingStatus)
                .buttonStyle(LargeButton(filled: true, height: 7.5))
            }
            .padding()
        }
        .navigationBarBackButtonHidden()
        .navigationTitle(Text("status.posting"))
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
            DispatchQueue.main.async {
                postText.append(NSAttributedString(string: initialString))
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
                    postText.append(NSAttributedString(string: "#"))
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
}

#Preview {
    PostingView()
}
