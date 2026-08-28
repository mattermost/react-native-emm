import LocalAuthentication
import UIKit

enum EmmAuthError: String {
    case authFailed = "E_AUTH_FAILED"
    case cancelled = "E_CANCELLED"
    case indeterminate = "E_INDETERMINATE"
}

extension EmmWrapper {
        static let foregroundWaitTimeout: TimeInterval = 5.0

        // userFallback only reaches here when the caller disabled the fallback; otherwise
        // it is escalated to passcode entry.
        static func classify(_ error: Error?) -> EmmAuthError {
            guard let error = error as NSError? else {
                return .indeterminate
            }

            switch error.code {
            case LAError.authenticationFailed.rawValue,
                 LAError.biometryLockout.rawValue:
                return .authFailed

            case LAError.userCancel.rawValue,
                 LAError.appCancel.rawValue,
                 LAError.systemCancel.rawValue,
                 LAError.userFallback.rawValue:
                return .cancelled

            // Unrecognised errors mean we learned nothing, so never claim the user failed.
            default:
                return .indeterminate
            }
        }

        // LocalAuthentication is unusable until the app is frontmost, and iOS reports the
        // `active` app state while still animating out of the app switcher. On timeout we
        // report failure rather than running the work, so callers reject instead of
        // fabricating a "not secured" verdict.
        func whenAppIsActive(_ work: @escaping (_ isActive: Bool) -> Void) {
            DispatchQueue.main.async {
                if UIApplication.shared.applicationState == .active {
                    work(true)
                    return
                }

                var observer: NSObjectProtocol?
                var settled = false

                let settle = { (isActive: Bool) in
                    guard !settled else { return }
                    settled = true
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    work(isActive)
                }

                observer = NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    settle(true)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + EmmWrapper.foregroundWaitTimeout) {
                    settle(false)
                }
            }
        }

        private func showBlockingView() {
            DispatchQueue.main.async {
                guard let window = ScreenCaptureManager.shared.getLastKeyWindow() else { return }
                let blockingView = UIView(frame: window.bounds)
                blockingView.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Optional: semi-transparent
                blockingView.tag = 999 // Unique tag to identify the view later
                window.addSubview(blockingView)
            }
        }
        
        private func removeBlockingView() {
            DispatchQueue.main.async {
                guard let window = ScreenCaptureManager.shared.getLastKeyWindow() else { return }
                if let blockingView = window.viewWithTag(999) {
                    blockingView.removeFromSuperview()
                }
            }
        }

        func authenticateWithPolicy(policy: LAPolicy, reason: String, fallback: Bool, supressEnterPassword: Bool, completionHandler: @escaping (Bool, Error?) -> Void) -> Void {
            let context = LAContext()
            if (supressEnterPassword) {
                context.localizedFallbackTitle = ""
            }

            let isBiometricPolicy = policy == LAPolicy.deviceOwnerAuthenticationWithBiometrics

            // Only valid from the biometric policy, so a failure on .deviceOwnerAuthentication
            // stays terminal instead of recursing.
            let escalateToPasscode = { () -> Bool in
                guard isBiometricPolicy && fallback else { return false }
                self.authenticateWithPolicy(policy: .deviceOwnerAuthentication, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: completionHandler)
                return true
            }

            var canEvaluateError: NSError?

            if (!context.canEvaluatePolicy(policy, error: &canEvaluateError)) {
                let code = canEvaluateError?.code

                if isBiometricPolicy &&
                    (code == LAError.biometryNotAvailable.rawValue ||
                     code == LAError.biometryNotEnrolled.rawValue ||
                     code == LAError.biometryLockout.rawValue) &&
                    escalateToPasscode() {
                    return
                }

                completionHandler(false, canEvaluateError)
                return
            }

            self.showBlockingView()

            context.evaluatePolicy(policy, localizedReason: reason, reply: {(success: Bool, error: Error?) in
                self.removeBlockingView()

                if let error = error {
                    let code = (error as NSError).code

                    // userFallback means the user asked for the passcode; authenticationFailed
                    // means biometrics are exhausted. Both warrant passcode entry rather than
                    // reporting failure.
                    if (code == LAError.userFallback.rawValue || code == LAError.authenticationFailed.rawValue),
                       escalateToPasscode() {
                        return
                    }

                    completionHandler(false, error)
                    return
                }

                completionHandler(success, nil)
            })
        }
    
    func errorMessageForFails(errorCode: Int) -> String {
        var message = ""
        
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            message = "Authentication was not successful, because user failed to provide valid credentials"
            
        case LAError.appCancel.rawValue:
            message = "Authentication was canceled by application"
            
        case LAError.invalidContext.rawValue:
            message = "LAContext passed to this call has been previously invalidated"
            
        case LAError.notInteractive.rawValue:
            message = "Authentication failed, because it would require showing UI which has been forbidden by using interactionNotAllowed property"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Authentication could not start, because passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was canceled by system"
            
        case LAError.userCancel.rawValue:
            message = "Authentication was canceled by user"
            
        case LAError.userFallback.rawValue:
            message = "Authentication was canceled, because the user tapped the fallback button"
            
        default:
            message = "Unknown Error"
        }
        
        return message
    }
}
