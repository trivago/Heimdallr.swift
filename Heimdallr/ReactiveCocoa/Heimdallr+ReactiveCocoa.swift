import Foundation
import ReactiveSwift
import ReactiveObjC
import ReactiveObjCBridge
import Result

extension Heimdallr {
    /// Requests an access token with the resource owner's password credentials.
    ///
    /// - parameter username: The resource owner's username.
    /// - parameter password: The resource owner's password.
    /// - returns: A `SignalProducer` that, when started, creates a signal that
    ///     completes when the request finishes successfully or sends an error
    ///     if the request finishes with an error.
    public func requestAccessToken(username: String, password: String) -> SignalProducer<Void, NSError> {
        return SignalProducer { observer, disposable in
            self.requestAccessToken(username: username, password: password) { result in
                switch result {
                case .success:
                    observer.send(value: ())
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
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
    public func requestAccessToken(grantType: String, parameters: [String: String]) -> SignalProducer<Void, NSError> {
        return SignalProducer { observer, disposable in
            self.requestAccessToken(grantType: grantType, parameters: parameters) { result in
                switch result {
                case .success:
                    observer.send(value: ())
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
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
    public func authenticateRequest(request: URLRequest) -> SignalProducer<URLRequest, NSError> {
        return SignalProducer { observer, disposable in
            self.authenticateRequest(request) { result in
                switch result {
                case .success(let value):
                    observer.send(value: value)
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
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
    @objc public func rac_requestAccessToken(username: String, password: String) -> RACSignal<RACUnit> {
        let producer: SignalProducer<RACUnit, NSError> = requestAccessToken(username: username, password: password)
            .map { _ in RACUnit.default() }
        return producer.toRACSignal()
    }

    /// Requests an access token with the given grant type.
    ///
    /// - parameter grantType: The name of the grant type
    /// - parameter parameters: The required parameters for the custom grant type
    /// - returns: A signal that sends a `RACUnit` and completes when the
    ///     request finishes successfully or sends an error if the request
    ///     finishes with an error.
    @objc public func rac_requestAccessToken(grantType: String, parameters: NSDictionary) -> RACSignal<RACUnit> {
        let producer: SignalProducer<RACUnit, NSError> = requestAccessToken(grantType: grantType, parameters: parameters as! [String: String])
            .map { _ in RACUnit.default() }
        return producer.toRACSignal()
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
    @objc public func rac_authenticateRequest(request: NSURLRequest) -> RACSignal<NSURLRequest> {
        let convertedRequest = request as URLRequest
        let authenticatedRequestSignalProducer = authenticateRequest(request: convertedRequest)
        let convertedAuthenticatedRequestSignalProducer = authenticatedRequestSignalProducer.map { (request) -> NSURLRequest in
            return request as NSURLRequest
        }
        let authenticatedRequestSignal = convertedAuthenticatedRequestSignalProducer.toRACSignal()
        return authenticatedRequestSignal
    }
}
