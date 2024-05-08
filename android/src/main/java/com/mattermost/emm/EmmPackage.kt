package com.mattermost.emm


import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class EmmPackage : TurboReactPackage() {
  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? =
    if (name == EmmModuleImpl.NAME) {
      EmmModule(reactContext)
    } else {
      null
    }

  override fun getReactModuleInfoProvider() = ReactModuleInfoProvider {
    mapOf(
      EmmModuleImpl.NAME to ReactModuleInfo(
        EmmModuleImpl.NAME,
        EmmModuleImpl.NAME,
        false,
        false,
        true,
        false,
        BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
      )
    )
  }
}
