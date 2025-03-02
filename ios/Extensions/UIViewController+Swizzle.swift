extension UIViewController {
    private struct AssociatedKeys {
        static var viewDidAppearHandler: UnsafeRawPointer = UnsafeRawPointer(bitPattern: "viewDidAppearHandler".hashValue)!
    }
    
    var viewDidAppearHandler: (() -> Void)? {
        get { return objc_getAssociatedObject(self, AssociatedKeys.viewDidAppearHandler) as? (() -> Void) }
        set { objc_setAssociatedObject(self, AssociatedKeys.viewDidAppearHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    static let swizzleViewControllerLifecycleMethods: Void = {
        guard let targetClass = NSClassFromString("RNNComponentViewController") as? UIViewController.Type else {
            print("⚠️ RNNComponentViewController not found")
            return
        }
        
        let methodPairs: [(Selector, Selector)] = [
            (#selector(viewDidAppear(_:)), #selector(swizzled_viewDidAppear(_:))),
        ]
        
        for (originalSelector, swizzledSelector) in methodPairs {
            swizzleMethod(for: targetClass, original: originalSelector, swizzled: swizzledSelector)
        }
    }()
    
    private static func swizzleMethod(for targetClass: UIViewController.Type, original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(targetClass, original),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled) else {
            return
        }
        
        let didAddMethod = class_addMethod(
            targetClass,
            swizzled,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        if didAddMethod {
            guard let newSwizzledMethod = class_getInstanceMethod(targetClass, swizzled) else { return }
            method_exchangeImplementations(originalMethod, newSwizzledMethod)
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    @objc private func swizzled_viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { // Check if needed again
            self.viewDidAppearHandler?()
            self.swizzled_viewDidAppear(animated)
        })
    }
}
