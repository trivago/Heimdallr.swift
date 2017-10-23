import Foundation
import UIKit
import SafariServices
import Result

@available(iOS 9.0, *)
class AuthorizationCodeHandler {

    private var authenticationSession: Any?
    private var safariViewController: SFSafariViewController?
    private var completion: ((Result<String, NSError>) -> Void)?

    func requestAuthorizationCode(url: URL, completion: @escaping (Result<String, NSError>) -> Void) {
        if #available(iOS 11.0, *) {
            requestAuthorizationCodeWithSafariServices(url: url, completion: completion)
        } else {
            requestAuthorizationCodeLegacy(url: url, completion: completion)
        }
    }

    func appOpen(authorizationCodeURL url: URL) {
        safariViewController?.dismiss(animated: true, completion: nil)
        safariViewController = nil
        handle(authorizationCodeURL: url, error: nil)
    }

    private func handle(authorizationCodeURL url: URL?, error: Error?) {
        guard let completion = completion else { return }

        defer {
            self.completion = nil
            self.authenticationSession = nil
        }

        guard let code = url?.queryParameters?["code"] else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            return
        }

        switch (code, error) {
        case let (code, .none):
            completion(.success(code))
        case let (_, error):
            completion(.failure(error! as NSError))
        }
    }

    @available(iOS 11.0, *)
    private func requestAuthorizationCodeWithSafariServices(url: URL, completion: @escaping (Result<String, NSError>) -> Void) {
        self.completion = completion

        let session = SFAuthenticationSession(url: url, callbackURLScheme: nil) { [weak self] url, error in
            self?.handle(authorizationCodeURL: url, error: error)
        }
        authenticationSession = session
        session.start()
    }

    private func requestAuthorizationCodeLegacy(url: URL, completion: @escaping (Result<String, NSError>) -> Void) {
        self.completion = completion

        let safariViewController = SFSafariViewController(url: url)
        //        safariViewController.delegate = self
        let parent = UIApplication.shared.keyWindow?.rootViewController
        parent?.present(safariViewController, animated: true, completion: nil)
        self.safariViewController = safariViewController
    }
}
