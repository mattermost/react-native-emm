extension EmmWrapper {
    func managedConfig() -> Dictionary<String, Any>? {
        let defaults = UserDefaults.standard
        return defaults.dictionary(forKey: self.configurationKey)
    }

    @objc func managedConfigChaged(notification: Notification) -> Void {
        let config = managedConfig()
        if (config == nil) {
            if (self.sharedUserDefaults?.dictionary(forKey: self.configurationKey) != nil) {
                self.sharedUserDefaults?.removeObject(forKey: self.configurationKey)
            }
            return
        }
        
        let initial = self.sharedUserDefaults?.dictionary(forKey: self.configurationKey) ?? Dictionary<String, Any>()
        let equal = NSDictionary(dictionary: initial).isEqual(to: config!)
        
        
        if (self.appGroupId != nil && !equal) {
            self.sharedUserDefaults?.set(config, forKey: self.configurationKey)
        }
        
        if (hasListeners) {
            delegate?.sendEvent(name: "managedConfigChanged", result: config)
        }
    }
}