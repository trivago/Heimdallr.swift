import Foundation
import Result
import Argo

@objc
public class OAuthAccessTokenDefaultParser: NSObject, OAuthAccessTokenParser {
    public func parse(data: NSData) -> Result<OAuthAccessToken, NSError> {
        
        let decoded = OAuthAccessToken.decode(data)
        
        switch decoded {
        case .Success(let token):
            return .Success(token)
        case .Failure:
            let error = NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorInvalidData, userInfo: nil)
            return .Failure(error)
        }
    }
}

