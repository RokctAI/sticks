package com.app.demo

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Sticks voice as a real Android call.
 *
 * Blind mode asks for "start" when a voice session opens and "end" when it
 * closes. While it is open, Android sees an ongoing self-managed call (like
 * WhatsApp's), so a paired watch, earbuds or car kit carries the sound over
 * Bluetooth call audio and can hang up. A hang-up from any of those comes back
 * to Dart as "onEnded". Registered by MainActivity's OPTIONAL_BRIDGES.
 */
object SticksCallBridge {
    private const val CHANNEL = "rokct.agent_sdk/sticks_call"
    private const val ACCOUNT_ID = "sticks_voice"
    private var channel: MethodChannel? = null

    @JvmStatic
    fun register(messenger: BinaryMessenger, activity: Activity) {
        val ch = MethodChannel(messenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> result.success(start(activity, call.argument<String>("name") ?: "Sticks"))
                "end" -> {
                    SticksConnectionService.endActive()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Called by the connection when the call ends outside the app. */
    fun notifyEnded() {
        channel?.invokeMethod("onEnded", null)
    }

    /** Telecom refused the call: Dart keeps the voice on the phone speaker. */
    fun notifyFailed() {
        channel?.invokeMethod("onFailed", null)
    }

    private fun start(context: Context, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val handle = PhoneAccountHandle(
                ComponentName(context, SticksConnectionService::class.java),
                ACCOUNT_ID,
            )
            telecom.registerPhoneAccount(
                PhoneAccount.builder(handle, name)
                    .setCapabilities(PhoneAccount.CAPABILITY_SELF_MANAGED)
                    .build(),
            )
            SticksConnectionService.callerName = name
            val extras = Bundle().apply {
                putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, handle)
            }
            telecom.placeCall(Uri.fromParts("sip", name, null), extras)
            true
        } catch (e: Exception) {
            // No MANAGE_OWN_CALLS, or the phone refuses: voice still works on
            // the phone speaker, just not through the watch.
            false
        }
    }
}
