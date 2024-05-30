package com.mattermost.emm

import android.app.Activity
import android.app.KeyguardManager
import android.content.*
import android.hardware.biometrics.BiometricManager.Authenticators
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.biometric.BiometricManager
import androidx.collection.ArraySet
import com.facebook.react.bridge.*
import kotlin.system.exitProcess

class EmmModuleImpl(reactApplicationContext: ReactApplicationContext) {
  private var blurEnabled: Boolean = false
  private var managedConfig: Bundle? = null

  private val restrictionsFilter = IntentFilter(Intent.ACTION_APPLICATION_RESTRICTIONS_CHANGED)
  private val keyguardManager: KeyguardManager = reactApplicationContext.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
  private val context = reactApplicationContext

  companion object {
    const val NAME = "Emm"
  }

  fun handleReceiveBroadcast(intent: Intent) {
    val managed: Bundle? = loadManagedConfig(true)

    Log.i("ReactNative", "Managed Configuration Changed")
    sendConfigChanged(managed)
  }

  fun handleActivityResult (authPromise: Promise?, activity: Activity?, requestCode: Int, resultCode: Int, data: Intent?) {
    if (requestCode != REQUEST || authPromise == null) {
      return
    }

    if (resultCode == Activity.RESULT_CANCELED) {
      authPromise.reject(CANCELLED, "User canceled")
    } else if (resultCode == Activity.RESULT_OK) {
      authPromise.resolve(true)
    }
  }

  fun handleHostResume(activity: Activity?, restrictionsReceiver: BroadcastReceiver) {
    val managed = loadManagedConfig(false)
    activity?.registerReceiver(restrictionsReceiver, restrictionsFilter)
    if (!equalBundles(managed, this.managedConfig)) {
      sendConfigChanged(managed)
    }
    handleBlurScreen(activity)
  }

  fun loadManagedConfig(global: Boolean): Bundle {
    synchronized(this) {
      val restrictionsManager: RestrictionsManager = context.getSystemService(Context.RESTRICTIONS_SERVICE) as RestrictionsManager
      val managed = restrictionsManager.applicationRestrictions

      if (global) {
        this.managedConfig = managed
      }

      return managed
    }
  }

  fun authenticate(activity: Activity?, map: ReadableMap, promise: Promise?) {
    val reason: String? = if (map.hasKey("reason")) map.getString("reason") else null
    val description: String? = if (map.hasKey("description")) map.getString("description") else null
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        val bio = BiometricPrompt.Builder(activity)
          .setAllowedAuthenticators(Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL)
        reason?.let { bio.setTitle(it) }
        description?.let { bio.setDescription(it) }

        val cancellationSignal = CancellationSignal()
        cancellationSignal.setOnCancelListener {
          Log.i("ReactNative", "Biometric prompt cancelled")
          promise?.reject(CANCELLED, "Biometric prompt cancelled")
        }

        val executor = context.mainExecutor
        val authCallback = object : BiometricPrompt.AuthenticationCallback() {
          override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
            super.onAuthenticationError(errorCode, errString)
            promise?.reject(ERROR, "error code = [${errorCode}], message = [${errString}]")
          }

          override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult?) {
            super.onAuthenticationSucceeded(result)
            promise?.resolve(true)
          }

          override fun onAuthenticationFailed() {
            super.onAuthenticationFailed()
            promise?.reject(FAILED, "Biometric authentication failed")
          }
        }
        bio.build().authenticate(cancellationSignal, executor, authCallback)
      } else {
        val authIntent: Intent? = keyguardManager?.createConfirmDeviceCredentialIntent(reason, description)
        activity?.startActivityForResult(authIntent, REQUEST)
      }
    } catch (e: Exception) {
      promise?.reject(FAILED, e)
      throw e
    }
  }

  fun deviceSecureWith(promise: Promise?) {
    val map = Arguments.createMap()
    val hasBiometrics = BiometricManager.from(context).canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS

    map.putBoolean("passcode", keyguardManager.isDeviceSecure)
    map.putBoolean("face", hasBiometrics)
    map.putBoolean("fingerprint", hasBiometrics)
    promise?.resolve(map)
  }

  fun setBlurScreen(activity: Activity?, enabled: Boolean) {
    this.blurEnabled = enabled
    handleBlurScreen(activity)
  }

  fun exitApp(activity: Activity?) {
    activity?.finish()
    exitProcess(0)
  }

  fun getManagedConfig(): WritableMap {
    return try {
      val managed = loadManagedConfig(false)
      Arguments.fromBundle(managed);
    } catch (e: Exception) {
      Arguments.createMap()
    }
  }

  fun openSecuritySettings(activity: Activity?) {
    val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    context.startActivity(intent)
    exitApp(activity)
  }

  private fun handleBlurScreen(activity: Activity?) {
    activity?.runOnUiThread(Runnable {
      if (this.blurEnabled) {
        activity.window?.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
      } else {
        activity.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
      }
    })
  }

  private fun sendConfigChanged(config: Bundle?) {
    if (context.hasActiveReactInstance()) {
      var result = Arguments.createMap()
      if (config != null) {
        result = Arguments.fromBundle(config)
      }
      context.emitDeviceEvent("managedConfigChanged", result)
    }
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
}
