import UIKit

extension UIWindow {

    var topMostViewController: UIViewController? {
        var current = rootViewController

        while true {
            if let presented = current?.presentedViewController {
                current = presented
            } else if let navigationController = current as? UINavigationController {
                current = navigationController.visibleViewController
            } else if let tabBarController = current as? UITabBarController {
                current = tabBarController.selectedViewController
            } else {
                break
            }
        }

        return current
    }
}
