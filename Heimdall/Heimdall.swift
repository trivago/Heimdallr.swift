//
//  Heimdall.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import LlamaKit

public let HeimdallErrorDomain = "OAuthManagerErrorDomain"
public let HeimdallErrorNoData = 1
public let HeimdallErrorInvalidData = 2
public let HeimdallErrorNotAuthorized = 3

private enum AuthorizationGrant {
    case ResourceOwnerPasswordCredentials(username: String, password: String)
    case Refresh(refreshToken: String)

    private var parameters: [String: String] {
        switch self {
        case .ResourceOwnerPasswordCredentials(let username, let password):
            return [ "grant_type": "password", "username": username, "password": password ]
        case .Refresh(let refreshToken):
            return [ "grant_type": "refresh_token", "refresh_token": refreshToken ]
        }
    }
}

@objc
public class AccessToken {
    public let accessToken: String
    public let tokenType: String
    public let expiresAt: NSDate?
    public let refreshToken: String?

    private var authorizationString: String {
        return "\(tokenType) \(accessToken)"
    }

    public init(accessToken: String, tokenType: String, expiresAt: NSDate? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    private class func fromData(data: NSData) -> Result<AccessToken, NSError> {
        var error: NSError?

        if let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? [String: AnyObject] {
            return fromDictionary(dictionary)
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not create access token from data", comment: ""),
                NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected valid JSON, got: %@.", comment: ""), NSString(data: data, encoding: NSUTF8StringEncoding) ?? "nil")
            ]

            let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
            return failure(error)
        }
    }

    private class func fromDictionary(dictionary: [String: AnyObject]) -> Result<AccessToken, NSError> {
        let accessToken: AnyObject? = dictionary["access_token"]
        let tokenType: AnyObject? = dictionary["token_type"]
        let expiresAt = map(dictionary["expires_in"] as? NSTimeInterval) { NSDate(timeIntervalSinceNow: $0) }
        let refreshToken = dictionary["refresh_token"] as? String

        if let accessToken = accessToken as String? {
            if let tokenType = tokenType as String? {
                return success(self.init(accessToken: accessToken, tokenType: tokenType, expiresAt: expiresAt, refreshToken: refreshToken))
            } else {
                let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("Could not create access token from dictionary", comment: ""),
                    NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected valid token type, got: %@.", comment: ""), tokenType?.description ?? "nil")
                ]

                let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
                return failure(error)
            }
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not create access token from dictionary", comment: ""),
                NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected valid access token, got: %@.", comment: ""), accessToken?.description ?? "nil")
            ]

            let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
            return failure(error)
        }
    }
}

@objc
public class Credentials {
    public let id: String
    public let secret: String?

    private var parameters: [String: String] {
        var parameters = [ "client_id": id ]

        if let secret = secret {
            parameters["client_secret"] = secret
        }

        return parameters
    }

    public init(id: String, secret: String? = nil) {
        self.id = id
        self.secret = secret
    }
}

@objc
public class Heimdall {
    private let tokenURL: NSURL
    private let credentials: Credentials?

    private let accessTokenStorage: AccessTokenStorage
    private var accessToken: AccessToken? {
        get {
            return accessTokenStorage.retrieveAccessToken()
        }
        set {
            accessTokenStorage.storeAccessToken(newValue)
        }
    }

    public var hasAccessToken: Bool {
        return accessToken != nil
    }
    
    public init(tokenURL: NSURL, credentials: Credentials? = nil, accessTokenStorage: AccessTokenStorage = AccessTokenKeychainStorage()) {
        self.tokenURL = tokenURL
        self.credentials = credentials

        self.accessTokenStorage = accessTokenStorage
    }

    public func authorize(username: String, password: String, completion: Result<Void, NSError> -> ()) {
        authorize(.ResourceOwnerPasswordCredentials(username: username, password: password)) { result in
            completion(result.map { _ in return })
        }
    }

    private func authorize(grant: AuthorizationGrant, completion: Result<AccessToken, NSError> -> ()) {
        let request = NSMutableURLRequest(URL: tokenURL)

        var parameters = grant.parameters
        if let credentials = credentials {
            if let secret = credentials.secret {
                let encodedCredentials = "\(credentials.id):\(secret)".dataUsingEncoding(NSASCIIStringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))
                request.setValue("Basic \(encodedCredentials!)", forHTTPHeaderField: "Authorization")
            } else {
                parameters["client_id"] = credentials.id
            }
        }

        var parts = [String]()
        for (name, value) in parameters {
            let encodedName = name.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            let encodedValue = value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            parts.append("\(encodedName!)=\(encodedValue!)")
        }

        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "&".join(parts).dataUsingEncoding(NSUTF8StringEncoding)

        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                completion(failure(error))
            } else if let data = data {
                switch AccessToken.fromData(data) {
                case .Success(let value):
                    self.accessToken = value.unbox
                    completion(success(value.unbox))
                case .Failure(let error):
                    completion(failure(error.unbox))
                }
            } else {
                let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                    NSLocalizedFailureReasonErrorKey: NSLocalizedString("Expected data, got: nil.", comment: "")
                ]

                let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorNoData, userInfo: userInfo)
                completion(failure(error))
            }
        }
        
        task.resume()
    }

    private func requestByAddingAuthorizationHeaderToRequest(request: NSURLRequest, accessToken: AccessToken) -> NSURLRequest {
        var mutableRequest = request.mutableCopy() as NSMutableURLRequest
        mutableRequest.setValue(accessToken.authorizationString, forHTTPHeaderField: "Authorization")
        return mutableRequest
    }

    public func requestByAddingAuthorizationToRequest(request: NSURLRequest, completion: Result<NSURLRequest, NSError> -> ()) {
        if let accessToken = accessToken {
            if accessToken.expiresAt != nil && accessToken.expiresAt < NSDate() {
                if let refreshToken = accessToken.refreshToken {
                    authorize(.Refresh(refreshToken: refreshToken)) { result in
                        completion(result.map { accessToken in
                            return self.requestByAddingAuthorizationHeaderToRequest(request, accessToken: accessToken)
                        })
                    }
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not refresh access token", comment: ""),
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString("No refresh token available.", comment: "")
                    ]

                    let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorNotAuthorized, userInfo: userInfo)
                    completion(failure(error))
                }
            } else {
                let request = requestByAddingAuthorizationHeaderToRequest(request, accessToken: accessToken)
                completion(success(request))
            }
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not add authorization to request", comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("Not authorized.", comment: "")
            ]

            let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorNotAuthorized, userInfo: userInfo)
            completion(failure(error))
        }
    }
}
