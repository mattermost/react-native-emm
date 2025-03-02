extension UIView {
    private struct Constants {
        static var secureTextFieldTag: Int { 37125 }
        static var secureTextFieldKey = UnsafeRawPointer(bitPattern: "secureTextFieldKey".hashValue)!
        static var originalSuperlayerKey = UnsafeRawPointer(bitPattern: "originalSuperlayerKey".hashValue)!
    }
    
    func setScreenCaptureProtection(_ isModal: Bool) {
        guard let superview = superview else {
            return
        }

        if let _ = objc_getAssociatedObject(self, &Constants.secureTextFieldKey) as? UITextField {
            return // Already protected
        }
        
        // Step 1: Create the secureTextField to obscure screenshots
        layer.name = "originalLayer"
        let secureTextField = UITextField()
        secureTextField.backgroundColor = .clear
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        secureTextField.tag = Constants.secureTextFieldTag
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.layer.name = "secureTextFieldLayer"
        
        // Step 2: Store a reference of the original layout
        if let originalSuperlayer = layer.superlayer {
            objc_setAssociatedObject(self, &Constants.originalSuperlayerKey, originalSuperlayer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Step 3: Insert the secureTextField in the view hierarchy
        // and store its reference
        let isBottomSheet = self.nativeID != nil && self.nativeID == "BottomSheetComponent"
        let isPermalink = self.nativeID != nil && self.nativeID.lowercased().contains("permalink")
        if (isModal && !isBottomSheet && !isPermalink) {
            superview.insertSubview(secureTextField, at: 0)
        } else {
            insertSubview(secureTextField, at: 0)
        }
        objc_setAssociatedObject(self, &Constants.secureTextFieldKey, secureTextField, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Step 4: Modify the layout
        layer.superlayer?.addSublayer(secureTextField.layer)
        secureTextField.layer.sublayers?.last?.addSublayer(layer)
    }
    
    public func removeScreenCaptureProtection() {
        guard let secureTextField = objc_getAssociatedObject(self, &Constants.secureTextFieldKey) as? UITextField else {
            return // Not found, assume already removed
        }
        
        // Step 1: Restore the original superlayer before removing secureTextField
        if let originalSuperlayer = objc_getAssociatedObject(self, &Constants.originalSuperlayerKey) as? CALayer {
            if layer.superlayer !== originalSuperlayer {
                // Temporarily remove the layer
                let tempLayer = CALayer()
                originalSuperlayer.addSublayer(tempLayer)

                layer.removeFromSuperlayer()
                secureTextField.removeFromSuperview()
                originalSuperlayer.addSublayer(layer)

                // Remove temp layer after forcing an update
                tempLayer.removeFromSuperlayer()
            }
        }
        
        // Step 3: Remove stored references
        objc_setAssociatedObject(self, &Constants.secureTextFieldKey, nil, .OBJC_ASSOCIATION_ASSIGN)
        objc_setAssociatedObject(self, &Constants.originalSuperlayerKey, nil, .OBJC_ASSOCIATION_ASSIGN)
    }
}
