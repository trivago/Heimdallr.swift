import Foundation
import Result

/// An access token parser that can be used by Heimdallr.
public protocol OAuthAccessTokenParser {
    func parse(data: NSData) -> Result<OAuthAccessToken, NSError>
}
