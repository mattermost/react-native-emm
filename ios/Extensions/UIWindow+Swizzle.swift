extension UIWindow {
    private struct AssociatedKeys {
        static var isBeingSwizzled: UnsafeRawPointer = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))
    }

    private var isBeingSwizzled: Bool {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.isBeingSwizzled) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.isBeingSwizzled, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

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
        // Prevent infinite recursion
        guard !isBeingSwizzled else { return }
        isBeingSwizzled = true

        print("[RNN Overlay] Overlay visibility changed to: \(level.rawValue) - \(self)")
        
        if level == .normal && ScreenCaptureManager.shared.preventScreenCapture,
           let rootVC = self.rootViewController {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                ScreenCaptureManager.shared.logLayerHierarchy(rootVC)
                rootVC.applyScreenCaptureProtection()
            }
        }
        
        // Call the original method (now swizzled)
        swizzled_setWindowLevel(level)
        
        isBeingSwizzled = false
    }
}
