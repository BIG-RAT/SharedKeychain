import Foundation
import Shared

public final class SharedKeychainClient {

    public static let shared = SharedKeychainClient()

    private let connection: NSXPCConnection

    public init() {

        connection = NSXPCConnection(
            machServiceName: "com.jamf.ie.sharedkeychain"
        )

        connection.remoteObjectInterface =
            NSXPCInterface(with: SharedKeychainProtocol.self)

        connection.resume()
    }

    private func proxy(errorHandler: @escaping (Error) -> Void) -> SharedKeychainProtocol {
        connection.remoteObjectProxyWithErrorHandler(errorHandler) as! SharedKeychainProtocol
    }

    public func getPassword(
        service: String,
        account: String,
        accessGroup: String = ""
    ) async throws -> String? {

        try await withCheckedThrowingContinuation { continuation in
            proxy { error in continuation.resume(throwing: error) }
                .getPassword(service: service, account: account, accessGroup: accessGroup) { password in
                    continuation.resume(returning: password)
                }
        }
    }

    public func getItem(
        service: String,
        account: String,
        accessGroup: String = ""
    ) async throws -> [String: String]? {

        try await withCheckedThrowingContinuation { continuation in
            proxy { error in continuation.resume(throwing: error) }
                .getItem(service: service, account: account, accessGroup: accessGroup) { item in
                    continuation.resume(returning: item)
                }
        }
    }

    public func setPassword(
        service: String,
        account: String,
        password: String,
        comment: String = "",
        accessGroup: String = ""
    ) async throws -> Bool {

        try await withCheckedThrowingContinuation { continuation in
            proxy { error in continuation.resume(throwing: error) }
                .setPassword(service: service, account: account, password: password, comment: comment, accessGroup: accessGroup) { success in
                    continuation.resume(returning: success)
                }
        }
    }

    public func deletePassword(
        service: String,
        account: String,
        accessGroup: String = ""
    ) async throws -> Bool {

        try await withCheckedThrowingContinuation { continuation in
            proxy { error in continuation.resume(throwing: error) }
                .deletePassword(service: service, account: account, accessGroup: accessGroup) { success in
                    continuation.resume(returning: success)
                }
        }
    }
}
