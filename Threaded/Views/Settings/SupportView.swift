//Made by Lumaa

import SwiftUI
import MessageUI

struct SupportView: View {
    @Environment(UniversalNavigator.self) private var uniNav: UniversalNavigator
    @Environment(AppDelegate.self) private var appDelegate: AppDelegate
    @Environment(\.openURL) private var openURL
    
    @State private var mailComposer: Bool = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                Text("support.platform")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        discordSupport
                            .listRowThreaded()
                        
                        matrixSupport
                            .listRowThreaded()
                        
                        mentionAccount
                            .listRowThreaded()
                        
                        mailApp
                            .listRowThreaded()
                    }
                    .scrollTargetLayout()
                    .safeAreaPadding(25)
                }
                .scrollTargetBehavior(.viewAligned)
            }
            .padding(.vertical)
            .frame(minWidth: appDelegate.windowWidth)
        }
        .listThreaded()
        .navigationTitle(Text("support"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $mailComposer) {
            MailView(result: $mailResult)
        }
    }
    
    var discordSupport: some View {
        VStack(alignment: .center) {
            Image("DiscordMark")
                .mark()
            
            Text("support.discord")
                .font(.title.bold())
            
            Text("support.discord.description")
                .padding(.horizontal)
                .lineLimit(3, reservesSpace: true)
            
            Button {
                let discordUrl = URL(string: "https://discord.gg/MaHcRbkX46")
                openURL(discordUrl!)
            } label: {
                Text("support.discord.join")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .zIndex(10.0)
            .buttonStyle(.borderedProminent)
            .tint(Color.blurple)
            .padding(.vertical)
        }
        .boxify(appDelegate.windowWidth - 50, bgColor: Color.blurple)
    }
    
    var matrixSupport: some View {
        VStack(alignment: .center) {
            Image("ElementMark")
                .mark()
            
            Text("support.matrix")
                .font(.title.bold())
            
            Text("support.matrix.description")
                .padding(.horizontal)
                .lineLimit(3, reservesSpace: true)
            
            Button {
                let matrixUrl = URL(string: "https://matrix.to/#/#threadedapp:matrix.org")
                openURL(matrixUrl!)
            } label: {
                Text("support.matrix.join")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .zIndex(10.0)
            .buttonStyle(.borderedProminent)
            .tint(Color.mountainMeadow)
            .padding(.vertical)
        }
        .boxify(appDelegate.windowWidth - 50,bgColor: Color.mountainMeadow)
    }
    
    var mentionAccount: some View {
        VStack(alignment: .center) {
            Image(systemName: "at")
                .mark()
                .foregroundStyle(Color(uiColor: UIColor.label))
            
            Text("support.mention")
                .font(.title.bold())
            
            Text("support.mention.description")
                .padding(.horizontal)
                .lineLimit(3, reservesSpace: true)
            
            Button {
                uniNav.presentedSheet = .post(content: "@Threaded@mastodon.online", replyId: nil, editId: nil)
            } label: {
                Text("support.mention.post")
                    .foregroundStyle(Color(uiColor: UIColor.systemBackground))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .zIndex(10.0)
            .buttonStyle(.borderedProminent)
            .tint(Color(uiColor: UIColor.label))
            .padding(.vertical)
        }
        .boxify(appDelegate.windowWidth - 50, bgColor: Color(uiColor: UIColor.label))
    }
    
    var mailApp: some View {
        VStack(alignment: .center) {
            Image(systemName: "envelope.fill")
                .mark()
                .foregroundStyle(Color.blue)
            
            Text("support.email")
                .font(.title.bold())
            
            Text("support.email.description")
                .padding(.horizontal)
                .lineLimit(3, reservesSpace: true)
            
            Button {
                mailComposer.toggle()
            } label: {
                Text("support.mail.send")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .zIndex(10.0)
            .disabled(!MFMailComposeViewController.canSendMail())
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            .padding(.vertical)
            .overlay(alignment: .bottom) {
                if !MFMailComposeViewController.canSendMail() {
                    Text("support.mail.no-mail")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                        .frame(width: 300)
                        .offset(y: 15.0)
                }
            }
            
        }
        .boxify(appDelegate.windowWidth - 50, bgColor: Color.blue)
    }
}

#Preview("FR") {
    NavigationStack {
        SupportView()
    }
    .environment(\.locale, Locale(identifier: "fr-fr"))
    .environment(AppDelegate())
}

#Preview("EN") {
    NavigationStack {
        SupportView()
    }
    .environment(\.locale, Locale(identifier: "en-us"))
    .environment(AppDelegate())
}

private extension View {
    @ViewBuilder
    func boxify(_ width: CGFloat, bgColor: Color? = nil) -> some View {
        self
            .frame(width: width, height: 330)
            .padding(.vertical)
            .zIndex(5.0)
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(uiColor: UIColor.label).opacity(0.4))
                    .background() {
                        Rectangle()
                            .fill(bgColor != nil ? LinearGradient(colors: [bgColor!.opacity(0.15), bgColor!.opacity(0.3)], startPoint: .bottom, endPoint: .top) : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                            .allowsHitTesting(false)
                    }
                
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .zIndex(1.0)
            }
    }
}

private extension Image {
    @ViewBuilder
    func mark() -> some View {
        self.resizable()
            .scaledToFit()
            .frame(width: 75, height: 75)
    }
}

private extension Color {
    static let blurple: Color = Color(red: 88 / 255, green: 101 / 255, blue: 242 / 255)
    static let mountainMeadow: Color = Color(red: 13 / 255, green: 189 / 255, blue: 139 / 255)
}
