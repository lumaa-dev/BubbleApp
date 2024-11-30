// Made by Lumaa

import UIKit
import SwiftUI
import Foundation
import UserNotifications

class AppNotification {
    /// Authorizes the app to send the device's APNS token to the "Push\_URL" string in the `Secret.plist` file
    private static var registerToken: Bool = false

    @AppStorage("sentToken") private static var sentToken: Bool = false
    static var hasSentToken: Bool {
        get {
            self.sentToken
        }
    }
    static var allowedNotifications: Bool = false

    init() {}

    static func requestAuthorization(completionHandler: @escaping (Bool) -> Void = {_ in}) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, err in
            completionHandler(success)
            self.allowedNotifications = success

            guard success else { print("Did not validate"); return }

            print("REQUESTED PUSH NOTIFICATION")
            Task {
                #if !WIDGET
                await UIApplication.shared.registerForRemoteNotifications()
                #endif
            }
        }
    }

    static func sendToken(client: Client, oauth: OauthToken) async {
        guard let acc: Account = try? await client.get(endpoint: Accounts.verifyCredentials), let accUrl: URL = acc.url, let server: String = accUrl.host() else { return }
        self.sendToken(instanceUrl: server, accessToken: oauth.accessToken)
    }

    static func sendToken(account: Account, oauth: OauthToken) {
        guard let server = account.acct.split(separator: "@").first else { return }
        self.sendToken(instanceUrl: String(server), accessToken: oauth.accessToken)
    }

    static private func sendToken(instanceUrl: String, accessToken: String) {
        guard let plist = AppDelegate.readSecret(), let baseUrl = plist["Push_URL"], !Self.hasSentToken, Self.allowedNotifications && Self.registerToken else {
            return
        }

        let header: [String: String] = [
            "deviceToken": AppDelegate.deviceToken,
            "instance": instanceUrl,
            "accessToken": accessToken
        ]

        var formatted: String = ""

        for (key, value) in header {
            if value == header.values.reversed().first {
                formatted += "\(key)=\(value)"
            } else {
                formatted += "\(key)=\(value)&"
            }
        }

        print(formatted)

//        let encoder: JSONEncoder = .init()
//        if let json = try? encoder.encode(header) {
//            var req = URLRequest(url: URL(string: "\(baseUrl)/push/add")!)
//            req.httpMethod = "POST"
////            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//            req.httpBody = json
//
//            URLSession.shared.dataTask(with: req) { data, res, err in
//                if err != nil {
//                    print(err?.localizedDescription ?? "No error details")
//                    return
//                }
//
//                let decoder: JSONDecoder = .init()
//                if let genRes: GenericResponse = try? decoder.decode(GenericResponse.self, from: data ?? Data()) {
//                    let resType: String = genRes.success ? "successfully" : "incorrectly" // incorrect cause idk how to say "failed" with -ly
//                    print("Server \(resType) replied with: \(genRes.message ?? "[NO MESSAGE]")")
//                } else {
//                    print("No valid GenericResponse was output: \(String(data: data ?? Data(), encoding: .utf8) ?? "[NOT DECODED]")")
//                }
//            }.resume()
//        }

        var req = URLRequest(url: URL(string: "\(baseUrl)/push/add")!, timeoutInterval: Double.infinity)
        req.httpMethod = "POST"
        req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = formatted.data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, res, err in
            if err != nil {
                print(err?.localizedDescription ?? "No error details")
                return
            }

            let decoder: JSONDecoder = .init()
            if let genRes: GenericResponse = try? decoder.decode(GenericResponse.self, from: data ?? Data()) {
                let resType: String = genRes.success ? "successfully" : "incorrectly" // incorrect cause idk how to say "failed" with -ly
                print("Server \(resType) replied with: \(genRes.message ?? "[NO MESSAGE]")")
            } else {
                print("No valid GenericResponse was output: \(String(data: data ?? Data(), encoding: .utf8) ?? "[NOT DECODED]")")
            }
        }.resume()
    }

    /// This is a generic server response from the APNS server
    struct GenericResponse: Decodable {
        let success: Bool
        let message: String?
    }
}
