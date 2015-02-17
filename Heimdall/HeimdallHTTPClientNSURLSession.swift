import Foundation

/// An HTTP client that uses NSURLSession.
@objc
public class HeimdallHTTPClientNSURLSession: HeimdallHTTPClient {
    let urlSession: NSURLSession
    
    /// Initializes a new client.
    ///
    /// :param: urlSession The NSURLSession to use.
    ///     Default: `NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())`.
    ///
    /// :returns: A new client using the given `NSURLSession`.
    public init(urlSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())) {
        self.urlSession = urlSession
    }
    
    /// Sends the given request.
    ///
    /// :param: request The request to be sent.
    /// :param: completion A callback to invoke when the request completed.
    public func sendRequest(request: NSURLRequest, completion: (data: NSData!, response: NSURLResponse!, error: NSError?) -> ()) {
        let task = urlSession.dataTaskWithRequest(request, completionHandler: completion)
        task.resume()
    }
}
