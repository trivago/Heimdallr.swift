//
//  OAuthManager.swift
//  oauth-swift
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import LlamaKit

public let OAuthManagerErrorDomain = "OAuthManagerErrorDomain"
public let OAuthManagerErrorNoData = 1
public let OAuthManagerErrorInvalidData = 2
public let OAuthManagerErrorNotAuthorized = 3

private enum OAuthGrantType: String {
    case Password = "password"
    case RefreshToken = "refresh_token"
}

@objc
public class OAuthAccessToken {
    public let token: String
    public let type: String
    public let expiresAt: NSDate?
    public let refreshToken: String?

    private var authorizationString: String {
        return "\(type) \(token)"
    }

    public init(token: String, type: String, expiresAt: NSDate?, refreshToken: String?) {
        self.token = token
        self.type = type
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    private class func fromData(data: NSData) -> Result<OAuthAccessToken, NSError> {
        var error: NSError?

        if let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? [String: AnyObject] {
            return fromDictionary(dictionary)
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not create access token from data", comment: ""),
                NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected valid JSON, got: %@.", comment: ""), NSString(data: data, encoding: NSUTF8StringEncoding) ?? "nil")
            ]

            let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorInvalidData, userInfo: userInfo)
            return failure(error)
        }
    }

    private class func fromDictionary(dictionary: [String: AnyObject]) -> Result<OAuthAccessToken, NSError> {
        let token: AnyObject? = dictionary["access_token"]
        let type: AnyObject? = dictionary["token_type"]
        let expiresAt = map(dictionary["expires_in"] as? NSTimeInterval) { NSDate(timeIntervalSinceNow: $0) }
        let refreshToken = dictionary["refresh_token"] as? String

        if let token = token as String? {
            if let type = type as String? {
                return success(self.init(token: token, type: type, expiresAt: expiresAt, refreshToken: refreshToken))
            } else {
                let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("Could not create access token from dictionary", comment: ""),
                    NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected valid token type, got: %@.", comment: ""), type?.description ?? "nil")
                ]

                let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorInvalidData, userInfo: userInfo)
                return failure(error)
            }
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not create access token from dictionary", comment: ""),
                NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected valid access token, got: %@.", comment: ""), token?.description ?? "nil")
            ]

            let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorInvalidData, userInfo: userInfo)
            return failure(error)
        }
    }
}

public protocol OAuthAccessTokenStorage {
    func storeAccessToken(accessToken: OAuthAccessToken) -> Void
    func retrieveAccessToken() -> OAuthAccessToken?
}

@objc
public class OAuthManager {
    private let tokenURL: NSURL
    private let clientID: String

    private var accessToken: OAuthAccessToken?

    public var hasAccessToken: Bool {
        return accessToken != nil
    }

    public init(tokenURL: NSURL, clientID: String) {
        self.tokenURL = tokenURL
        self.clientID = clientID
    }

    public func authorize(username: String, password: String, completion: Result<Void, NSError> -> ()) {
        let queryParameters = [
            "grant_type": OAuthGrantType.Password.rawValue,
            "client_id": clientID,
            "username": username,
            "password": password
        ]

        let url = NSURLByAppendingQueryParameters(tokenURL, queryParameters)
        let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let urlRequest = NSURLRequest(URL: url!)

        let task = urlSession.dataTaskWithRequest(urlRequest) { data, response, error in
            if let error = error {
                completion(failure(error))
            } else if let data = data {
                switch OAuthAccessToken.fromData(data) {
                case .Success(let value):
                    self.accessToken = value.unbox
                    completion(success())
                case .Failure(let error):
                    completion(failure(error.unbox))
                }
            } else {
                let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize", comment: ""),
                    NSLocalizedFailureReasonErrorKey: NSLocalizedString("Expected data, got: nil.", comment: "")
                ]

                let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorNoData, userInfo: userInfo)
                completion(failure(error))
            }
        }

        task.resume()
    }

    private func refreshAccessToken(accessToken: OAuthAccessToken, completion: Result<OAuthAccessToken, NSError> -> ()) {
        if let refreshToken = accessToken.refreshToken {
            let queryParameters = [
                "grant_type": OAuthGrantType.RefreshToken.rawValue,
                "refresh_token": refreshToken
            ]

            let url = NSURLByAppendingQueryParameters(tokenURL, queryParameters)
            let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let urlRequest = NSURLRequest(URL: url!)

            let task = urlSession.dataTaskWithRequest(urlRequest) { data, response, error in
                if let error = error {
                    completion(failure(error))
                } else if let data = data {
                    switch OAuthAccessToken.fromData(data) {
                    case .Success(let value):
                        self.accessToken = value.unbox
                        completion(success(value.unbox))
                    case .Failure(let error):
                        completion(failure(error.unbox))
                    }
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not refresh access token", comment: ""),
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString("Expected data, got: nil.", comment: "")
                    ]

                    let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorNoData, userInfo: userInfo)
                    completion(failure(error))
                }
            }

            task.resume()
        } else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not refresh access token", comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString("No refresh token available.", comment: "")
            ]

            let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorNotAuthorized, userInfo: userInfo)
            completion(failure(error))
        }
    }

    private func requestByAddingAuthorizationHeaderToRequest(request: NSURLRequest, accessToken: OAuthAccessToken) -> NSURLRequest {
        var mutableRequest = request.mutableCopy() as NSMutableURLRequest
        mutableRequest.setValue(accessToken.authorizationString, forHTTPHeaderField: "Authorization")
        return mutableRequest
    }

    public func requestByAddingAuthorizationToRequest(request: NSURLRequest, completion: Result<NSURLRequest, NSError> -> ()) {
        if let accessToken = accessToken {
            if accessToken.expiresAt != nil && accessToken.expiresAt < NSDate() {
                refreshAccessToken(accessToken) { result in
                    completion(result.map { accessToken in
                        return self.requestByAddingAuthorizationHeaderToRequest(request, accessToken: accessToken)
                    })
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

            let error = NSError(domain: OAuthManagerErrorDomain, code: OAuthManagerErrorNotAuthorized, userInfo: userInfo)
            completion(failure(error))
        }
    }
}
