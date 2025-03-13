package com.mattermost.emm

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.facebook.react.bridge.BaseActivityEventListener
import com.facebook.react.bridge.LifecycleEventListener
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap

class EmmModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), LifecycleEventListener {
  private var implementation: EmmModuleImpl = EmmModuleImpl(reactContext)
  private var authPromise: Promise? = null

  private val restrictionsReceiver: BroadcastReceiver = object : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
      implementation.handleReceiveBroadcast(intent)
    }
  }

  private val mActivityEventListener = object : BaseActivityEventListener() {
    override fun onActivityResult(activity: Activity?, requestCode: Int, resultCode: Int, data: Intent?) {
      implementation.handleActivityResult(authPromise, activity, requestCode, resultCode, data)
      authPromise = null
    }
  }

  init {
    reactContext.addLifecycleEventListener(this)
    reactContext.addActivityEventListener(mActivityEventListener)
    implementation.loadManagedConfig(true)
  }

  override fun getName(): String = EmmModuleImpl.NAME

  override fun onHostResume() {
    implementation.handleHostResume(currentActivity, restrictionsReceiver)
  }

  override fun onHostPause() {
    try {
      currentActivity?.unregisterReceiver(restrictionsReceiver)
    } catch (e: IllegalArgumentException) {
      // Just ignore this cause the receiver wasn't registered for this activity
    }
  }

  override fun onHostDestroy() {}

  @ReactMethod
  fun authenticate(map: ReadableMap, promise: Promise) {
    if (authPromise != null) {
      promise.reject(E_ONE_REQ_AT_A_TIME, "One auth request at a time")
      return
    }

    if (currentActivity == null) {
      promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity does not exist")
      return
    }

    authPromise = promise
    implementation.authenticate(currentActivity, map, promise)
    authPromise = null
  }

  @ReactMethod
  fun deviceSecureWith(promise: Promise) {
    implementation.deviceSecureWith(promise)
  }

  @ReactMethod
  fun setBlurScreen(enabled: Boolean) {
    implementation.setBlurScreen(currentActivity, enabled)
  }

  @ReactMethod
  fun exitApp() {
    implementation.exitApp(currentActivity)
  }

  @ReactMethod(isBlockingSynchronousMethod = true)
  fun getManagedConfig(): WritableMap = implementation.getManagedConfig()

  @ReactMethod
  fun openSecuritySettings() {
    implementation.openSecuritySettings(currentActivity)
  }

  @ReactMethod
  fun setAppGroupId(identifier: String) {
    // Not implemented
  }

  @ReactMethod
  fun addListener(eventName: String) {
    // Keep: Required for RN built in Event Emitter Calls
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    // Keep: Required for RN built in Event Emitter Calls
  }

    @ReactMethod
    fun applyBlurEffect(radius: Float = 10f) {
        implementation.applyBlurEffect(radius)
    }

    @ReactMethod
    fun removeBlurEffect() {
        implementation.removeBlurEffect()
    }
}
