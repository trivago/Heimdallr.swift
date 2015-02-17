import Foundation

/// An HTTP client that can be used by Heimdall.
public protocol HeimdallHTTPClient {
    /// Sends the given request.
    /// 
    /// :param: request The request to be sent.
    /// :param: completion A callback to invoke when the request completed.
    func sendRequest(request: NSURLRequest, completion: (data: NSData!, response: NSURLResponse!, error: NSError?) -> ())
}
