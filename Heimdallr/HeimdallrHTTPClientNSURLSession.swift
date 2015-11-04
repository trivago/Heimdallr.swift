import Foundation

/// An HTTP client that uses NSURLSession.
@objc
public class HeimdallrHTTPClientNSURLSession: NSObject, HeimdallrHTTPClient {
    let urlSession: NSURLSession

    /// Initializes a new client.
    ///
    /// - parameter urlSession: The NSURLSession to use.
    ///     Default: `NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())`.
    ///
    /// - returns: A new client using the given `NSURLSession`.
    public init(urlSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())) {
        self.urlSession = urlSession
    }

    /// Sends the given request.
    ///
    /// - parameter request: The request to be sent.
    /// - parameter completion: A callback to invoke when the request completed.
    public func sendRequest(request: NSURLRequest, completion: (data: NSData?, response: NSURLResponse?, error: NSError?) -> ()) {
        let task = urlSession.dataTaskWithRequest(request, completionHandler: completion)
        task.resume()
    }
}
