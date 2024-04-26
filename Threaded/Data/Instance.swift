//Made by Lumaa

import Foundation

public struct Instance: Codable, Sendable {
    static let blocklistUrl: URL? = URL(string: "https://codeberg.org/oliphant/blocklists/raw/branch/main/blocklists/_unified_tier0_blocklist.csv")
    
    @MainActor
    static func getBlocklist() -> [String] {
        var final: [String] = []
        //locate the file you want to use
        guard let filelink = Instance.blocklistUrl else {
            return []
        }
        
        //convert that file into one long string
        var data = ""
        do {
            data = try String(contentsOf: filelink)
        } catch {
            print(error)
            return []
        }
        
        //now split that string into an array of "rows" of data.  Each row is a string.
        var rows = data.components(separatedBy: "\n")
        
        //if you have a header row, remove it here
        rows.removeFirst()
        
        //now loop around each row, and split it into each of its columns
        for row in rows {
            let columns = row.components(separatedBy: ",")
            
            //check that we have enough columns
            if columns.count > 0 {
                let instanceUrl = columns[0]
                final.append(instanceUrl)
            }
        }
        
        return final
    }
    
    public struct Stats: Codable, Sendable {
        public let userCount: Int
        public let statusCount: Int
        public let domainCount: Int
    }
    
    public struct Configuration: Codable, Sendable {
        public struct Statuses: Codable, Sendable {
            public let maxCharacters: Int
            public let maxMediaAttachments: Int
        }
        
        public struct Polls: Codable, Sendable {
            public let maxOptions: Int
            public let maxCharactersPerOption: Int
            public let minExpiration: Int
            public let maxExpiration: Int
        }
        
        public let statuses: Statuses
        public let polls: Polls
    }
    
    public struct Rule: Codable, Identifiable, Sendable {
        public let id: String
        public let text: String
    }
    
    public struct URLs: Codable, Sendable {
        public let streamingApi: URL?
    }
    
    public let title: String
    public let shortDescription: String
    public let email: String
    public let version: String
    public let stats: Stats
    public let languages: [String]?
    public let registrations: Bool
    public let thumbnail: URL?
    public let configuration: Configuration?
    public let rules: [Rule]?
    public let urls: URLs?
}

public struct InstanceApp: Codable, Identifiable {
    public let id: String
    public let name: String
    public let website: URL?
    public let redirectUri: String
    public let clientId: String
    public let clientSecret: String
    public let vapidKey: String?
}

extension InstanceApp: Sendable {}
