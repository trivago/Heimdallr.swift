import Security

internal struct Keychain {
    internal let service: String

    private var defaultClassAndAttributes: [String: AnyObject] {
        return [
            String(kSecClass): String(kSecClassGenericPassword),
            String(kSecAttrAccessible): String(kSecAttrAccessibleAfterFirstUnlock),
            String(kSecAttrService): service
        ]
    }

    internal func dataForKey(key: String) -> NSData? {
        var attributes = defaultClassAndAttributes
        attributes[String(kSecAttrAccount)] = key
        attributes[String(kSecMatchLimit)] = kSecMatchLimitOne
        attributes[String(kSecReturnData)] = true

        var result: AnyObject?
        let status = withUnsafeMutablePointer(&result) { pointer in
            return SecItemCopyMatching(attributes, UnsafeMutablePointer(pointer))
        }

        guard status == errSecSuccess else {
            return nil
        }

        return result as? NSData
    }

    internal func valueForKey(key: String) -> String? {
        return dataForKey(key).flatMap { data in
            return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
        }
    }

    internal func setData(data: NSData, forKey key: String) {
        var attributes = defaultClassAndAttributes
        attributes[String(kSecAttrAccount)] = key
        attributes[String(kSecValueData)] = data
        SecItemAdd(attributes, nil)
    }

    internal func setValue(value: String, forKey key: String) {
        if let data = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            setData(data, forKey: key)
        }
    }

    internal func updateData(data: NSData, forKey key: String) {
        var query = defaultClassAndAttributes
        query[String(kSecAttrAccount)] = key

        var attributesToUpdate = query
        attributesToUpdate[String(kSecClass)] = nil
        attributesToUpdate[String(kSecValueData)] = data

        let status = SecItemUpdate(query, attributesToUpdate)
        if status == errSecItemNotFound || status == errSecNotAvailable {
            setData(data, forKey: key)
        }
    }

    internal func updateValue(value: String, forKey key: String) {
        if let data = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            updateData(data, forKey: key)
        }
    }

    internal func removeValueForKey(key: String) {
        var attributes = defaultClassAndAttributes
        attributes[String(kSecAttrAccount)] = key
        SecItemDelete(attributes)
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

    public func storeAccessToken(accessToken: OAuthAccessToken?) {
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
                return NSDate(timeIntervalSince1970: expiresAtInSeconds)
            }
        }

        if let accessToken = accessToken, tokenType = tokenType {
            return OAuthAccessToken(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken)
        }

        return nil
    }
}
