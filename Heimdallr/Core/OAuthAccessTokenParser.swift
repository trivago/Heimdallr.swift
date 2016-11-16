import Foundation
import Result

/// An access token parser that can be used by Heimdallr.
@objc public protocol OAuthAccessTokenParser {
    func parse(data: Data) throws -> OAuthAccessToken
}
