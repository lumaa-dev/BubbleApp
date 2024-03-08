//Made by Lumaa

import Foundation
import WatchConnectivity

#if os(watchOS)
import ClockKit
#endif

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// Handle WCSession status changes.
//
class SessionDelegator: NSObject, WCSessionDelegate {
    public var session: WCSession = .default
    public var lastMessage: GivenAccount? = nil
    public var allMessage: [GivenAccount] = []
    public var isWorking: Bool {
        self.session.isReachable
    }
    
    func initialize() {
        guard WCSession.isSupported() else { fatalError("Doesn't support WCSession") }
        session.delegate = self
        session.activate()
    }
    
    // Monitor WCSession activation state changes.
    //
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        return
    }
    
    // Monitor WCSession reachability state changes.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        self.session = session
    }
    
    // Did receive an app context.
    //
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let givenAccount = applicationContext["givenAccount"] as? String {
            self.lastMessage = GivenAccount.makeFromMessage(givenAccount)
            guard !self.allMessage.contains(where: { $0.bearerToken == self.lastMessage!.bearerToken }) else { return }
            self.allMessage.append(self.lastMessage!)
        }
    }
    
    // Did receive a message, and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let givenAccount = message["givenAccount"] as? String {
            self.lastMessage = GivenAccount.makeFromMessage(givenAccount)
            guard !self.allMessage.contains(where: { $0.bearerToken == self.lastMessage!.bearerToken }) else { return }
            self.allMessage.append(self.lastMessage!)
        }
    }
    
    // Did receive a message, and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        let response = ["success" : true, "timestamp": Int(Date.now.timeIntervalSince1970)] as [String : Any]
        replyHandler(response)
    }
    
    // Did receive a piece of message data, and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        self.lastMessage = GivenAccount.makeFromMessage(messageData)
        guard !self.allMessage.contains(where: { $0.bearerToken == self.lastMessage!.bearerToken }) else { return }
        self.allMessage.append(self.lastMessage!)
    }
    
    // Did receive a piece of message data, and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(messageData) // Echo back the data.
    }
    
    // Did receive a piece of userInfo.
    //
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        return
    }
    
    // Did finish sending a piece of userInfo.
    //
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
       return
    }
    
    // Did receive a file.
    //
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        return
    }
    
    // Did finish a file transfer.
    //
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        return
    }
    
    // WCSessionDelegate methods for iOS only.
    //
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
#endif
}
