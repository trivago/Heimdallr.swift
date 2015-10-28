import Foundation
import Heimdallr
import ReactiveCocoa

extension Heimdallr {
    /// Requests an access token with the resource owner's password credentials.
    ///
    /// - parameter username: The resource owner's username.
    /// - parameter password: The resource owner's password.
    /// - returns: A `SignalProducer` that, when started, creates a signal that
    ///     completes when the request finishes successfully or sends an error
    ///     if the request finishes with an error.
    public func requestAccessToken(username username: String, password: String) -> SignalProducer<Void, NSError> {
        return SignalProducer { observer, disposable in
            self.requestAccessToken(username: username, password: password) { result in
                switch result {
                case .Success:
                    observer.sendNext()
                    observer.sendCompleted()
                case .Failure(let error):
                    observer.sendFailed(error)
                }
            }
        }
    }

    /// Requests an access token with the given grant type.
    ///
    /// - parameter grantType: The grant type.
    /// - parameter parameters: The required parameters for the grant type.
    /// - returns: A `SignalProducer` that, when started, creates a signal that
    ///     completes when the request finishes successfully or sends an error
    ///     if the request finishes with an error.
    public func requestAccessToken(grantType grantType: String, parameters: [String: String]) -> SignalProducer<Void, NSError> {
        return SignalProducer { observer, disposable in
            self.requestAccessToken(grantType: grantType, parameters: parameters) { result in
                switch result {
                case .Success:
                    observer.sendNext()
                    observer.sendCompleted()
                case .Failure(let error):
                    observer.sendFailed(error)
                }
            }
        }
    }

    /// Alters the given request by adding authentication, if possible.
    ///
    /// In case of an expired access token and the presence of a refresh token,
    /// automatically tries to refresh the access token.
    ///
    /// - Note: If the access token must be refreshed, network I/O is
    ///     performed.
    ///
    /// - parameter request: An unauthenticated NSURLRequest.
    /// - returns: A `SignalProducer` that, when started, creates a signal that
    ///     sends the authenticated request on success or an error if the
    ///     request could not be authenticated.
    public func authenticateRequest(request: NSURLRequest) -> SignalProducer<NSURLRequest, NSError> {
        return SignalProducer { observer, disposable in
            self.authenticateRequest(request) { result in
                switch result {
                case .Success(let value):
                    observer.sendNext(value)
                    observer.sendCompleted()
                case .Failure(let error):
                    observer.sendFailed(error)
                }
            }
        }
    }

    // MARK: Objective-C compatibility

    /// Requests an access token with the resource owner's password credentials.
    ///
    /// - parameter username: The resource owner's username.
    /// - parameter password: The resource owner's password.
    /// - returns: A signal that sends a `RACUnit` and completes when the
    ///     request finishes successfully or sends an error if the request
    ///     finishes with an error.
    @objc public func RH_requestAccessToken(username username: String, password: String) -> RACSignal {
        let producer: SignalProducer<RACUnit, NSError> = requestAccessToken(username: username, password: password)
            .map { _ in RACUnit.defaultUnit() }
        return toRACSignal(producer)
    }

    /// Requests an access token with the given grant type.
    ///
    /// - parameter grantType: The name of the grant type
    /// - parameter parameters: The required parameters for the custom grant type
    /// - returns: A signal that sends a `RACUnit` and completes when the
    ///     request finishes successfully or sends an error if the request
    ///     finishes with an error.
    @objc public func RH_requestAccessToken(grantType grantType: String, parameters: NSDictionary) -> RACSignal {
        let producer: SignalProducer<RACUnit, NSError> = requestAccessToken(grantType: grantType, parameters: parameters as! [String: String])
            .map { _ in RACUnit.defaultUnit() }
        return toRACSignal(producer)
    }

    /// Alters the given request by adding authentication, if possible.
    ///
    /// In case of an expired access token and the presence of a refresh token,
    /// automatically tries to refresh the access token.
    ///
    /// - Note: If the access token must be refreshed, network I/O is
    ///     performed.
    ///
    /// - parameter request: An unauthenticated NSURLRequest.
    /// - returns: A signal that sends the authenticated request on success or
    ///     an error if the request could not be authenticated.
    @objc public func RH_authenticateRequest(request: NSURLRequest) -> RACSignal {
        return toRACSignal(authenticateRequest(request))
    }
}
