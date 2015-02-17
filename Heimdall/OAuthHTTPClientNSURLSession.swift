import Foundation

@objc
public class OAuthHTTPClientNSURLSession: OAuthHTTPClient {
    
    let urlSession: NSURLSession
    
    public init(urlSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())) {
        self.urlSession = urlSession
    }
    
    public func sendRequest(request: NSURLRequest, completionHandler: ((data: NSData!, response: NSURLResponse!, error: NSError?) -> Void)?) {
        let task = urlSession.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }
    
}
