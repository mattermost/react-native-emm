import Foundation

@objc public protocol EmmDelegate {
    func sendEvent(name: String, result: Dictionary<String, Any>?)
}

extension EmmWrapper {
    enum Event: String, CaseIterable {
        case managedConfigChanged
    }
    
    @objc
    public static var supportedEvents: [String] {
        return Event.allCases.map(\.rawValue)
    }
}
