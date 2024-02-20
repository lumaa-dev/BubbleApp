//Made by Lumaa

import SwiftUI

struct AttachmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDelegate.self) private var appDelegate
    
    var attachments: [MediaAttachment]
    @State var selectedId: String = ""
    
    private var selectedAttachment: MediaAttachment? {
        guard !selectedId.isEmpty else { return nil }
        return attachments.filter({ $0.id == selectedId })[0]
    }
    
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
                        currentZoom = 0
                        totalZoom = 1
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
                    }
            )
            .highPriorityGesture(
                DragGesture()
                    .onChanged { gesture in
                        if totalZoom > 1.1 {
                            currentPos = gesture.translation
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
                HStack(spacing: 10) {
                    Button {
                        readAlt.toggle()
                    } label: {
                        Text(String("ALT"))
                            .font(.body)
                    }
                    .disabled(selectedAttachment?.description?.isEmpty ?? true)
                    .opacity(selectedAttachment?.description?.isEmpty ?? true ? 0.3 : 1.0)
                    
                    Divider()
                        .frame(height: 10)
                    
                    Button {
                        Task {
                            let imgData = try await URLSession.shared.data(from: selectedAttachment?.url ?? URL.placeholder)
                            if let img = UIImage(data: imgData.0) {
                                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                .pill()
                .padding()
            }
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
    func pill() -> some View {
        self
            .foregroundStyle(Color(uiColor: UIColor.label))
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Material.thin)
            .clipShape(Capsule())
    }
}

#Preview {
    AttachmentView(attachments: [.init(id: "ABC", type: "photo", url: URL(string: "https://i.stack.imgur.com/HX3Aj.png"), previewUrl: URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg"), description: String("This displays the TabView with a page indicator at the bottom"), meta: nil), .init(id: "DEF", type: "photo", url: URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg"), previewUrl: URL(string: "https://cdn.pixabay.com/photo/2023/08/28/20/32/flower-8220018_1280.jpg"), description: nil, meta: nil)])
        .environment(AppDelegate())
}
