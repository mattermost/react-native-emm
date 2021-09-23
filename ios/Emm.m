#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_REMAP_MODULE(Emm, ReactNativeEmm, RCTEventEmitter)
RCT_EXTERN_METHOD(authenticate:(NSDictionary *)options
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(deviceSecureWith:
                  (RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(enableBlurScreen:(BOOL)enabled)

RCT_EXTERN_METHOD(exitApp)

RCT_EXTERN_METHOD(getManagedConfig:
                 (RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setAppGroupId:(NSString)identifier)

RCT_EXTERN_METHOD(supportedEvents)
RCT_EXTERN_METHOD(startObserving)
RCT_EXTERN_METHOD(stopObserving)

RCT_EXPORT_METHOD(addListener : (NSString *)eventName) {
  // Keep: Required for RN built in Event Emitter Calls.
}

RCT_EXPORT_METHOD(removeListeners : (NSInteger)count) {
  // Keep: Required for RN built in Event Emitter Calls.
}

@end
