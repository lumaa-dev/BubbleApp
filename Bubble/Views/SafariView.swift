// Made by Lumaa

import SwiftUI
import WebKit

struct SafariView: View {
    var url: URL

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            Navigator.shared.presentedSheet = nil
                        } label: {
                            Label("close", systemImage: "xmark")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            #if !WIDGET
                            UIApplication.shared.open(url)
                            #endif
                        } label: {
                            Label("open.safari", systemImage: "safari")
                        }
                    }
                }
        }
    }
}
