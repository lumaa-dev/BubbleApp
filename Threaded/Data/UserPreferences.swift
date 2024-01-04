//Made by Lumaa

import Foundation

@Observable
class UserPreferences: Codable, ObservableObject {
    private static let saveKey: String = "threaded-preferences.user"
    public static let defaultPreferences: UserPreferences = .init()
    
    // Final
    var displayedName: DisplayedName = .username
    var profilePictureShape: ProfilePictureShape = .circle
    
    // Experimental
    var showExperimental: Bool = false
    var experimental: UserPreferences.Experimental
    
    init(displayedName: DisplayedName = .username, profilePictureShape: ProfilePictureShape = .circle, showExperimental: Bool = false, experimental: UserPreferences.Experimental = .init()) {
        self.displayedName = displayedName
        self.profilePictureShape = profilePictureShape
        
        self.showExperimental = showExperimental
        self.experimental = experimental
    }
    
    @Observable
    class Experimental: Codable, ObservableObject {
        private static let saveKey: String = "threaded-preferences.experimental"
        
        var replySymbol: Bool = false
        
        init(replySymbol: Bool = false) {
            self.replySymbol = replySymbol
        }
        
        func saveAsCurrent() throws {
            let encoder = JSONEncoder()
            let json = try encoder.encode(self)
            UserDefaults.standard.setValue(json, forKey: UserPreferences.Experimental.saveKey)
        }
        
        static func loadAsCurrent() throws -> UserPreferences.Experimental? {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: UserPreferences.Experimental.saveKey) {
                let exp = try decoder.decode(UserPreferences.Experimental.self, from: data)
                return exp
            }
            return nil
        }
    }
    
    func saveAsCurrent() throws {
        let encoder = JSONEncoder()
        let json = try encoder.encode(self)
        UserDefaults.standard.setValue(json, forKey: UserPreferences.saveKey)
    }
    
    static func loadAsCurrent() throws -> UserPreferences? {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: UserPreferences.saveKey) {
            let pref = try decoder.decode(UserPreferences.self, from: data)
            return pref
        }
        return nil
    }
    
    // Enums and other
    
    enum DisplayedName: Codable, CaseIterable {
        case username, displayName, both
    }
    
    enum ProfilePictureShape: Codable, CaseIterable {
        case circle, rounded
    }
}
