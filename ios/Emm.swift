import LocalAuthentication

@objc(ReactNativeEmm)
class ReactNativeEmm: RCTEventEmitter {
    // The Managed app configuration dictionary pushed down from an EMM provider are stored in this key.
    var configurationKey = "com.apple.configuration.managed"
    var blurViewTag = 8065
    var appGroupId:String?
    var hasListeners = false
    var blurScreen = false
    var sharedUserDefaults:UserDefaults?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(managedConfigChaged(notification:)), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func applyBlurEffect(window: UIWindow, toImage image: inout UIImage) {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: "inputImage")
        filter?.setValue(8, forKey: "inputRadius")
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

    func autheticateWithPolicy(policy: LAPolicy, reason: String, fallback: Bool, supressEnterPassword: Bool, completionHandler: @escaping (Bool, Error?) -> Void) -> Void {
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
                            self.autheticateWithPolicy(policy: .deviceOwnerAuthentication, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: completionHandler)
                            return
                        }
                    default:
                        completionHandler(false, error);
                    }
                } else if (fallback) {
                    self.autheticateWithPolicy(policy: .deviceOwnerAuthentication, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: completionHandler)
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
    
    func managedConfig() -> Dictionary<String, Any>? {
        let defaults = UserDefaults.standard
        return defaults.dictionary(forKey: self.configurationKey)
    }

    func screenShot(window: UIWindow) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, scale);
        window.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot ?? UIImage()
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
      return true
    }
    
    @objc
    override func supportedEvents() -> [String]! {
      return ["managedConfigChanged"]
    }
    
    @objc
    override func startObserving() {
        hasListeners = true
    }
    
    @objc
    override func stopObserving() {
        hasListeners = false
    }
    
    @objc func handleAppStateActive() {
        if (self.blurScreen) {
            DispatchQueue.main.async {
                let keyWindow = UIApplication.shared.keyWindow
                guard let kw = keyWindow else {
                    return
                }
                kw.viewWithTag(self.blurViewTag)?.removeFromSuperview()
            }
        }
    }
    
    @objc func handleAppStateResignActive() {
        if (self.blurScreen) {
            DispatchQueue.main.async {
                let keyWindow = UIApplication.shared.keyWindow
                guard let kw = keyWindow else {
                    return
                }
                let imageView = UIImageView()
                var cover = self.screenShot(window: kw)
                imageView.frame = kw.frame
                imageView.tag = self.blurViewTag
                imageView.contentMode = .scaleToFill
                imageView.backgroundColor = UIColor.gray
                kw.addSubview(imageView)
                self.applyBlurEffect(window: kw, toImage: &cover)
                imageView.image = cover
            }
        }
    }

    @objc func managedConfigChaged(notification: Notification) -> Void {
        let config = managedConfig()
        var result = Dictionary<String, Any>()
        
        if (config != nil) {
            result = config!
        }

        if (self.appGroupId != nil) {
            self.sharedUserDefaults?.set(result, forKey: self.configurationKey)
        }
        
        if (hasListeners) {
            sendEvent(withName: "managedConfigChanged", body: result)
        }
    }

    @objc(authenticate:withResolver:withRejecter:)
    func authenticate(options: Dictionary<String, Any>, resolve:(@escaping RCTPromiseResolveBlock), reject:(@escaping RCTPromiseRejectBlock)) {
        DispatchQueue.global(qos: .userInitiated).async {
            let reason = options["reason"] as! String
            let fallback = options["fallback"] as! Bool
            let supressEnterPassword = options["supressEnterPassword"] as! Bool
            self.autheticateWithPolicy(policy: .deviceOwnerAuthenticationWithBiometrics, reason: reason, fallback: fallback, supressEnterPassword: supressEnterPassword, completionHandler: {(success: Bool, error: Error?) in
                if (error != nil) {
                    let errorReason = self.errorMessageForFails(errorCode: (error! as NSError).code)
                    reject("error", errorReason, error)
                    return
                }
                
                resolve(true)
            })
        }
    }
    
    @objc(deviceSecureWith:withRejecter:)
    func deviceSecureWith(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        
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

    @objc(enableBlurScreen:)
    func enableBlurScreen(enabled: Bool) {
        self.blurScreen = enabled
    }

    @objc(exitApp)
    func exitApp() -> Void {
        exit(0)
    }
    
    @objc(getManagedConfig:withRejecter:)
    func getManagedConfig(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        let config = managedConfig()
        if ((config) != nil) {
            resolve(config)
        } else {
            resolve({})
        }
    }
    
    @objc(setAppGroupId:)
    func setAppGroupId(identifier: String) -> Void {
        self.appGroupId = identifier
        self.sharedUserDefaults = UserDefaults.init(suiteName: identifier)
    }
}
