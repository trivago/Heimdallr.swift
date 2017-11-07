import Foundation

@available(iOS 9.0, *)
@available(OSXApplicationExtension 10.10, *)
extension URL {

    public var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return nil
        }

        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }

        return parameters
    }

    var fragmentParameters: [String: String]? {
        guard let fragment = fragment else { return nil }

        var parameters: [String: String] = [:]
        for fragmentValues in fragment.split(separator: "&") {
            let fragmentValue = fragmentValues.split(separator: "=")

            guard let key = fragmentValue.first,
                let value = fragmentValue.last else { return nil }

            parameters[String(key)] = String(value)
        }

        return parameters
    }
}
