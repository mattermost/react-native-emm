extension UIWindow {
    private static var originalSetWindowLevel: IMP?

    static let swizzleRNNOverlayPresentation: Void = {
        guard let targetClass = NSClassFromString("RNNOverlayWindow") as? UIWindow.Type else {
            print("⚠️ RNNOverlayWindow not found")
            return
        }
        
        let originalSelector = #selector(setter: UIWindow.windowLevel)
        let swizzledSelector = #selector(swizzled_setWindowLevel(_:))
        
        swizzleMethod(for: targetClass, original: originalSelector, swizzled: swizzledSelector)
    }()
    
    private static func swizzleMethod(for targetClass: UIWindow.Type, original: Selector, swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(targetClass, original),
              let swizzledMethod = class_getInstanceMethod(UIWindow.self, swizzled) else {
            return
        }
        
        originalSetWindowLevel = method_getImplementation(originalMethod)
        
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
    
    @objc private func swizzled_setWindowLevel(_ level: UIWindow.Level) {
        let windowClassName = String(describing: type(of: self))
        print("Window Class: \(windowClassName)")
        
        // Ensure the method only runs for RNNOverlayWindow
        if let windowClass = NSClassFromString("RNNOverlayWindow"), type(of: self) == windowClass {
            print("[RNN Overlay] Overlay visibility changed to: \(level.rawValue) - \(self)")

            if level == .normal && ScreenCaptureManager.shared.preventScreenCapture,
               let rootVC = self.rootViewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    ScreenCaptureManager.shared.logLayerHierarchy(rootVC)
                    rootVC.applyScreenCaptureProtection()
                }
            }
        }

        // Always call the original method at the end
        callOriginalSetWindowLevel(level)
    }

    
    private func callOriginalSetWindowLevel(_ level: UIWindow.Level) {
        guard let originalIMP = UIWindow.originalSetWindowLevel else { return }

        typealias Function = @convention(c) (AnyObject, Selector, UIWindow.Level) -> Void
        let function = unsafeBitCast(originalIMP, to: Function.self)

        function(self, #selector(setter: UIWindow.windowLevel), level)
    }
}
