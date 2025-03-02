@objc public class ScreenCaptureManager: NSObject {
    @objc public static let shared = ScreenCaptureManager()
    
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
}
