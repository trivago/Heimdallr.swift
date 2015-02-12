//
//  Heimdall.swift
//  Heimdall
//
//  Created by Felix Jendrusch on 2/10/15.
//  Copyright (c) 2015 B264 GmbH. All rights reserved.
//

import LlamaKit

public let HeimdallErrorDomain = "HeimdallErrorDomain"
public let HeimdallErrorInvalidData = 1
public let HeimdallErrorNotAuthorized = 2

private enum AuthorizationGrant {
    case ResourceOwnerPasswordCredentials(String, String)
    case Refresh(String)

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
        authorize(.ResourceOwnerPasswordCredentials(username, password)) { result in
            completion(result.map { _ in return })
        }
    }

    private func authorize(grant: AuthorizationGrant, completion: Result<AccessToken, NSError> -> ()) {
        let request = NSMutableURLRequest(URL: tokenURL)

        var parameters = grant.parameters
        if let credentials = credentials {
            if let secret = credentials.secret {
                request.setHTTPAuthorization(.BasicAuthentication(username: credentials.id, password: secret))
            } else {
                parameters["client_id"] = credentials.id
            }
        }

        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setHTTPBody(parameters: parameters)

        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                completion(failure(error))
            } else if (response as NSHTTPURLResponse).statusCode == 200 {
                if let accessToken = AccessToken.decode(data) {
                    self.accessToken = accessToken
                    completion(success(accessToken))
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected access token, got: %@.", comment: ""), NSString(data: data, encoding: NSUTF8StringEncoding) ?? "nil")
                    ]

                    let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
                    completion(failure(error))
                }
            } else {
                if let error = OAuthError.decode(data) {
                    completion(failure(error.nsError))
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not authorize grant", comment: ""),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("Expected error, got: %@.", comment: ""), NSString(data: data, encoding: NSUTF8StringEncoding) ?? "nil")
                    ]

                    let error = NSError(domain: HeimdallErrorDomain, code: HeimdallErrorInvalidData, userInfo: userInfo)
                    completion(failure(error))
                }
            }
        }
        
        task.resume()
    }

    private func requestByAddingAuthorizationHeaderToRequest(request: NSURLRequest, accessToken: AccessToken) -> NSURLRequest {
        var mutableRequest = request.mutableCopy() as NSMutableURLRequest
        mutableRequest.setHTTPAuthorization(.AccessTokenAuthentication(accessToken))
        return mutableRequest
    }

    public func requestByAddingAuthorizationToRequest(request: NSURLRequest, completion: Result<NSURLRequest, NSError> -> ()) {
        if let accessToken = accessToken {
            if accessToken.expiresAt != nil && accessToken.expiresAt < NSDate() {
                if let refreshToken = accessToken.refreshToken {
                    authorize(.Refresh(refreshToken)) { result in
                        completion(result.map { accessToken in
                            return self.requestByAddingAuthorizationHeaderToRequest(request, accessToken: accessToken)
                        })
                    }
                } else {
                    let userInfo = [
                        NSLocalizedDescriptionKey: NSLocalizedString("Could not add authorization to request", comment: ""),
                        NSLocalizedFailureReasonErrorKey: NSLocalizedString("Access token expired, no refresh token available.", comment: "")
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
