#import "Emm.h"

#ifdef RCT_NEW_ARCH_ENABLED

#import "EmmSpec.h"
#endif

#if __has_include("react_native_emm-Swift.h")
#import <react_native_emm-Swift.h>
#else
#import <react_native_emm/react_native_emm-Swift.h>
#endif

#include <optional>

@interface Emm () <EmmDelegate>
@end

@implementation Emm {
    EmmWrapper *wrapper;
    bool hasListeners;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        wrapper = [EmmWrapper new];
        wrapper.delegate = self;
        [wrapper captureEvents];
    }
    return self;
}

-(void)startObserving {
    hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
}

RCT_EXPORT_MODULE(Emm)

RCT_REMAP_METHOD(authenticate, options:(NSDictionary *)options
                  withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject) {
    [wrapper authenticateWithOptions:options resolve:resolve reject:reject];
}

RCT_REMAP_METHOD(deviceSecureWith, withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject) {
    [self deviceSecureWith:resolve reject:reject];
}

RCT_REMAP_BLOCKING_SYNCHRONOUS_METHOD(getManagedConfig, NSDictionary *, getManaged) {
    return [self getManagedConfig];
}

RCT_REMAP_METHOD(exitApp, exit) {
    [self exitApp];
}

RCT_REMAP_METHOD(setAppGroupId, identifier:(NSString *)identifier) {
    [self setAppGroupId:identifier];
}

RCT_REMAP_METHOD(setBlurScreen, enabled:(BOOL)enabled) {
    [self setBlurScreen:enabled];
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeEmmSpecJSI>(params);
}
#endif

#pragma protocol

- (void)sendEventWithName:(NSString * _Nonnull)name result:(NSDictionary<NSString *,id> * _Nullable)result {
    if (hasListeners) {
        [self sendEventWithName:name body:result];
    }
}

- (NSArray<NSString *> *)supportedEvents {
  return [EmmWrapper supportedEvents];
}

#pragma overrides
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

#pragma utils
- (NSNumber *)processBooleanValue:(std::optional<bool>)optionalBoolValue {
    // Use the boolean value
    if (optionalBoolValue.has_value()) {
        return [NSNumber numberWithBool:optionalBoolValue.value()];
    }

    return 0;
}

#pragma react methods implementation

#ifdef RCT_NEW_ARCH_ENABLED

- (void)authenticate:(JS::NativeEmm::AuthenticateConfig &)options resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    id sharedKeySet = [NSDictionary sharedKeySetForKeys:@[@"reason", @"fallback", @"description", @"supressEnterPassword"]]; // returns NSSharedKeySet
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithSharedKeySet:sharedKeySet];
    dict[@"reason"] = options.reason();
    dict[@"fallback"] = [self processBooleanValue:options.fallback()];
    dict[@"description"] = options.description();
    dict[@"supressEnterPassword"] = [self processBooleanValue:options.supressEnterPassword()];
    [wrapper authenticateWithOptions:dict resolve:resolve reject:reject];
}

#endif


- (NSDictionary *)getManagedConfig {
    return [wrapper getManagedConfig];
}


- (void)deviceSecureWith:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [wrapper deviceSecureWithResolve:resolve reject:reject];
}


- (void)exitApp {
    [wrapper exitApp];
}


- (void)openSecuritySettings { 
    NSLog(@"Method not implemented on iOS");
}


- (void)setAppGroupId:(NSString *)identifier { 
    [wrapper setAppGroupIdWithIdentifier:identifier];
}


- (void)setBlurScreen:(BOOL)enabled { 
    [wrapper setBlurScreenWithEnabled:enabled];
}

@end
