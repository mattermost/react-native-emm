import LocalAuthentication

extension EmmWrapper {
        func authenticateWithPolicy(policy: LAPolicy, reason: String, fallback: Bool, supressEnterPassword: Bool, completionHandler: @escaping (Bool, Error?) -> Void) -> Void {
            let context = LAContext()
            if (supressEnterPassword) {
                context.localizedFallbackTitle = ""
            }
    
            var error: NSError?
    
            if (!context.canEvaluatePolicy(policy, error: &error)) {
                if (policy == LAPolicy.deviceOwnerAuthenticationWithBiometrics) {
                    if #available(iOS 11.0, *) {
                        switch error!.code {
                        case LAError.Code.biometryNotAvailable.rawValue,
                             LAError.Code.biometryNotEnrolled.rawValue,
                             LAError.Code.biometryLockout.rawValue:
                            if (fallback) {
                                self.authenticateWithPolicy(policy: .deviceOwnerAuthentication, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: completionHandler)
                                return
                            }
                        default:
                            completionHandler(false, error);
                        }
                    } else if (fallback) {
                        self.authenticateWithPolicy(policy: .deviceOwnerAuthentication, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: completionHandler)
                        return
                    } else {
                        completionHandler(false, error);
                    }
                }
            }
    
            context.evaluatePolicy(policy, localizedReason: reason, reply: {(success: Bool, error: Error?) in
                if (error != nil) {
                    completionHandler(false, error)
                    return
                }
    
                completionHandler(true, nil)
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
