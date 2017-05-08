import Security

internal struct Keychain {
    internal let service: String

    fileprivate var defaultClassAndAttributes: [String: AnyObject] {
        return [
            String(kSecClass): String(kSecClassGenericPassword) as AnyObject,
            String(kSecAttrAccessible): String(kSecAttrAccessibleAfterFirstUnlock) as AnyObject,
            String(kSecAttrService): service as AnyObject,
        ]
    }

    internal func dataForKey(_ key: String) -> Data? {
        var attributes = defaultClassAndAttributes
        attributes[String(kSecAttrAccount)] = key as AnyObject?
        attributes[String(kSecMatchLimit)] = kSecMatchLimitOne
        attributes[String(kSecReturnData)] = true as AnyObject?

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { pointer in
            return SecItemCopyMatching(attributes as CFDictionary, UnsafeMutablePointer(pointer))
        }

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    internal func valueForKey(_ key: String) -> String? {
        return dataForKey(key).flatMap { data in
            String(data: data, encoding: String.Encoding.utf8)
        }
    }

    internal func setData(_ data: Data, forKey key: String) {
        var attributes = defaultClassAndAttributes
        attributes[String(kSecAttrAccount)] = key as AnyObject?
        attributes[String(kSecValueData)] = data as AnyObject?
        SecItemAdd(attributes as CFDictionary, nil)
    }

    internal func setValue(_ value: String, forKey key: String) {
        if let data = value.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            setData(data, forKey: key)
        }
    }

    internal func updateData(_ data: Data, forKey key: String) {
        var query = defaultClassAndAttributes
        query[String(kSecAttrAccount)] = key as AnyObject?

        var attributesToUpdate = query
        attributesToUpdate[String(kSecClass)] = nil
        attributesToUpdate[String(kSecValueData)] = data as AnyObject?

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if status == errSecItemNotFound || status == errSecNotAvailable {
            setData(data, forKey: key)
        }
    }

    internal func updateValue(_ value: String, forKey key: String) {
        if let data = value.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            updateData(data, forKey: key)
        }
    }

    internal func removeValueForKey(_ key: String) {
        var attributes = defaultClassAndAttributes
        attributes[String(kSecAttrAccount)] = key as AnyObject?
        SecItemDelete(attributes as CFDictionary)
    }

    internal subscript(key: String) -> String? {
        get {
            return valueForKey(key)
        }

        set {
            if let value = newValue {
                updateValue(value, forKey: key)
            } else {
                removeValueForKey(key)
            }
        }
    }
}

/// A persistent keychain-based access token store.
@objc public class OAuthAccessTokenKeychainStore: NSObject, OAuthAccessTokenStore {
    private var keychain: Keychain

    /// Creates an instance initialized to the given keychain service.
    ///
    /// - parameter service: The keychain service.
    ///     Default: `de.rheinfabrik.heimdallr.oauth`.
    public init(service: String = "de.rheinfabrik.heimdallr.oauth") {
        keychain = Keychain(service: service)
    }

    public func storeAccessToken(_ accessToken: OAuthAccessToken?) {
        keychain["access_token"] = accessToken?.accessToken
        keychain["token_type"] = accessToken?.tokenType
        keychain["expires_at"] = accessToken?.expiresAt?.timeIntervalSince1970.description
        keychain["refresh_token"] = accessToken?.refreshToken
    }

    public func retrieveAccessToken() -> OAuthAccessToken? {
        let accessToken = keychain["access_token"]
        let tokenType = keychain["token_type"]
        let refreshToken = keychain["refresh_token"]
        let expiresAt = keychain["expires_at"].flatMap { description in
            return Double(description).flatMap { expiresAtInSeconds in
                Date(timeIntervalSince1970: expiresAtInSeconds)
            }
        }

        if let accessToken = accessToken, let tokenType = tokenType {
            return OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
        }

        return nil
    }
}
