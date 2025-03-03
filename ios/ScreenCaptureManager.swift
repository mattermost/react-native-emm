@objc public class ScreenCaptureManager: NSObject {
    @objc public static let shared = ScreenCaptureManager()
    
    // MARK: Properties
    internal var blurView: UIImageView? = nil
    var isAuthenticating: Bool = false
    var blurOnAuthenticate: Bool = false

    var preventScreenCapture: Bool = false {
        didSet {
            // here we should traverse the viewControllers
            // and apply or remove the protection
            self.applyScreenCapturePolicy()
        }
    }
    
    // MARK: Swizzle for RNN
    public static func startTrackingScreens() {
        UIWindow.swizzleRNNOverlayPresentation
        UIViewController.swizzleViewControllerLifecycleMethods
        UINavigationController.swizzleNavigationTracking()
    }
    
    // MARK: Event listener
    private func listenForScreenCapture() {
        if self.preventScreenCapture {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applyBlurEffect),
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
            applyBlurEffect() // Prevent screen recording
        } else {
            removeBlurEffect()
        }
    }
    
    // MARK: Windows and ViewControllers
    func getKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
    
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

    func getAllKeyWindows() -> [UIWindow] {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
        } else {
            return UIApplication.shared.windows
        }
    }
    
    private func getAllRootViewControllers() -> [UIViewController] {
        return getAllKeyWindows().compactMap { $0.rootViewController }
    }
    
    private func getAllPresentedViewControllers(from viewController: UIViewController) -> [UIViewController] {
        var presentedVCs: [UIViewController] = []
        
        var currentVC: UIViewController? = viewController
        while let vc = currentVC {
            presentedVCs.append(vc)
            currentVC = vc.presentedViewController
        }
        
        return presentedVCs
    }
    
    // MARK: Screenshot protection functions
    private func applyPolicyToViewController(_ vc: UIViewController) {
        if self.preventScreenCapture {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                vc.applyScreenCaptureProtection()
            }
            return
        }
        
        vc.removeScreenCaptureProtection()
    }
    
    private func applyScreenCapturePolicy() {
        DispatchQueue.main.sync {
            for rootVC in self.getAllRootViewControllers() {
                let c = NSStringFromClass(type(of: rootVC))
                if c.contains("RNNStackController"), let r = rootVC as? UINavigationController {
                    for vc in r.viewControllers {
                        print(String(describing: type(of: vc)))
                        self.applyPolicyToViewController(vc)
                    }
                }
                if let modalVC = rootVC.presentedViewController {
                    let c = NSStringFromClass(type(of: modalVC))
                    print(String(describing: type(of: modalVC)))
                    if c.contains("RNNStackController"), let r = modalVC as? UINavigationController {
                        for vc in r.viewControllers {
                            print(String(describing: type(of: vc)))
                            self.applyPolicyToViewController(vc)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Blur effect functions
    func createBlurEffect(window: UIWindow, toImage image: inout UIImage, radius: CGFloat) {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: "inputImage")
        filter?.setValue(radius, forKey: "inputRadius")
        guard let blurredImage = filter?.outputImage else {
            image = UIImage()
            return
        }
        let croppedFrame = CGRect(
            x: window.frame.origin.x,
            y: window.frame.origin.y,
            width: window.frame.width * UIScreen.main.scale,
            height: window.frame.height * UIScreen.main.scale
        )
        let cover = blurredImage.cropped(to: croppedFrame)
        image = UIImage.init(ciImage: cover)
    }
    
    func screenShot(window: UIWindow) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, scale);
        window.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot ?? UIImage()
    }
    
    @objc public func applyBlurEffect(radius: CGFloat = 8) {
        if self.blurView == nil && (
                (self.preventScreenCapture && !self.isAuthenticating) ||
                (self.isAuthenticating && self.blurOnAuthenticate)
        ) {
            DispatchQueue.main.async {
                if let window = self.getKeyWindow() {
                    if self.blurView == nil {
                        self.blurView = UIImageView()
                    }
                    guard let blurView = self.blurView else { return }
                    var cover = self.screenShot(window: window)
                    blurView.frame = window.frame
                    blurView.contentMode = .scaleToFill
                    blurView.backgroundColor = UIColor.gray
                    window.addSubview(blurView)
                    self.createBlurEffect(window: window, toImage: &cover, radius: 8)
                    blurView.image = cover
                }
            }
        }
    }
    
    @objc public func removeBlurEffect(forced: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.blurView != nil && ((!UIScreen.main.isCaptured && !self.isAuthenticating) || forced) {
                self.blurView?.removeFromSuperview()
                self.blurView = nil
            }
        }
    }
    
    // MARK: Print View hierarchy tree for debugging purposes
    func logLayerHierarchy(_ view: UIView?, prefix: String = "") {
#if DEBUG
        guard let view = view else { return }
        let viewClassName: String = String(describing: type(of: view))
        print("\(prefix)└── View: \(viewClassName), Layer: \(view.layer.name ?? "nil"), NativeID: \(String(describing: view.nativeID))")

        if view is UITextField {
            print("\(prefix)    (FOUND TEXTFIELD)")
        }

        let subviewCount = view.subviews.count
        for (index, subview) in view.subviews.enumerated() {
            let isLast = index == subviewCount - 1
            let newPrefix = prefix + (isLast ? "    " : "│   ")
            logLayerHierarchy(subview, prefix: newPrefix)
        }
#endif
    }
    
    func logLayerHierarchy(_ vc: UIViewController?, prefix: String = "") {
        guard let vc = vc else { return }
        logLayerHierarchy(vc.view, prefix: prefix)
    }
}
