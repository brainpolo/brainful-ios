/**
 Author(s): Aditya Dedhia
 copyright 2022-2025 brainful.ai
 */

import Foundation
var domain = "ai.brainful"

class KeychainManager {
    
    enum KeychainError: Error {
        case duplicateKey
        case Unknown(OSStatus)
        case noKey
    }
    
    
    static func getPassword(
        attribute: String,
        username: String
    ) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: domain + "." + attribute,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var passwordData: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &passwordData)
        guard status != errSecItemNotFound else {
            UserDefaults.standard.removeObject(forKey: "username")  // Remove user from defaults
            throw KeychainError.noKey
        }
        guard status == errSecSuccess else { throw KeychainError.Unknown(status) }
        guard let passwordData = passwordData as? Data else { throw KeychainError.Unknown(status) }
        guard let password = String(data: passwordData, encoding: .utf8) else { throw KeychainError.Unknown(status) }
        return password
    }
    
    static func savePassword(
        attribute: String,
        username: String,
        password: Data
    ) throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: domain + "." + attribute as AnyObject,
            kSecAttrAccount as String: username as AnyObject,
            kSecValueData as String: password as AnyObject,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                do {
                    try updatePassword(attribute: attribute, username: username, password: password)
                } catch {
                    throw KeychainError.Unknown(status)
                }
            } else {
                throw KeychainError.Unknown(status)
            }
            return
        }
        print("Key saved successfully")
    }

    
    static func updatePassword(
            attribute: String,
            username: String,
            password: Data
        ) throws {
            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: domain + "." + attribute as AnyObject,
                kSecAttrAccount as String: username as AnyObject,
            ]
            let attributes: [String: AnyObject] = [
                kSecValueData as String: password as AnyObject,
            ]
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status == errSecItemNotFound {
                try savePassword(attribute: attribute, username: username, password: password)
            } else if status != errSecSuccess {
                throw KeychainError.Unknown(status)
            } else {
                print("Key updated successfully")
            }
        }
}
