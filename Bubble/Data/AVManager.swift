// Made by Lumaa

import Foundation
import AVFoundation

final class AVManager {
    static var duckOther: Bool {
        set {
            self.ducking = newValue
            try? AVAudioSession.sharedInstance().setActive(newValue)
        }
        get {
            self.ducking
        }
    }

    private static var ducking: Bool = true

    static func configureForVideoPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AVManager] Couldn't configure audio for video playback: \(error)")
        }
    }
}
