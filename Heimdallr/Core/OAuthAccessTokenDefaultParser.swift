import Foundation
import Result

@objc
public class OAuthAccessTokenDefaultParser: NSObject, OAuthAccessTokenParser {
    public func parse(data: NSData) -> Result<OAuthAccessToken, NSError> {
        
        if let token = OAuthAccessToken.decode(data: data) {
            return .Success(token)
        } else {
            let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorInvalidData, userInfo: nil)
            return .Failure(error)
        }
    }
}

