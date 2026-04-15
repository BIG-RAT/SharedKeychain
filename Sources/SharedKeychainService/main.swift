//
//  Copyright 2026, Jamf
//

import Foundation
#if SWIFT_PACKAGE
import Shared
#endif

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard CallerVerifier.isAllowed(connection: connection) else {
            return false
        }
        connection.exportedInterface = NSXPCInterface(with: SharedKeychainProtocol.self)
        connection.exportedObject = SharedKeychainService()
        connection.resume()
        return true
    }
}

let delegate = ServiceDelegate()
let listener = NSXPCListener(machServiceName: "com.jamf.ie.sharedkeychain")
listener.delegate = delegate
listener.resume()

RunLoop.main.run()
