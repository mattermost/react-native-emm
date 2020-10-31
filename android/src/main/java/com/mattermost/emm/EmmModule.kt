package com.mattermost.emm

import android.app.Activity
import android.app.KeyguardManager
import android.content.*
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.annotation.RequiresApi
import androidx.biometric.BiometricManager
import androidx.collection.ArraySet
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import kotlin.system.exitProcess


@RequiresApi(Build.VERSION_CODES.M)
class EmmModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), LifecycleEventListener {
  private var blurEnabled: Boolean = false
  private var managedConfig: Bundle? = null
  private var authPromise: Promise? = null
  private var keyguardManager: KeyguardManager = reactContext.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager

  private val AUTH_REQUEST: Int = 18864
  private val E_ACTIVITY_DOES_NOT_EXIST: String = "E_ACTIVITY_DOES_NOT_EXIST"
  private val E_AUTH_CANCELLED: String = "UserCancel"
  private val E_FAILED_TO_SHOW_AUTH: String = "E_FAILED_TO_SHOW_AUTH"
  private val E_ONE_REQ_AT_A_TIME: String = "E_ONE_REQ_AT_A_TIME"
  private val restrictionsFilter = IntentFilter(Intent.ACTION_APPLICATION_RESTRICTIONS_CHANGED)

  private val restrictionsReceiver: BroadcastReceiver = object : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
      val managed: Bundle? = loadManagedConfig(ctx, true)

      Log.i("ReactNative", "Managed Configuration Changed")
      sendConfigChanged(managed)
    }
  }

  private val mActivityEventListener = object : BaseActivityEventListener() {
    override fun onActivityResult(activity: Activity?, requestCode: Int, resultCode: Int, data: Intent?) {
      if (requestCode != AUTH_REQUEST || authPromise == null) {
        return
      }

      if (resultCode == Activity.RESULT_CANCELED) {
        authPromise?.reject(E_AUTH_CANCELLED, "User canceled")
      } else if (resultCode == Activity.RESULT_OK) {
        authPromise?.resolve(true)
      }

      authPromise = null
    }
  }

  init {
    reactContext.addLifecycleEventListener(this)
    reactContext.addActivityEventListener(mActivityEventListener)
    loadManagedConfig(reactContext, true)
  }

  override fun getName(): String {
      return "Emm"
  }

  override fun onHostResume() {
    val managed = loadManagedConfig(reactApplicationContext, false)
    currentActivity?.registerReceiver(restrictionsReceiver, restrictionsFilter)
    if (!equalBundles(managed, this.managedConfig)) {
      sendConfigChanged(managed)
    }
    handleBlurScreen()
  }

  override fun onHostPause() {
    try {
      currentActivity?.unregisterReceiver(restrictionsReceiver)
    } catch (e: IllegalArgumentException) {
      // Just ignore this cause the receiver wasn't registered for this activity
    }
  }

  override fun onHostDestroy() {}

  private fun handleBlurScreen() {
    val activity = currentActivity
    activity?.runOnUiThread(Runnable {
      if (this.blurEnabled) {
        activity?.window?.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
      } else {
        activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
      }
    })
  }

  fun loadManagedConfig(ctx: Context, global: Boolean): Bundle? {
    synchronized(this) {
      if (ctx != null) {
        val restrictionsManager: RestrictionsManager = ctx.getSystemService(Context.RESTRICTIONS_SERVICE) as RestrictionsManager
        val managed = restrictionsManager.applicationRestrictions

        if (global) {
          this.managedConfig = managed
        }

        if (managed != null && managed!!.size() > 0) {
          return managed
        }

        return null;
      }

      return null;
    }
  }

  private fun sendConfigChanged(config: Bundle?) {
    var result = Arguments.createMap()
    if (config != null) {
      result = Arguments.fromBundle(config)
    }

    val ctx = this.reactApplicationContext
    ctx.getJSModule(RCTDeviceEventEmitter::class.java)?.emit("managedConfigChanged", result)
  }

  private fun equalBundles(one: Bundle?, two: Bundle?): Boolean {
    if (one == null && two == null) {
      return true
    }

    if (one == null || two == null) return false
    if (one.size() !=  two.size()) return false

    var valueOne: Any?
    var valueTwo: Any?
    val setOne: MutableSet<String> = ArraySet()

    setOne.addAll(one.keySet())
    setOne.addAll(two.keySet())

    for (key in setOne) {
      if (!one.containsKey(key) || !two.containsKey(key)) return false

      valueOne = one[key]
      valueTwo = two[key]
      if (valueOne is Bundle && valueTwo is Bundle &&
              !equalBundles(valueOne as Bundle?, valueTwo as Bundle?)) {
        return false
      } else if (valueOne == null) {
        if (valueTwo != null) return false
      } else if (valueOne != valueTwo) return false
    }
    return true
  }

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

    val reason: String? = if (map.hasKey("reason")) map.getString("reason") else null
    val description: String? = if (map.hasKey("description")) map.getString("description") else null
    try {
      // Add Android Q with BiometricPrompt (https://stackoverflow.com/questions/56928769/how-to-set-a-fallback-method-if-fingerprint-does-not-work)
      val authIntent: Intent? = keyguardManager?.createConfirmDeviceCredentialIntent(reason, description)
      currentActivity?.startActivityForResult(authIntent, AUTH_REQUEST)
    } catch (e: Exception) {
      authPromise?.reject(E_FAILED_TO_SHOW_AUTH, e)
      authPromise = null
    }
  }

  @ReactMethod
  fun deviceSecureWith(promise: Promise) {
    val map = Arguments.createMap()
    val hasBiometrics = BiometricManager.from(reactApplicationContext).canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS

    map.putBoolean("passcode", keyguardManager.isDeviceSecure)
    map.putBoolean("face", hasBiometrics)
    map.putBoolean("fingerprint", hasBiometrics)
    promise.resolve(map)
  }

  @ReactMethod
  fun enableBlurScreen(enabled: Boolean) {
    this.blurEnabled = enabled
    handleBlurScreen()
  }

  @ReactMethod
  fun exitApp() {
    currentActivity?.finish()
    exitProcess(0)
  }

  @ReactMethod
  fun getManagedConfig(promise: Promise) {
    try {
      val managed = loadManagedConfig(this.reactApplicationContext, false)
      val result: Any = Arguments.fromBundle(managed)
      promise.resolve(result)
    } catch (e: Exception) {
      promise.resolve(Arguments.createMap())
    }
  }

  @ReactMethod
  fun openSecuritySettings() {
    val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    reactApplicationContext.startActivity(intent)
    exitApp()
  }
}
