//Made by Lumaa

import Foundation
import CoreHaptics

struct Haptic: Hashable {
    var intensity: CGFloat
    var sharpness: CGFloat
    var interval: CGFloat
    
    static let tap: [Haptic] = [Haptic(intensity: 0.5, sharpness: 0.8, interval: 0.0)]
    static let success: [Haptic] = [
        Haptic(intensity: 0.5, sharpness: 1.0, interval: 0.0),
        Haptic(intensity: 0.9, sharpness: 0.5, interval: 0.2)
    ]
    static let error: [Haptic] = [
        Haptic(intensity: 1.0, sharpness: 0.7, interval: 0.0),
        Haptic(intensity: 1.0, sharpness: 0.3, interval: 0.2)
    ]
    static let lock: [Haptic] = [
        Haptic(intensity: 1.0, sharpness: 0.7, interval: 0.0),
        Haptic(intensity: 0.55, sharpness: 0.55, interval: 0.1),
        Haptic(intensity: 0.35, sharpness: 0.35, interval: 0.1)
    ]
}

class HapticManager {
    private static var supportsHaptics: Bool = false
    private static var engine: CHHapticEngine?
    
    static func playHaptics(haptics: [Haptic]) {
        guard supportsHaptics else { return }
        var events = [CHHapticEvent]()
        let hapticIntensity: [CGFloat] = haptics.map { $0.intensity }
        let hapticSharpness: [CGFloat] = haptics.map { $0.sharpness }
        let intervals: [CGFloat] = haptics.map({ $0.interval })
        
        for index in 0..<haptics.count {
            let relativeInterval: TimeInterval = TimeInterval(intervals[0...index].reduce(0, +))
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(hapticIntensity[index]))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(hapticSharpness[index]))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: relativeInterval)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    
    static func prepareHaptics() {
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        HapticManager.supportsHaptics = hapticCapability.supportsHaptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            HapticManager.engine = try CHHapticEngine()
            engine?.isMutedForHaptics = false
            try engine?.start()
        } catch {
            print("Error creating the engine: \(error.localizedDescription)")
        }
        
        engine?.resetHandler = {
            print("Restarting haptic engine")
            do {
                try self.engine?.start()
            } catch {
                fatalError("Failed to restart the engine: \(error)")
            }
        }
    }
}
