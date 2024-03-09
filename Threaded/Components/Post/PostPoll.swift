//Made by Lumaa

import SwiftUI

struct PostPoll: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @State var poll: Poll
    @State private var selectedOption: [Int] = []
    
    @State private var submitted: Bool = false
    @State private var showResults: Bool = false
    
    init(poll: Poll) {
        self.poll = poll
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(poll.options) { option in
                let index = poll.options.firstIndex(where: { $0.id == option.id })
                let isMostVoted: Bool = self.isMostVoted(option: option)
                
                let clamped: Double = Double(option.votesCount ?? 0) / Double(poll.safeVotersCount)
                
                Button {
                    if !submitted && !poll.expired {
                        withAnimation(.spring(duration: 0.25)) {
                            selectVote(index ?? 0)
                            
                            if !poll.multiple {
                                Task {
                                    await vote()
                                }
                            }
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2.5)
                            .frame(width: 300, height: 50)
                            .overlay {
                                HStack {
                                    Text(option.title)
                                        .font(.subheadline)
                                        .padding(.leading, 25)
                                        .foregroundStyle(Color(uiColor: UIColor.label))
                                    
                                    if selectedOption.contains(index ?? 0) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(Color(uiColor: UIColor.label))
                                    }
                                    
                                    Spacer()
                                    
                                    if showResults {
                                        Text(String("\(Int(clamped * 100))%"))
                                            .font(.subheadline)
                                            .padding(.horizontal, 25)
                                            .foregroundStyle(Color(uiColor: UIColor.label))
                                    }
                                }
                            }
                        
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(uiColor: UIColor.label))
                            .frame(width: 300, height: 50)
                            .overlay {
                                HStack {
                                    Text(option.title)
                                        .foregroundStyle(Color(uiColor: UIColor.systemBackground))
                                        .font(.subheadline)
                                        .padding(.leading, 25)
                                    
                                    if selectedOption.contains(index ?? 0) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(Color(uiColor: UIColor.systemBackground))
                                    }
                                    
                                    Spacer()
                                    
                                    if showResults {
                                        Text(String("\(Int(clamped * 100))%"))
                                            .font(.subheadline)
                                            .padding(.horizontal, 25)
                                            .foregroundStyle(Color(uiColor: UIColor.systemBackground))
                                    }
                                }
                            }
                            .mask(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: showResults ? CGFloat(clamped * 300) : 0, height: 50)
                            }
                    }
                    .opacity((poll.expired || submitted) && !isMostVoted ? 0.5 : 1.0)
                }
                .buttonStyle(NoTapAnimationStyle())
            }
            
            if !poll.expired && !submitted {
                HStack {
                    if poll.multiple {
                        Button {
                            Task {
                                await vote()
                            }
                        } label: {
                            Text("status.poll.submit")
                        }
                        .buttonStyle(LargeButton(filled: true, height: 7.5, disabled: selectedOption.count == 0))
                        .disabled(selectedOption.count == 0)
                    }
                    
                    Button {
                        withAnimation(.spring) {
                            showResults.toggle()
                        }
                    } label: {
                        Text(showResults ? LocalizedStringKey("status.poll.hide-results") : LocalizedStringKey("status.poll.show-results"))
                    }
                    .buttonStyle(LargeButton(filled: false, height: 7.5))
                }
            }
            
            HStack {
                if !poll.expired {
                    Text("status.poll.expires-in.\(poll.expiresAt.value?.relativeFormatted ?? "unknown")")
                        .contentTransition(.numericText())
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.gray)
                } else {
                    Text("status.poll.expired")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.gray)
                }
                
                Spacer()
                
                Text("status.poll.voters.\(poll.safeVotersCount)")
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Color.gray)
            }
            .frame(width: 300)
        }
        .task {
            await getPoll()
        }
    }
    
    private func isMostVoted(option: Poll.Option) -> Bool {
        let sortedOptions: [Poll.Option] = poll.options.sorted(by: { $0.votesCount ?? 0 > $1.votesCount ?? 0 })
        let checkEquality: [Poll.Option] = sortedOptions.filter({ ($0.votesCount ?? 0) == (sortedOptions[0].votesCount ?? 0) })
        let isMostVoted: Bool = checkEquality.contains(where: { $0.id == option.id })
        return isMostVoted
    }
    
    private func getPoll() async {
        guard let client = accountManager.getClient() else { return }
        if let p: Poll = try? await client.get(endpoint: Polls.poll(id: poll.id)) {
            poll = p
            selectedOption = p.ownVotes ?? []
            submitted = p.voted ?? true
            showResults = submitted || p.expired
        }
    }
    
    private func selectVote(_ index: Int) {
        guard !poll.expired else { return }
        
        if poll.multiple {
            let remove: Bool = selectedOption.contains(index)
            if remove {
                selectedOption.removeAll(where: { $0 == index })
            } else {
                selectedOption.append(index)
            }
        } else {
            selectedOption = [index]
        }
    }
    
    private func vote() async {
        guard let client = accountManager.getClient(), !poll.expired else { return }
        
        _ = try? await client.post(endpoint: Polls.vote(id: poll.id, votes: selectedOption))
        withAnimation(.spring) {
            showResults = true
            submitted = true
        }
    }
}

#Preview {
    CompactPostView(status: Status.placeholder(forSettings: true, language: "fr"))
        .environment(AccountManager())
        .environment(UniversalNavigator())
        .environmentObject(UserPreferences.defaultPreferences)
        .environmentObject(Navigator())
}
