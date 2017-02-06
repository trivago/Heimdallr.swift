import Foundation

/// An HTTP client that uses NSURLSession.
@objc
public class HeimdallrHTTPClientNSURLSession: NSObject, HeimdallrHTTPClient {

    let urlSession: URLSession

    /// Initializes a new client.
    ///
    /// - parameter urlSession: The NSURLSession to use.
    ///     Default: `NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())`.
    ///
    /// - returns: A new client using the given `NSURLSession`.
    public init(urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)) {
        self.urlSession = urlSession
    }

    /// Sends the given request.
    ///
    /// - parameter request: The request to be sent.
    /// - parameter completion: A callback to invoke when the request completed.
    public func sendRequest(_ request: URLRequest, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> ()) {
        let task = urlSession.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
}
