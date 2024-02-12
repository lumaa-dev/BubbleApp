//Made by Lumaa

import SwiftUI

struct ProfilePicture: View {
    @EnvironmentObject private var pref: UserPreferences
    var url: URL
    var size: CGFloat = 50.0
    
    init(url: URL, size: CGFloat = 50.0) {
        self.url = url
        self.size = size
    }
    
    var cornerRadius: CGFloat {
        return pref.profilePictureShape == .circle ? (size / 2) : 10.0
    }
    
    init(url: URL) {
        self.url = url
    }
    
    init(url: String) {
        self.url = .init(string: url)!
    }
    
    var body: some View {
        OnlineImage(url: url, size: size, useNuke: true)
            .frame(width: size - 10, height: size - 10)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
