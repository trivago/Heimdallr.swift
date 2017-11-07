@testable import Heimdallr
import Nimble
import Quick
import Result

class OAuthAuthorizationCodeHandlerMock: OAuthAuthorizationCodeHandlerType {
    
    var requestAuthorizationCodeURL: URL?
    func requestAuthorizationCode(url: URL, completion: @escaping AuthorizationCodeCompletion) {
        requestAuthorizationCodeURL = url
    }
    
    var requestAccessTokenURL: URL?
    func requestAccessToken(url: URL, completion: @escaping (Result<OAuthAccessToken, NSError>) -> Void) {
        requestAccessTokenURL = url
    }
    
    func authCallback(url: URL?, error: Error?) {
    }
}

class iOSHeimdallrSpec: QuickSpec {
    
    override func spec() {
        
        describe("iOSHeimdallr") {
            
            var sut: Heimdallr!
            var authorizationCodeHandlerMock: OAuthAuthorizationCodeHandlerMock!
            
            
            beforeEach {
                sut = Heimdallr(tokenURL: URL(string: "http://trivago.com")!)
                authorizationCodeHandlerMock = OAuthAuthorizationCodeHandlerMock()
                sut.authorizationCodeHandler = authorizationCodeHandlerMock
            }
            
            describe("requestAccessToken(implicitAuthorizationURL:redirectURI:scope:parameters:completion:)") {
                
                beforeEach {
                    sut.requestAccessToken(authorizationCodeURL: URL(string: "http://trivago.com")!,
                                           redirectURI: "http://trivago.com",
                                           scope: "scope",
                                           parameters: ["test":"abc123"],
                                           completion: { result in
                                            print(result)
                    })
                }
                
                it("builds the right request URL") {
                    expect(authorizationCodeHandlerMock.requestAuthorizationCodeURL) == URL(string: "http://trivago.com?response_type=code&scope=scope&redirect_uri=http://trivago.com&test=abc123")!
                }
            }
            
            describe("implicitAuthorizationURL(authorizationCodeURL:redirectURI:scope:completion:)") {
                
                beforeEach {
                    sut.requestAccessToken(implicitAuthorizationURL: URL(string: "http://trivago.com")!,
                                           redirectURI: "http://trivago.com",
                                           scope: "scope",
                                           completion: { result in
                                            print(result)
                    })
                }
                
                it("builds the right request URL") {
                    expect(authorizationCodeHandlerMock.requestAccessTokenURL) == URL(string: "http://trivago.com?scope=scope&redirect_uri=http://trivago.com&response_type=token")!
                }
            }
            
            describe("requestAuthorizationCode(authorizationCodeURL:redirectURI:scope:parameters:completion:)") {
                
                beforeEach {
                    sut.requestAuthorizationCode(authorizationCodeURL: URL(string: "http://trivago.com")!,
                                           redirectURI: "http://trivago.com",
                                           scope: "scope",
                                           parameters: ["test":"abc123"],
                                           completion: { result in
                                            print(result)
                    })
                }
                
                it("builds the right request URL") {
                    expect(authorizationCodeHandlerMock.requestAuthorizationCodeURL) == URL(string: "http://trivago.com?response_type=code&scope=scope&redirect_uri=http://trivago.com&test=abc123")!
                }
            }
        }
    }
}
