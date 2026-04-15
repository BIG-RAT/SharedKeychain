//
//  Copyright 2026, Jamf
//

import Foundation
import Security
#if SWIFT_PACKAGE
import Shared
#endif

class SharedKeychainService: NSObject, SharedKeychainProtocol {

    private func applyAccessGroup(_ accessGroup: String, to query: inout [String: Any]) {
        guard !accessGroup.isEmpty else { return }
        query[kSecAttrAccessGroup as String] = accessGroup
        query[kSecUseDataProtectionKeychain as String] = true
    }

    func getPassword(service: String, account: String, accessGroup: String, reply: @escaping (String?) -> Void) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        applyAccessGroup(accessGroup, to: &query)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            reply(nil)
            return
        }
        reply(password)
    }

    func getItem(service: String, account: String, accessGroup: String, reply: @escaping ([String: String]?) -> Void) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        applyAccessGroup(accessGroup, to: &query)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let attrs = result as? [String: Any] else {
            reply(nil)
            return
        }

        var item: [String: String] = [:]
        if let data = attrs[kSecValueData as String] as? Data,
           let password = String(data: data, encoding: .utf8) {
            item["password"] = password
        }
        if let comment = attrs[kSecAttrComment as String] as? String {
            item["comment"] = comment
        }
        reply(item.isEmpty ? nil : item)
    }

    func setPassword(service: String, account: String, password: String, comment: String, accessGroup: String, reply: @escaping (Bool) -> Void) {
        guard let passwordData = password.data(using: .utf8) else {
            reply(false)
            return
        }

        // Check if item already exists
        var lookupQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        applyAccessGroup(accessGroup, to: &lookupQuery)

        let existing = SecItemCopyMatching(lookupQuery as CFDictionary, nil)

        if existing == errSecSuccess {
            // Update existing item
            var attributes: [String: Any] = [kSecValueData as String: passwordData]
            if !comment.isEmpty {
                attributes[kSecAttrComment as String] = comment
            }
            let status = SecItemUpdate(lookupQuery as CFDictionary, attributes as CFDictionary)
            reply(status == errSecSuccess)
        } else {
            // Add new item
            var addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: passwordData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            if !comment.isEmpty {
                addQuery[kSecAttrComment as String] = comment
            }
            applyAccessGroup(accessGroup, to: &addQuery)
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            reply(status == errSecSuccess)
        }
    }

    func deletePassword(service: String, account: String, accessGroup: String, reply: @escaping (Bool) -> Void) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        applyAccessGroup(accessGroup, to: &query)

        let status = SecItemDelete(query as CFDictionary)
        // errSecItemNotFound is also acceptable (already deleted)
        reply(status == errSecSuccess || status == errSecItemNotFound)
    }
}
