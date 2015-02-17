import AeroGearHttpStub
import Foundation

extension StubResponse {
    convenience init(filename: String, bundle: NSBundle, statusCode: Int = 200, headers: [String: String] = [ "Content-Type": "application/json" ]) {
        self.init(filename: filename, location: .Bundle(bundle), statusCode: statusCode, headers: headers)
    }
}
