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

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(getManagedConfig)

RCT_EXTERN_METHOD(setAppGroupId:(NSString)identifier)

RCT_EXTERN_METHOD(supportedEvents)
RCT_EXTERN_METHOD(startObserving)
RCT_EXTERN_METHOD(stopObserving)

@end
