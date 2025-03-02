@objc public class ScreenCaptureManager: NSObject {
    @objc public static let shared = ScreenCaptureManager()
    
    // MARK: Properties
    internal var blurView: UIImageView? = nil
    var isAuthenticating: Bool = false
    var blurOnAuthenticate: Bool = false

    var preventScreenCapture: Bool = false
    
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
                    self.blurView = UIImageView()
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
        DispatchQueue.main.async {
            if self.blurView != nil && (!self.isAuthenticating || forced),
               let window = self.getKeyWindow() {
                self.blurView?.removeFromSuperview()
                self.blurView = nil
            }
        }
    }
}
