import Foundation
import UIKit
import SafariServices
import Result

/// The request could not be authorized (e.g., no refresh token available).
public let HeimdallrErrorAuthorizationCanceled = 101

private enum CompletionType {
    case authorizationCode(AuthorizationCodeCompletion)
    case accessToken(AccessTokenCompletion)
    case none
}

extension CompletionType {

    func oAuthAccessToken(fromURL url: URL) -> OAuthAccessToken? {

        guard let paramters = url.fragmentParameters,
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

protocol OAuthAuthorizationCodeHandlerType {

    func requestAuthorizationCode(url: URL, completion: @escaping AuthorizationCodeCompletion)
    func requestAccessToken(url: URL, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void)
    func authCallback(url: URL?, error: Error?)
}

@available(iOS 9.0, *)
class OAuthAuthorizationCodeHandler: NSObject, OAuthAuthorizationCodeHandlerType {

    private var authenticationSession: Any?
    private var safariViewController: SFSafariViewController?
    private var completion: CompletionType = .none

    func requestAuthorizationCode(url: URL, completion: @escaping AuthorizationCodeCompletion) {
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
        completion = .none
    }

    // MARK: Open WebView methods

    @available(iOS 11.0, *)
    private func requestWithSafariServices(url: URL) {
        let session = SFAuthenticationSession(url: url, callbackURLScheme: nil) { [weak self] url, error in
            self?.authCallback(url: url, error: error)
        }
        authenticationSession = session
        DispatchQueue.main.async {
        session.start()
        }
    }

    private func requestLegacy(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .overFullScreen
        safariViewController.delegate = self
        self.safariViewController = safariViewController

        let parent = UIApplication.shared.keyWindow?.topMostViewController
        DispatchQueue.main.async {
            parent?.present(safariViewController, animated: true, completion: nil)
        }
    }
}

extension OAuthAuthorizationCodeHandler: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_: SFSafariViewController) {
        authCallback(url: nil, error: NSError(domain: HeimdallrErrorDomain, code: HeimdallrErrorAuthorizationCanceled, userInfo: nil))
    }
}
