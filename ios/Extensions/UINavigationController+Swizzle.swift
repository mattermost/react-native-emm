extension UINavigationController {
    static func swizzleNavigationTracking() {
        guard self === UINavigationController.self else { return }

        swizzleMethod(#selector(setter: viewControllers), with: #selector(swizzled_setViewControllers(_:animated:)))
        swizzleMethod(#selector(pushViewController(_:animated:)), with: #selector(swizzled_pushViewController(_:animated:)))
    }
    
    static func revertNavigationSwizzling() {
        guard self === UINavigationController.self else { return }
        
        swizzleMethod(#selector(swizzled_setViewControllers(_:animated:)), with: #selector(setter: viewControllers))
        swizzleMethod(#selector(swizzled_pushViewController(_:animated:)), with: #selector(pushViewController(_:animated:)))
    }

    private static func swizzleMethod(_ originalSelector: Selector, with swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc private func swizzled_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.swizzled_setViewControllers(viewControllers, animated: animated)
        trackViewControllerChanges()
    }

    @objc private func swizzled_pushViewController(_ viewController: UIViewController, animated: Bool) {
        self.swizzled_pushViewController(viewController, animated: animated)
        observeLifecycle(of: viewController)
    }

    /// Track ViewControllers in the stack
    private func trackViewControllerChanges() {
        print("Navigation Stack Updated: \(viewControllers.map { type(of: $0) })")
        viewControllers.forEach { observeLifecycle(of: $0) }
    }

    /// Observe lifecycle events
    private func observeLifecycle(of viewController: UIViewController) {
        viewController.viewDidAppearHandler = {
            print("ViewController \(type(of: viewController)) did appear")
            if ScreenCaptureManager.shared.preventScreenCapture {
                viewController.applyScreenCaptureProtection()
            }
        }
    }
}
