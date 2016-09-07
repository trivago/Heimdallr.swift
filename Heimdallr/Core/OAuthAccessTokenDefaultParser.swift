import Foundation
import Result

@objc
public class OAuthAccessTokenDefaultParser: NSObject, OAuthAccessTokenParser {
    public func parse(_ data: Data) -> Result<OAuthAccessToken, NSError> {
        
        if let token = OAuthAccessToken.decode(data: data) {
            return .success(token)
        } else {
            let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorInvalidData, userInfo: nil)
            return .failure(error)
        }
    }
}

