//Made by Lumaa

import SwiftUI
import SwiftData

struct FilterView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @AppStorage("allowFilter") private var allowFilter: Bool = false
    @AppStorage("autoOnFilter") private var enableAutoFilter: Bool = false
    @AppStorage("censorsFilter") private var censorsFilter: Bool = false
    
    @State private var censorType: ContentFilter.FilterType = .censor
    
    @Query private var filters: [ModelFilter]
    @State private var wordsFilter: ContentFilter.WordFilter = ContentFilter.defaultFilter
    
    @State private var newWord: String = ""
    @FocusState private var filterState: Bool
    
    var body: some View {
        List {
            Section {
                WarningView(description: "beta.feature")
                    .listRowInsets(.none)
            }
            .listRowBackground(Color.yellow.opacity(0.25))
            
            Toggle(isOn: $allowFilter.animation(.spring)) {
                Text("settings.content-filter.allow")
            }
            .tint(Color.green)
            .listRowThreaded()
            
            if allowFilter {
                Toggle(isOn: $enableAutoFilter.animation(.spring)) {
                    Text("settings.content-filter.auto")
                }
                .tint(Color.green)
                .listRowThreaded()
                
                Picker(selection: $censorType) {
                    ForEach(ContentFilter.FilterType.allCases, id: \.self) { type in
                        type.label
                            .id(type)
                    }
                } label: {
                    Text("settings.content-filter.type")
                }
                .pickerStyle(.menu)
                .listRowThreaded()
                .onAppear {
                    censorType = censorsFilter ? .censor : .remove
                }
                .onChange(of: censorType) { _, newValue in
                    censorsFilter = newValue == .censor
                }
                
                Section(header: Text("settings.content-filter.words"), footer: Text("settings.content-filter.words.footer")) {
                    TextField("settings.content-filter.new-word", text: $newWord)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .focused($filterState)
                        .onSubmit {
                            filterState.toggle()
                            
                            let sensitive = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                            if !sensitive.isEmpty {
                                wordsFilter.content.append(sensitive)
                            }
                            
                            newWord = ""
                            saveData()
                        }
                    
                    ForEach(wordsFilter.content, id: \.self) { word in
                        Text(word)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                    }
                    .onDelete { i in
                        wordsFilter.content.remove(atOffsets: i)
                        saveData()
                    }
                }
                .onAppear {
                    self.wordsFilter = filters.compactMap({ ContentFilter.WordFilter(model: $0) }).first ?? ContentFilter.defaultFilter
                    filterState = true
                }
                .listRowThreaded()
            }
        }
        .navigationTitle(Text("settings.privacy.filter"))
        .navigationBarTitleDisplayMode(.inline)
        .listThreaded()
    }
    
    private func saveData() {
        let pack: ModelFilter = ModelFilter(postFilter: wordsFilter)
        
        do {
            if let firstFilter = filters.first {
                modelContext.delete(firstFilter)
            }
            modelContext.insert(pack)
            try modelContext.save()
        } catch {
            print("Couldn't save properly: \(error)")
        }
    }
}

#Preview {
    FilterView()
}
