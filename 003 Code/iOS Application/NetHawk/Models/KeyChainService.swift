//
//  KeyChainService.swift
//  NetHawk
//
//  Created by mobicom on 6/6/24.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    func save(broker: String, mac: String) {
        let formattedMac = mac.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "")
        
        let brokerData = Data(broker.utf8)
        let macData = Data(formattedMac.utf8)
        
        let brokerQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "BrokerAddress",
            kSecValueData as String: brokerData
        ]
        
        let macQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MACAddress",
            kSecValueData as String: macData
        ]
        
        SecItemAdd(brokerQuery as CFDictionary, nil)
        SecItemAdd(macQuery as CFDictionary, nil)
        
        print("Keychain Saved : \(brokerQuery)")
        print("Keychain Saved : \(macQuery)")
    }
    
    func load() -> (broker: String, mac: String)? {
        let brokerQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "BrokerAddress",
            kSecReturnData as String: true
        ]
        
        let macQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MACAddress",
            kSecReturnData as String: true
        ]
        
        var brokerData: AnyObject?
        var macData: AnyObject?
        
        let brokerStatus = SecItemCopyMatching(brokerQuery as CFDictionary, &brokerData)
        let macStatus = SecItemCopyMatching(macQuery as CFDictionary, &macData)
        
        if brokerStatus == errSecSuccess, let brokerData = brokerData as? Data,
           macStatus == errSecSuccess, let macData = macData as? Data {
            let broker = String(data: brokerData, encoding: .utf8) ?? ""
            let formattedMac = String(data: macData, encoding: .utf8) ?? ""
            let mac = formatMACAddress(formattedMac)
            return (broker, mac)
        }
        
        return nil
    }
    
    private func formatMACAddress(_ macAddress: String) -> String {
        var formattedMACAddress = ""
        var index = 0
        
        for char in macAddress {
            formattedMACAddress.append(char)
            
            if (index + 1) % 2 == 0 && index < macAddress.count - 1 {
                formattedMACAddress.append(":")
            }
            
            index += 1
        }
        
        return formattedMACAddress
    }
}
