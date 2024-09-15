// Made by Lumaa

import Foundation
import SwiftUI

extension Navigator {
    public func handle(url: URL) -> OpenURLAction.Result {
        return .systemAction
        guard let client = self.client else { return .systemAction }
        let path: String = url.absoluteString.replacingOccurrences(of: AppInfo.scheme, with: "") // remove all path
        let urlPath: URL = URL(string: path)!

        let server: String = urlPath.host() ?? client.server
        let lastIndex = urlPath.pathComponents.count - 1

        let actionType = urlPath.pathComponents[lastIndex - 1]

        if client.isAuth && client.hasConnection(with: url) {
            if urlPath.lastPathComponent.starts(with: "@") {
                Task {
                    do {
                        print("\(urlPath.lastPathComponent)@\(server.replacingOccurrences(of: "www.", with: ""))")
                        let search: SearchResults = try await client.get(endpoint: Search.search(query: "\(urlPath.lastPathComponent)@\(server.replacingOccurrences(of: "www.", with: ""))", type: "accounts", offset: nil, following: nil), forceVersion: .v2)
                        print(search)
                        let acc: Account = search.accounts.first ?? .placeholder()
                        self.navigate(to: .account(acc: acc))
                    } catch {
                        print(error)
                    }
                }
                return OpenURLAction.Result.handled
            } else {
                self.presentedSheet = .safari(url: url)
            }
        } else {
            Task {
                do {
                    let connections: [String] = try await client.get(endpoint: Instances.peers)
                    client.addConnections(connections)


                    if client.hasConnection(with: url) {
                        _ = self.handle(url: url)
                    } else {
                        self.presentedSheet = .safari(url: url)
                    }
                } catch {
                    self.presentedSheet = .safari(url: url)
                }
            }

            return OpenURLAction.Result.handled
        }
        return OpenURLAction.Result.handled
    }
}
