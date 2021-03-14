import Foundation

/// An HTTP client that uses URLSession.
@objc
public class HeimdallrHTTPClientURLSession: NSObject, HeimdallrHTTPClient {

    let urlSession: URLSession

    /// Initializes a new client.
    ///
    /// - parameter urlSession: The NSURLSession to use.
    ///     Default: `URLSession(configuration: URLSessionConfiguration.defaultSessionConfiguration())`.
    ///
    /// - returns: A new client using the given `URLSession`.
    public init(urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)) {
        self.urlSession = urlSession
    }

    /// Sends the given request.
    ///
    /// - parameter request: The request to be sent.
    /// - parameter completion: A callback to invoke when the request completed.
    public func sendRequest(_ request: URLRequest, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let task = urlSession.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
}
