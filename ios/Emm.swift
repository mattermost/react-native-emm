
import Foundation
import LocalAuthentication
import React

@objc public class EmmWrapper: NSObject {
    @objc public weak var delegate: EmmDelegate? = nil
    
    // The Managed app configuration dictionary pushed down from an EMM provider are stored in this key.
    internal var hasListeners = false
    internal var configurationKey = "com.apple.configuration.managed"
    internal var appGroupId:String?
    internal var sharedUserDefaults:UserDefaults?
    
    @objc public func captureEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(managedConfigChaged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(ScreenCaptureManager.shared, selector: #selector(ScreenCaptureManager.applyBlurEffect(radius:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(ScreenCaptureManager.shared, selector: #selector(ScreenCaptureManager.removeBlurEffect), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc public func invalidate() {
        ScreenCaptureManager.shared.removeBlurEffect(forced: true)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc public func authenticate(options:Dictionary<String, Any>, resolve:(@escaping RCTPromiseResolveBlock), reject:(@escaping RCTPromiseRejectBlock)) {
        DispatchQueue.global(qos: .userInitiated).async {
            let reason = options["reason"] as! String
            let fallback = options["fallback"] as! Bool
            let supressEnterPassword = options["supressEnterPassword"] as! Bool
            ScreenCaptureManager.shared.isAuthenticating = true
            ScreenCaptureManager.shared.blurOnAuthenticate = options["blurOnAuthenticate"] as? Bool ?? false
            ScreenCaptureManager.shared.applyBlurEffect()
            self.authenticateWithPolicy(policy: .deviceOwnerAuthenticationWithBiometrics, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: {(success: Bool, error: Error?) in
                if success && ScreenCaptureManager.shared.blurOnAuthenticate {
                    ScreenCaptureManager.shared.isAuthenticating = false
                    ScreenCaptureManager.shared.removeBlurEffect(forced: true)
                } else {
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                        ScreenCaptureManager.shared.isAuthenticating = false
                    }
                }
                
                if (error != nil) {
                    let errorReason = self.errorMessageForFails(errorCode: (error! as NSError).code)
                    reject("error", errorReason, error)
                    return
                }
                
                resolve(true)
            })
        }
    }
    
    @objc public func deviceSecureWith(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        var result = [
            "face": false,
            "fingerprint": false,
            "passcode": false
        ]
        
        let context = LAContext()
        let hasAuthenticationBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        let hasAuthentication = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        if #available(iOS 11.0, *) {
            if (hasAuthenticationBiometrics) {
                switch context.biometryType {
                case .faceID:
                    result["face"] = true
                case .touchID:
                    result["fingerprint"] = true
                default:
                    print("No Biometrics authentication found")
                }
            } else if (hasAuthentication) {
                result["passcode"] = true
            }
        } else if (hasAuthenticationBiometrics) {
            result["fingerprint"] = true
        } else if (hasAuthentication) {
            result["passcode"] = true
        }
        
        resolve(result)
    }
    
    @objc public func setBlurScreen(enabled: Bool) {
        ScreenCaptureManager.shared.preventScreenCapture = enabled
    }
    
    @objc public func exitApp() -> Void {
        exit(0)
    }
    
    @objc public func getManagedConfig() -> Dictionary<String, Any> {
        let config = managedConfig()
        if ((config) != nil) {
            return config!
        } else {
            return Dictionary<String, Any>()
        }
    }
    
    @objc public func setAppGroupId(identifier: String) -> Void {
        self.appGroupId = identifier
        self.sharedUserDefaults = UserDefaults.init(suiteName: identifier)
    }
}
