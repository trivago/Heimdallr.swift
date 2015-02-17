import Foundation

public protocol OAuthHTTPClient {
    
    func sendRequest(request: NSURLRequest, completionHandler: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?)
    
}
