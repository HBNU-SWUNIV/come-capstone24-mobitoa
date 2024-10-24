////
////  WiFiService.swift
////  NetHawk
////
////  Created by mobicom on 6/5/24.
////
//
//// Services/WiFiService.swift
//import SystemConfiguration.CaptiveNetwork
//
//class WiFiService {
//    
//    func getWiFiAddress() -> String? {
//        var address: String?
//        
//        // Get list of all interfaces on the local machine:
//        var ifaddr: UnsafeMutablePointer<ifaddrs>?
//        guard getifaddrs(&ifaddr) == 0 else {
//            print("Error getting interface addresses")
//            return nil
//        }
//        guard let firstAddr = ifaddr else {
//            print("No interfaces found")
//            return nil
//        }
//        
//        // For each interface ...
//        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
//            let interface = ifptr.pointee
//            
//            // Check for IPv4 interface:
//            let addrFamily = interface.ifa_addr.pointee.sa_family
//            if addrFamily == UInt8(AF_INET) {
//                
//                // Check if interface is a Wi-Fi interface:
//                let name = String(cString: interface.ifa_name)
//                print("Checking interface: \(name)")
//                if name.hasPrefix("en") {
//                    
//                    // Convert interface address to a human readable string:
//                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
//                                &hostname, socklen_t(hostname.count),
//                                nil, socklen_t(0), NI_NUMERICHOST)
//                    let ipAddress = String(cString: hostname)
//                    print("Found IP address: \(ipAddress)")
//                    
//                    // Check if the IP address is a private IP address:
//                    if isPrivateIPAddress(ipAddress) {
//                        address = ipAddress
//                        break  // We've found the Wi-Fi interface with a private IP address, so we can stop looking
//                    }
//                }
//            }
//        }
//        freeifaddrs(ifaddr)
//        
//        return address
//    }
//
//    func isPrivateIPAddress(_ ipAddress: String) -> Bool {
//        let ipComponents = ipAddress.components(separatedBy: ".").compactMap({ Int($0) })
//        
//        guard ipComponents.count == 4 else {
//            return false
//        }
//        
//        switch ipComponents[0] {
//        case 10:
//            return true
//        case 172:
//            return ipComponents[1] >= 16 && ipComponents[1] <= 31
//        case 192:
//            return ipComponents[1] == 168
//        default:
//            return false
//        }
//    }
//}
