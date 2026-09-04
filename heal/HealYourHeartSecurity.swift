//
//  HealYourHeartSecurity.swift
//  heal
//
//  Keychain storage for anything this app ever needs to keep private
//  on-device. There is no server and no provider key to hold.
//

import Foundation
import Security

protocol SecretStoring {
    func save(_ value: String, for key: String) throws
    func read(_ key: String) throws -> String?
    func delete(_ key: String) throws
}

enum KeychainStoreError: Error, Equatable {
    case invalidData
    case unhandledStatus(OSStatus)
}

struct KeychainSecretStore: SecretStoring {
    private let service = "com.healyourheart.app"

    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainStoreError.invalidData
        }

        try delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainStoreError.unhandledStatus(status)
        }
    }

    func read(_ key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainStoreError.unhandledStatus(status)
        }

        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainStoreError.invalidData
        }

        return value
    }

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.unhandledStatus(status)
        }
    }
}
