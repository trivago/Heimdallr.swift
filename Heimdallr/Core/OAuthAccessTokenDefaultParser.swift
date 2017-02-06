import Foundation
import Result

@objc public class OAuthAccessTokenDefaultParser: NSObject, OAuthAccessTokenParser {
    public func parse(data: Data) throws -> OAuthAccessToken {

        guard let token = OAuthAccessToken.decode(data: data) else {
            throw NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorInvalidData, userInfo: nil)
        }

        return token
    }
}
