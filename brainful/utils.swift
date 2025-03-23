//
//  utils.swift
//  brainful
//  Modular utility functions for validation.
//  Created by Aditya Dedhia on 4/19/23.
//

import Foundation
import UIKit
import CoreLocation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}


func isIPad() -> Bool {
    let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
    if deviceIdiom == .pad {
        return true
    }
    let deviceModel = UIDevice.current.model
    print(deviceModel)
    let iPadModels = ["iPad", "iPad Air", "iPad Mini", "iPad Pro"]
    for model in iPadModels {
        if deviceModel.contains(model) {
            return true
        }
    }
    return false
}

func get_ip() -> String? {
    var address : String?
    // List interfaces
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }
    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        // Check IPv4 / IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            // Check interface name:
            // wifi = ["en0"]
            // wired = ["en2", "en3", "en4"]
            // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
            let name = String(cString: interface.ifa_name)
            if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
    }
    freeifaddrs(ifaddr)
    return address
}


func get_agent() -> String? {
    return UIDevice.current.name
}


class brainfulLocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()

    func getCurrentLocation(completion: @escaping (_ latitude: String, _ longitude: String) -> Void) {
        locationManager.requestWhenInUseAuthorization()

        guard CLLocationManager.locationServicesEnabled() else {
            // Handle location services disabled error
            return
        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()

        // Save the completion closure to a property so we can use it later
        self.completion = completion
    }

    var completion: ((_ latitude: String, _ longitude: String) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            // Handle location not found error
            return
        }

        let latitude = String(location.coordinate.latitude)
        let longitude = String(location.coordinate.longitude)

        // Call the completion closure with the latitude and longitude values as strings
        completion?(latitude, longitude)

        // Reset the completion closure to nil to prevent it from being called again
        completion = nil
    }
}
