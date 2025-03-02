package com.mattermost.emm

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.RestrictionsManager
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.collection.ArraySet
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import java.util.concurrent.Executor
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
        val managed: Bundle = loadManagedConfig(true)

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
        if (activity == null) {
            promise?.reject(ERROR, "Activity is null")
            return
        }

        if (activity !is FragmentActivity) {
            promise?.reject(ERROR, "Activity is not a FragmentActivity")
            return
        }

        val reason = map.getString("reason") ?: "Authenticate"
        val description = map.getString("description") ?: "Please authenticate to continue"
        val maxRetries = 3
        var failedAttempts = 0

        val cancellationSignal = CancellationSignal()
        cancellationSignal.setOnCancelListener {
            Log.i("ReactNative", "Biometric prompt cancelled")
            promise?.reject(CANCELLED, "Biometric prompt cancelled")
        }

        try {
            val biometricManager = BiometricManager.from(activity.applicationContext)
            val canAuthenticate = biometricManager.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL
            )

            if (canAuthenticate != BiometricManager.BIOMETRIC_SUCCESS) {
                promise?.reject(ERROR, "Biometric authentication not available")
                return
            }

            val executor: Executor = ContextCompat.getMainExecutor(activity.applicationContext)

            val biometricPrompt = BiometricPrompt(activity, executor, object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    when (errorCode) {
                        BiometricPrompt.ERROR_LOCKOUT -> {
                            Log.e("ReactNative", "Biometric authentication temporarily locked out")
                            promise?.reject(ERROR, "Too many failed attempts. Please try again later.")
                        }
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> {
                            Log.e("ReactNative", "Biometric authentication permanently locked")
                            promise?.reject(ERROR, "Too many failed attempts. Use device credentials.")
                        }
                        else -> {
                            promise?.reject(ERROR, "Error code [$errorCode]: $errString")
                        }
                    }
                }

                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    promise?.resolve(true)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    failedAttempts++
                    if (failedAttempts >= maxRetries) {
                        Log.w("ReactNative", "Max retries reached. Stopping authentication.")
                        promise?.reject(FAILED, "Max biometric attempts reached. Please try again later.")
                        cancellationSignal.cancel() // Cancel authentication prompt
                        return
                    }
                    Log.w("ReactNative", "Biometric authentication failed ($failedAttempts/$maxRetries), retry allowed")
                }
            })

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle(reason)
                .setDescription(description)
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                .build()

            activity.runOnUiThread {
                biometricPrompt.authenticate(promptInfo)
            }

        } catch (e: Exception) {
            promise?.reject("FAILED", e.localizedMessage ?: "Unknown error")
            throw e
        }
    }

    fun deviceSecureWith(promise: Promise?) {
        val map = Arguments.createMap()
        val biometricManager = BiometricManager.from(context)
        val canAuthenticate = biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL
        )
        val hasBiometrics = canAuthenticate == BiometricManager.BIOMETRIC_SUCCESS

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
            Arguments.fromBundle(managed)
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
        activity?.runOnUiThread {
            if (this.blurEnabled) {
                activity.window?.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
                )
            } else {
                activity.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
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
