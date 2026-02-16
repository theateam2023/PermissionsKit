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

#if os(iOS) && PERMISSIONSKIT_LOCATION
import Foundation
import EventKit

public extension HBPermission {
    
    static func location(access: LocationAccess) -> LocationPermission {
        LocationPermission(kind: .location(access: access))
    }
}

public class LocationPermission: HBPermission {
    
    private var _kind: HBPermission.Kind
    
    // MARK: - Init
    
    init(kind: HBPermission.Kind) {
        self._kind = kind
    }
    
    open override var kind: HBPermission.Kind { self._kind }
    open var usageDescriptionKey: String? {
        switch _kind {
        case .location(let access):
            switch access {
            case .whenInUse:
                return "NSLocationWhenInUseUsageDescription"
            case .always:
                return "NSLocationAlwaysAndWhenInUseUsageDescription"
            }
        default:
            fatalError()
        }
    }
    
    public override var status: HBPermission.Status {
        let authorizationStatus: CLAuthorizationStatus = {
            let locationManager = CLLocationManager()
            if #available(iOS 14.0, tvOS 14.0, *) {
                return locationManager.authorizationStatus
            } else {
                return CLLocationManager.authorizationStatus()
            }
        }()
        
        switch authorizationStatus {
        #if os(iOS)
        case .authorized: return .authorized
        #endif
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .authorizedAlways: return .authorized
        case .authorizedWhenInUse: return .authorized
        @unknown default: return .denied
        }
    }
    
    public var isPrecise: Bool {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            switch CLLocationManager().accuracyAuthorization {
            case .fullAccuracy: return true
            case .reducedAccuracy: return false
            @unknown default: return false
            }
        }
        #endif
        return false
    }
    
    @available(*, unavailable, message: "Use request() stream instead")
    @MainActor
    public override func request() async -> HBPermission.Status {
        return status
    }
    
    @MainActor
    public func request() -> AsyncStream<HBPermission.Status> {
        AsyncStream { continuation in
            self.request { _ in
                continuation.yield(self.status)
            }
        }
    }
    
    @MainActor
    func request(complete: @escaping ((HBPermission.Status) -> Void)) {
        switch self._kind {
        case .location(let access):
            switch access {
            case .whenInUse:
                LocationWhenInUseHandler.shared = LocationWhenInUseHandler()
                LocationWhenInUseHandler.shared?.requestPermission() {
                    DispatchQueue.main.async {
                        let finalStatus = self.status
                        self.logStatus(finalStatus)
                        complete(finalStatus)
                    }
                }
            case .always:
                LocationAlwaysHandler.shared = LocationAlwaysHandler()
                LocationAlwaysHandler.shared?.requestPermission() {
                    DispatchQueue.main.async {
                        let finalStatus = self.status
                        self.logStatus(finalStatus)
                        complete(finalStatus)
                    }
                }
            }
        default:
            fatalError()
        }
    }
}
#endif
