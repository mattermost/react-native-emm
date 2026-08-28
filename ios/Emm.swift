
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
        NotificationCenter.default.addObserver(ScreenCaptureManager.shared, selector: #selector(ScreenCaptureManager.handleWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(ScreenCaptureManager.shared, selector: #selector(ScreenCaptureManager.handleDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc public func invalidate() {
        ScreenCaptureManager.shared.conditionalRemoveBlurEffect(forced: true)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc public func authenticate(options:Dictionary<String, Any>, resolve:(@escaping RCTPromiseResolveBlock), reject:(@escaping RCTPromiseRejectBlock)) {
        self.whenAppIsActive { isActive in
            guard isActive else {
                reject(EmmAuthError.indeterminate.rawValue, "App did not reach the foreground", nil)
                return
            }

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
                        ScreenCaptureManager.shared.conditionalRemoveBlurEffect(forced: true)
                    } else {
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                            ScreenCaptureManager.shared.isAuthenticating = false
                        }
                    }

                    if (error != nil) {
                        let classified = EmmWrapper.classify(error)
                        reject(classified.rawValue, self.errorMessageForFails(errorCode: (error! as NSError).code), error)
                        return
                    }

                    resolve(success)
                })
            }
        }
    }
    
    @objc public func deviceSecureWith(resolve:(@escaping RCTPromiseResolveBlock),reject:(@escaping RCTPromiseRejectBlock)) -> Void {
        self.whenAppIsActive { isActive in
            guard isActive else {
                reject(EmmAuthError.indeterminate.rawValue, "App did not reach the foreground", nil)
                return
            }

            var result = [
                "face": false,
                "fingerprint": false,
                "passcode": false
            ]

            let context = LAContext()
            let hasAuthenticationBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

            // The device-credential probe is the authority on whether the device is secured;
            // the biometric probe legitimately fails on a passcode-only device.
            var authenticationError: NSError?
            let hasAuthentication = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authenticationError)

            guard hasAuthentication else {
                // Only passcodeNotSet is a real "not secured" verdict. Anything else means we
                // could not evaluate, and must not be reported as an unsecured device.
                if authenticationError?.code == LAError.passcodeNotSet.rawValue {
                    resolve(result)
                } else {
                    reject(EmmAuthError.indeterminate.rawValue, "Could not determine device security", authenticationError)
                }
                return
            }

            if (hasAuthenticationBiometrics) {
                switch context.biometryType {
                case .faceID:
                    result["face"] = true
                case .touchID:
                    result["fingerprint"] = true
                default:
                    result["passcode"] = true
                }
            } else {
                result["passcode"] = true
            }

            resolve(result)
        }
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
