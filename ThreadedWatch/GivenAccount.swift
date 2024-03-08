//Made by Lumaa

import Foundation

struct GivenAccount: Hashable {
    static let messageSeparator: String = "||"
    
    let acct: String
    let bearerToken: String
    
    init(acct: String, bearerToken: String) {
        self.acct = acct
        self.bearerToken = bearerToken
    }
    
    private func messageString() -> String {
        return "\(self.acct)\(Self.messageSeparator)\(self.bearerToken)"
    }
    
    func turnToMessage() -> Data {
        let str = self.messageString()
        return str.data(using: .utf8) ?? Data()
    }
    
    func turnToDictionary() -> [String : Any] {
        let str = self.messageString()
        return ["givenAccount" : str]
    }
    
    func toLogged() -> LoggedAccount {
        let oauth = OauthToken(accessToken: self.bearerToken, tokenType: "Bearer", scope: "", createdAt: .nan)
        return LoggedAccount(token: oauth, acct: self.acct)
    }
    
    static func makeFromMessage(_ message: Data) -> GivenAccount {
        if let string = String(data: message, encoding: .utf8) {
            let decomposed = string.split(separator: Self.messageSeparator)
            let acct = decomposed[0]
            let bearerToken = decomposed[1]
            
            return GivenAccount(acct: String(acct), bearerToken: String(bearerToken))
        }
        fatalError("Message couldn't be stringified")
    }
    
    static func makeFromMessage(_ message: String) -> GivenAccount {
        let decomposed = message.split(separator: Self.messageSeparator)
        let acct = decomposed[0]
        let bearerToken = decomposed[1]
        
        return GivenAccount(acct: String(acct), bearerToken: String(bearerToken))
    }
}

extension LoggedAccount {
    func toGiven() -> GivenAccount {
        return GivenAccount(acct: self.acct, bearerToken: self.token.accessToken)
    }
}
