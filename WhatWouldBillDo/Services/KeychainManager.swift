import Foundation
import Security

/// Persists the free-tier conversation counter in iCloud Keychain so it survives
/// app delete/reinstall (and syncs across the user's devices via iCloud Keychain).
/// UserDefaults would be wiped on reinstall, handing out unlimited free convos.
enum KeychainManager {
    private static let service = "com.whatwouldbilldo.app.freeaccess"
    private static let account = "freeConvosUsed"

    static func saveFreeConvosUsed(_ count: Int) {
        var value = count
        let data = Data(bytes: &value, count: MemoryLayout<Int>.size)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(baseQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func loadFreeConvosUsed() -> Int {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              data.count == MemoryLayout<Int>.size
        else { return 0 }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }
}
