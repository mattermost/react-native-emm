@objc public class ScreenCaptureManager: NSObject {
    @objc public static let shared = ScreenCaptureManager()
    
    // MARK: Properties
    private var blurEffectView: AnimatedBlurEffectView?
    var isAuthenticating: Bool = false
    var blurOnAuthenticate: Bool = false
    private var protectionTextField: UITextField?
    private var originalParent: CALayer?

    var preventScreenCapture: Bool = false {
        didSet {
            self.listenForScreenCapture()
            self.setScreenCapturePolicy()
        }
    }
    
    // MARK: Event listener
    private func listenForScreenCapture() {
        if self.preventScreenCapture {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCapturedDidChange(_:)),
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
            return
        }
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }
    
    func screenCaptureStatusChange() {
        if self.preventScreenCapture && UIScreen.main.isCaptured && !self.isAuthenticating {
            conditionalApplyBlurEffect() // Prevent screen recording
        } else {
            removeBlurEffect()
        }
    }
    
    // MARK: Windows and ViewControllers
    func getLastKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .last { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.last { $0.isKeyWindow }
        }
    }


    // MARK: Screenshot protection functions
    private func applyScreenCapturePolicy() {
        guard let keyWindow = self.getLastKeyWindow(),
        originalParent == nil,
        protectionTextField == nil else {
            return
        }
    
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.backgroundColor = UIColor.clear
        textField.frame = UIScreen.main.bounds
    
        originalParent = keyWindow.layer.superlayer
        
        keyWindow.layer.superlayer?.addSublayer(textField.layer)
        
        if let firstTextFieldSublayer = textField.layer.sublayers?.first {
            keyWindow.layer.removeFromSuperlayer()
            firstTextFieldSublayer.addSublayer(keyWindow.layer)
        }
        
        protectionTextField = textField
    }
    
    private func removeScreenCapturePolicy() {
        guard let textField = protectionTextField,
              let window = self.getLastKeyWindow(),
              let originalParentLayer = originalParent else {
            return
        }
        
        window.layer.removeFromSuperlayer()
        originalParentLayer.addSublayer(window.layer)
        textField.layer.removeFromSuperlayer()
        protectionTextField = nil
        originalParent = nil
    }
    
    private func setScreenCapturePolicy() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { [weak self] in
            guard let self = self else { return }
            if self.preventScreenCapture {
                self.applyScreenCapturePolicy()
                return
            }
        
            self.removeScreenCapturePolicy()
        })
    }
    
    // MARK: Blur effect functions
    @objc func handleWillResignActive(_ notification: Notification) {
        conditionalApplyBlurEffect()
    }

    @objc func handleDidBecomeActive(_ notification: Notification) {
        conditionalRemoveBlurEffect(forced: true)
    }

    @objc func handleCapturedDidChange(_ notification: Notification) {
        screenCaptureStatusChange()
    }

    @objc public func conditionalApplyBlurEffect(intensity: CGFloat = 0.5) {
        if self.blurEffectView == nil && (
            (self.preventScreenCapture && !self.isAuthenticating) ||
            (self.isAuthenticating && self.blurOnAuthenticate)
        ) {
            self.applyBlurEffect(intensity: intensity, animated: false)
        }
    }
    
    @objc public func conditionalRemoveBlurEffect(forced: Bool = false) {
        if ((!UIScreen.main.isCaptured && !self.isAuthenticating) || forced) {
            self.removeBlurEffect()
        }
    }
    
    @objc public func applyBlurEffect(intensity: CGFloat = 0.5, animated: Bool = true) {
        // Apply blur synchronously if on main thread to ensure it appears in app switcher snapshot
        if Thread.isMainThread {
            applyBlurEffectSync(intensity: intensity, animated: animated)
        } else {
            DispatchQueue.main.sync {
                self.applyBlurEffectSync(intensity: intensity, animated: animated)
            }
        }
    }
    
    private func applyBlurEffectSync(intensity: CGFloat, animated: Bool) {
        guard self.blurEffectView == nil,
              let keyWindow = self.getLastKeyWindow(),
              let rootView = keyWindow.subviews.first else { return }

        let blurEffectView = AnimatedBlurEffectView(style: .dark, intensity: intensity)
        blurEffectView.frame = rootView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.isUserInteractionEnabled = false

        rootView.addSubview(blurEffectView)
        self.blurEffectView = blurEffectView

        if animated {
            blurEffectView.alpha = 0
            blurEffectView.setupBlur()
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    blurEffectView.alpha = 1.0
                }
            )
        } else {
            // For app switcher snapshot, apply blur immediately
            blurEffectView.effect = UIBlurEffect(style: .dark)
            blurEffectView.alpha = 1.0
        }

    }
    
    @objc public func removeBlurEffect() {
        DispatchQueue.main.async {
            guard let blurEffectView = self.blurEffectView else {
                return
            }
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    blurEffectView.alpha = 0
                },
                completion: { _ in
                    blurEffectView.removeFromSuperview()
                    self.blurEffectView = nil
                }
            )
        }
    }
}
