//
//  Copyright 2026, Jamf
//

import Foundation

@objc public protocol SharedKeychainProtocol {
    func getPassword(service: String, account: String, accessGroup: String, reply: @escaping (String?) -> Void)
    func getItem(service: String, account: String, accessGroup: String, reply: @escaping ([String: String]?) -> Void)
    func setPassword(service: String, account: String, password: String, comment: String, accessGroup: String, reply: @escaping (Bool) -> Void)
    func deletePassword(service: String, account: String, accessGroup: String, reply: @escaping (Bool) -> Void)
}
