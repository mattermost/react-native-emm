extension EmmWrapper {
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
    
    func screenShot(window: UIWindow) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, scale);
        window.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot ?? UIImage()
    }
    
   @objc func handleAppStateActive() {
       if (self.blurScreen) {
           DispatchQueue.main.async {
               let keyWindow = UIApplication.shared.windows.last { $0.isKeyWindow }
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
               let keyWindow = UIApplication.shared.windows.last { $0.isKeyWindow }
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
}
