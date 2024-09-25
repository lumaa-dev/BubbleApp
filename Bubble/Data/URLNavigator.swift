// Made by Lumaa

import Foundation
import SwiftUI

extension Navigator {
    /// Handles the tapping links in posts, bios, etc...
    /// - Parameter uni: Defines if the function is triggered by the ``UniversalNavigator``.
    public func handle(url: URL, uni: Bool = false) -> OpenURLAction.Result {
        print("\(url.absoluteString) TAPPED")
        guard let client = self.client else { return .systemAction }
        let path: String = url.absoluteString.replacingOccurrences(of: AppInfo.scheme, with: "") // remove all path
        let urlPath: URL = URL(string: path) ?? URL(string: "https://example.com/")!
        if !url.absoluteString.starts(with: AppInfo.scheme) {
            if client.isAuth && client.hasConnection(with: url) {
                guard let actionType = urlPath.getActionType() else { fatalError("Couldn't get URLNav actionType") }
                let server: String = urlPath.host() ?? client.server

                print("actionType: \(actionType)")

                if actionType == .account {
                    Task {
                        do {
                            print("search acct: \(urlPath.lastPathComponent)@\(server.replacingOccurrences(of: "www.", with: ""))")
                            let search: SearchResults = try await client.get(endpoint: Search.search(query: "\(urlPath.lastPathComponent)@\(server.replacingOccurrences(of: "www.", with: ""))", type: "accounts", offset: nil, following: nil), forceVersion: .v2)
                            print(search)
                            if let acc: Account = search.accounts.first, !search.accounts.isEmpty {
                                guard !uni else { return OpenURLAction.Result.discarded }
                                self.navigate(to: .account(acc: acc))
                            } else {
                                guard uni else { return OpenURLAction.Result.discarded }
                                self.presentedSheet = .safari(url: url)
                            }
                        } catch {
                            print(error)
                        }

                        return OpenURLAction.Result.handled
                    }
                } else if actionType == .tag {
                    Task {
                        do {
                            let tag: String = urlPath.lastPathComponent
                            let search: SearchResults = try await client.get(endpoint: Search.search(query: "#\(tag)", type: "hashtags", offset: nil, following: nil), forceVersion: .v2)
                            print(search)
                            if let tgg: Tag = search.hashtags.first, !search.hashtags.isEmpty {
                                guard !uni else { return OpenURLAction.Result.discarded }
                                self.navigate(to: .timeline(timeline: .hashtag(tag: tgg.name, accountId: nil)))
                            } else {
                                guard uni else { return OpenURLAction.Result.discarded }
                                self.presentedSheet = .safari(url: url)
                            }
                        } catch {
                            print(error)
                        }

                        return OpenURLAction.Result.handled
                    }
                } else {
                    self.presentedSheet = .safari(url: url)
                }
            } else {
                print("clicked isn't handled properly")

                Task {
                    do {
                        let connections: [String] = try await client.get(endpoint: Instances.peers)
                        client.addConnections(connections)

                        if client.hasConnection(with: url) {
                            _ = self.handle(url: url, uni: uni)
                        } else {
                            guard uni else { return OpenURLAction.Result.discarded }
                            print("clicked isn't connection")
                            self.presentedSheet = .safari(url: url)
                        }
                    } catch {
                        guard uni else { return OpenURLAction.Result.discarded }
                        self.presentedSheet = .safari(url: url)
                    }

                    return OpenURLAction.Result.handled
                }
            }
        } else {
            print("deeplink detected")
            let actions: [String] = path.split(separator: /\/+/).map({ $0.lowercased().replacing(/\?(.)+$/, with: "") })
            if !actions.isEmpty, let mainAction: String = actions.first {
                if mainAction == "update" {
                    guard uni else { return OpenURLAction.Result.discarded }
                    self.presentedSheet = .update
                } else if mainAction == "new" {
                    guard uni else { return OpenURLAction.Result.discarded }
                    var newContent: String = ""
                    if let queries: [String : String] = urlPath.getQueryParameters() {
                        newContent = queries["text"] ?? ""
                    }

                    self.presentedSheet = .post(content: newContent, replyId: nil, editId: nil)
                }
            }
        }

        return OpenURLAction.Result.handled
    }
}

private extension URL {
    func getActionType() -> String.ActionType? {
        let pathComponents = self.pathComponents
        let subLinks = pathComponents.filter { $0 != "/" && !$0.isEmpty }
        
        return subLinks.first?.getRecognizer()
    }

    func getQueryParameters() -> [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            print("Invalid URL or no query items")
            return nil
        }

        // Convert query items into a dictionary
        var queryDict = [String: String]()
        for item in queryItems {
            queryDict[item.name] = item.value
        }

        return queryDict
    }
}

private extension String {
    func getRecognizer() -> String.ActionType? {
        if self.starts(with: "@") {
            return .account
        } else if self.starts(with: "tags") {
            return .tag
        }

        return nil
    }

    enum ActionType: String {
        case account = "account"
        case tag = "tag"
    }
}
