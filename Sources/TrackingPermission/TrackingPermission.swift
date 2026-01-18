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

#if PERMISSIONSKIT_TRACKING
import AppTrackingTransparency

#if canImport(FBSDKCoreKit)
import FBSDKCoreKit
#endif

@available(iOS 14, tvOS 14, *)
public extension HBPermission {

    static var tracking: TrackingPermission {
        return TrackingPermission()
    }
}

@available(iOS 14, tvOS 14, *)
public class TrackingPermission: HBPermission {
    
    open override var kind: HBPermission.Kind { .tracking }
    open var usageDescriptionKey: String? { "NSUserTrackingUsageDescription" }
    
    public override var status: HBPermission.Status {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted : return .denied
        @unknown default: return .denied
        }
    }
    
    @MainActor
    public override func request() async -> HBPermission.Status {
        let attStatus: ATTrackingManager.AuthorizationStatus =
            await withCheckedContinuation { continuation in
                ATTrackingManager.requestTrackingAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        
        #if HR_TRACKING_ENABLED
            HBEvent.log(attStatus == .authorized ? .allowTracking : .notAllowTracking)
        #endif
        
        #if canImport(FBSDKCoreKit)
            Settings.shared.isAdvertiserTrackingEnabled = (attStatus == .authorized)
        #endif
        
        return attStatus == .authorized ? .authorized : .denied
    }
}
#endif
