//
//  Reachability.swift
//  Recipe App
//
//  Created by Alex Tang on 11/28/24.
//

import SystemConfiguration
import Foundation

class Reachability {
    private let reachability: SCNetworkReachability
    
    var whenReachable: ((Reachability) -> Void)?
    var whenUnreachable: ((Reachability) -> Void)?
    
    init?() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let reachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return nil
        }
        
        self.reachability = reachability
    }
    
    func startNotifier() throws {
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        
        guard SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
            guard let info = info else { return }
            let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
            reachability.flagsChanged(flags)
        }, &context) else {
            throw Error.failedToSetCallback
        }
        
        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) else {
            throw Error.failedToSetDispatchQueue
        }
        
        flagsChanged(SCNetworkReachabilityFlags())
    }
    
    func stopNotifier() {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    }
    
    private func flagsChanged(_ flags: SCNetworkReachabilityFlags) {
        if flags.contains(.reachable) {
            whenReachable?(self)
        } else {
            whenUnreachable?(self)
        }
    }
    
    enum Error: Swift.Error {
        case failedToSetCallback
        case failedToSetDispatchQueue
    }
}
