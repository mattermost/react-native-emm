#import <Foundation/Foundation.h>
#import <React/RCTEventEmitter.h>

#if RCT_NEW_ARCH_ENABLED

#import <EmmSpec/EmmSpec.h>
@interface Emm: RCTEventEmitter <NativeEmmSpec>

#else

#import <React/RCTBridgeModule.h>
@interface Emm : RCTEventEmitter <RCTBridgeModule>

#endif

@end
