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

    func save(serialNumber: String, alias: String) {
        let serialData = Data(serialNumber.utf8)
        let aliasData = Data(alias.utf8)

        let serialQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SerialNumber",
            kSecValueData as String: serialData
        ]

        let aliasQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "Alias",
            kSecValueData as String: aliasData
        ]

        // 기존 키 체인 항목을 업데이트하거나 추가
        SecItemDelete(serialQuery as CFDictionary)
        SecItemAdd(serialQuery as CFDictionary, nil)

        SecItemDelete(aliasQuery as CFDictionary)
        SecItemAdd(aliasQuery as CFDictionary, nil)

        print("Keychain Saved: SerialNumber \(serialNumber), Alias \(alias)")
    }

    func load() -> (serialNumber: String, alias: String)? {
        let serialQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SerialNumber",
            kSecReturnData as String: true
        ]

        let aliasQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "Alias",
            kSecReturnData as String: true
        ]

        var serialData: AnyObject?
        var aliasData: AnyObject?

        let serialStatus = SecItemCopyMatching(serialQuery as CFDictionary, &serialData)
        let aliasStatus = SecItemCopyMatching(aliasQuery as CFDictionary, &aliasData)

        if serialStatus == errSecSuccess, let serialData = serialData as? Data,
           aliasStatus == errSecSuccess, let aliasData = aliasData as? Data {
            let serialNumber = String(data: serialData, encoding: .utf8) ?? ""
            let alias = String(data: aliasData, encoding: .utf8) ?? ""
            return (serialNumber, alias)
        }

        return nil
    }

    func clear() {
        deleteKey(for: "SerialNumber")
        deleteKey(for: "Alias")
        print("All Keychain entries cleared.")
    }

    private func deleteKey(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("Successfully deleted \(key) from Keychain.")
        } else if status == errSecItemNotFound {
            print("\(key) not found in Keychain.")
        } else {
            print("Failed to delete \(key) from Keychain: \(status)")
        }
    }
}

