// The MIT License (MIT)
// Copyright © 2022 Sparrow Code LTD (https://sparrowcode.io, hello@sparrowcode.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if PERMISSIONSKIT_SPM
import PermissionsKit
#endif

#if os(iOS) && PERMISSIONSKIT_MOTION
import Foundation
import CoreMotion

public extension HBPermission {
    
    static var motion: MotionPermission {
        return MotionPermission()
    }
}

public class MotionPermission: HBPermission {
    
    open override var kind: HBPermission.Kind { .motion }
    open var usageDescriptionKey: String? { "NSMotionUsageDescription" }
    
    public override var status: HBPermission.Status {
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request() async -> HBPermission.Status {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let manager = CMMotionActivityManager()
            let today = Date()
            
            manager.queryActivityStarting(from: today, to: today, to: .main) { _, _ in
                continuation.resume()
                manager.stopActivityUpdates()
            }
        }
        
        let currentStatus = self.status
        logStatus(currentStatus)
        
        return currentStatus
    }
}
#endif
