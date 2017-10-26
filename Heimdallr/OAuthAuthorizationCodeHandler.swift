import Foundation
import UIKit
import SafariServices
import Result

private typealias AuthorizationCodeCompletion = ((Result<String, NSError>) -> Void)
private typealias AccessTokenCompletion = ((Result<OAuthAccessToken, NSError>) -> Void)

private enum CompletionType {
    case authorizationCode(AuthorizationCodeCompletion)
    case accessToken(AccessTokenCompletion)
    case none
}

extension CompletionType {

    func oAuthAccessToken(fromURL url: URL) -> OAuthAccessToken? {

        func fragmentParamters(fromURL url: URL) -> [String: String]? {
            guard let fragment = url.fragment else { return nil }

            var paramters: [String: String] = [:]
            for fragmentValues in fragment.split(separator: "&") {
                let fragmentValue = fragmentValues.split(separator: "=")

                guard let key = fragmentValue.first,
                    let value = fragmentValue.last else { return nil }

                paramters[String(key)] = String(value)
            }

            return paramters
        }

        guard let paramters = fragmentParamters(fromURL: url),
            let token = paramters["access_token"] else { return nil }

        return OAuthAccessToken(accessToken: token)
    }

    func handle(url: URL) {
        switch self {
        case let .authorizationCode(completion):
            guard let authorizationCode = url.queryParameters?["code"] else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                return
            }
            completion(.success(authorizationCode))
        case let .accessToken(completion):
            guard let oAuthAccessToken = oAuthAccessToken(fromURL: url) else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                return
            }
            completion(.success(oAuthAccessToken))
        case .none:
            assertionFailure("Undefined state")
            break
        }
    }

    func fail(error: NSError) {
        switch self {
        case let .authorizationCode(completion):
            completion(.failure(error))
        case let .accessToken(completion):
            completion(.failure(error))
        case .none:
            assertionFailure("Undefined state")
            break
        }
    }
}

@available(iOS 9.0, *)
class OAuthAuthorizationCodeHandler {

    private var authenticationSession: Any?
    private var safariViewController: SFSafariViewController?
    private var completion: CompletionType = .none

    func requestAuthorizationCode(url: URL, completion: @escaping (Result<String, NSError>) -> Void) {
        self.completion = .authorizationCode(completion)

        if #available(iOS 11.0, *) {
            requestWithSafariServices(url: url)
        } else {
            requestLegacy(url: url)
        }
    }

    func requestAccessToken(url: URL, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        self.completion = .accessToken(completion)

        if #available(iOS 11.0, *) {
            requestWithSafariServices(url: url)
        } else {
            requestLegacy(url: url)
        }
    }

    func authCallback(url: URL?, error: Error?) {
        safariViewController?.dismiss(animated: true, completion: nil)
        safariViewController = nil

        handle(url: url, error: error)
    }

    // MARK: - Helper

    private func handle(url: URL?, error: Error?) {

        if let error = error {
            completion.fail(error: error as NSError)
            return
        }

        guard let url = url else {
            completion.fail(error: NSError(domain: "", code: 0, userInfo: nil))
            return
        }

        completion.handle(url: url)
    }

    // MARK: Open WebView methods

    @available(iOS 11.0, *)
    private func requestWithSafariServices(url: URL) {
        let session = SFAuthenticationSession(url: url, callbackURLScheme: nil) { [weak self] url, error in
            self?.authCallback(url: url, error: error)
        }
        authenticationSession = session
        session.start()
    }

    private func requestLegacy(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        let parent = UIApplication.shared.keyWindow?.topMostViewController
        parent?.present(safariViewController, animated: true, completion: nil)

        self.safariViewController = safariViewController
    }
}
