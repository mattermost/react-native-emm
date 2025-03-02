extension UIViewController {
    private struct ProtectionKeys {
        static var protectedViewKey = UnsafeRawPointer(bitPattern: "protectedViewKey".hashValue)!
    }
    
    private func getViewPriority(_ view: UIView) -> Int {
        if let nativeID = view.nativeID {
            if nativeID == "BottomSheetComponent" { return 4 } // Highest priority
            if nativeID.contains("shielded") { return 3 } // Second priority
        }
        
        let className = NSStringFromClass(type(of: view))
        if className.contains("RNCSafeAreaView") || className.contains("RCTSafeAreaView") {
            return 2 // Third priority
        }
        if className.contains("RNCSafeAreaProvider") {
            return 1 // Lowest priority
        }
        
        return 0 // If nothing matches
    }
    
    func findProtectionTarget(in target: UIView) -> UIView? {
        var fallbackView: UIView?
        var safeAreaView: UIView?
        var shieldedView: UIView?
        var bottomSheetView: UIView?

        func traverse(_ view: UIView) -> Bool {
            let priority = getViewPriority(view)
            
            switch priority {
            case 4: // ✅ BottomSheetComponent found, stop immediately
                print("✅ Found \(NSStringFromClass(type(of: view))) (BottomSheetComponent), prioritizing it for protection")
                bottomSheetView = view
                return true
            case 3: // ✅ Shielded view, but keep searching for BottomSheetComponent
                if shieldedView == nil {
                    print("✅ Found \(NSStringFromClass(type(of: view))) (Shielded), using as second priority")
                    shieldedView = view
                }
            case 2: // ✅ SafeAreaView, but keep searching for higher priorities
                if safeAreaView == nil && shieldedView == nil {
                    print("✅ Found \(NSStringFromClass(type(of: view))) (SafeAreaView), using as third priority")
                    safeAreaView = view
                }
            case 1: // ✅ SafeAreaProvider, but lowest priority
                if fallbackView == nil && safeAreaView == nil && shieldedView == nil {
                    fallbackView = view.subviews.first
                }
            default:
                break
            }
            
            // **Optimized DFS Traversal**
            let prioritizedSubviews = view.subviews.sorted { a, b in
                getViewPriority(a) > getViewPriority(b) // Higher priority first
            }

            for subview in prioritizedSubviews {
                if traverse(subview) { return true } // Stop if `BottomSheetComponent` is found
            }

            return false
        }

        let _ = traverse(target)

        return bottomSheetView ?? shieldedView ?? safeAreaView ?? fallbackView
    }

    func applyScreenCaptureProtection() {
        if self.view.layer.name == "Protected Layer" {
            return // already protected
        }
        
        ScreenCaptureManager.shared.logLayerHierarchy(self)
        guard let targetView = findProtectionTarget(in: self.view) else {
            print("🛑 No valid view found to protect for \(self)")
            return
            
        }
        
        print("✅ Applying screen capture protection to: \(targetView.nativeID ?? "Unknown View")")
        var isModal = self.isModalInPresentation
        if let navigationController = self.navigationController,
           let rootViewController = navigationController.viewControllers.first,
           rootViewController.presentingViewController != nil {
            isModal = true
        }
        
        targetView.setScreenCaptureProtection(isModal)
        self.view.layer.name = "Protected Layer"
        
        // Store the protected view in the View Controller
        objc_setAssociatedObject(self, &ProtectionKeys.protectedViewKey, targetView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func removeScreenCaptureProtection() {
        guard let protectedView = objc_getAssociatedObject(self, &ProtectionKeys.protectedViewKey) as? UIView else {
            print("⚠️ No stored protected view found, skipping removal")
            return
        }

        print("✅ Removing screen capture protection from: \(protectedView)")
        protectedView.removeScreenCaptureProtection()
        objc_setAssociatedObject(self, &ProtectionKeys.protectedViewKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.view.layer.name = nil
        CATransaction.flush()
    }
}
