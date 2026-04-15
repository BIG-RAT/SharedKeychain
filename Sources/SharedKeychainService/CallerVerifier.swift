//
//  Copyright 2026, Jamf
//

import Foundation

struct CallerVerifier {
    static func isAllowed(connection: NSXPCConnection) -> Bool {
        // Allow all callers for now; could add code signing requirement checks here
        return true
    }
}
