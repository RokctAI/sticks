package com.app.demo

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Hands the Stick that needs the owner to our launcher on the same phone, and
 * takes the owner's answer back (Ray, 2026-11-27: the Bible card flips to the
 * Stick; "launcher just give the sticks app my answer").
 *
 * WHO MAY TALK: only apps signed with this app's key. The ask goes by
 * explicit broadcast to each package whose receiver answers
 * [ACTION_ASK] and passes checkSignatures; the launcher's receiver is guarded
 * by the signature-level rokct.permission.SESSION_HANDOFF. The answer comes
 * back to [SticksAnswerReceiver], guarded by the same permission.
 *
 * Sticks has its own server and sign-in, so the launcher never calls it: the
 * answer is handed to Dart (StickNotifier), which answers through the Sticks
 * client. When Dart is not running the answer waits in [PREFS] and is sent the
 * next time Sticks runs; the server keeps the ask open until then.
 * Registered by MainActivity's OPTIONAL_BRIDGES.
 */
object SticksLauncherBridge {
    private const val CHANNEL = "rokct.agent_sdk/sticks_launcher"
    const val ACTION_ASK = "rokct.intent.action.STICK_ASK"
    const val ACTION_ANSWER = "rokct.intent.action.STICK_ANSWER"
    const val PERMISSION = "rokct.permission.SESSION_HANDOFF"
    const val PREFS = "sticks_launcher_answers"

    @Volatile
    private var channel: MethodChannel? = null

    @JvmStatic
    fun register(messenger: BinaryMessenger, activity: Activity) {
        val ch = MethodChannel(messenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    @Suppress("UNCHECKED_CAST")
                    publish(activity, call.arguments as? Map<String, Any?>)
                    result.success(true)
                }
                "takeAnswers" -> result.success(takeAnswers(activity))
                "refreshWidget" -> {
                    SticksAskWidget.refresh(activity)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Sends [ask] (or a clear, when null) to every same-key launcher. */
    private fun publish(context: Context, ask: Map<String, Any?>?) {
        val pm = context.packageManager
        val targets = try {
            pm.queryBroadcastReceivers(Intent(ACTION_ASK), 0)
                .mapNotNull { it.activityInfo?.packageName }
                .filter { it != context.packageName }
                .filter { pm.checkSignatures(context.packageName, it) == PackageManager.SIGNATURE_MATCH }
                .distinct()
        } catch (e: Exception) {
            emptyList()
        }
        for (pkg in targets) {
            val intent = Intent(ACTION_ASK).setPackage(pkg)
                .putExtra("source", context.packageName)
                .putExtra("clear", ask == null)
            ask?.forEach { (k, v) -> if (v is String) intent.putExtra(k, v) }
            try {
                context.sendBroadcast(intent, PERMISSION)
            } catch (e: Exception) {
                // A launcher that cannot be reached keeps showing the verse.
            }
        }
    }

    /** Called by [SticksAnswerReceiver]: Dart now, or kept for later. */
    fun deliver(context: Context, confirm: String, answer: String) {
        val ch = channel
        if (ch != null) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                ch.invokeMethod(
                    "answer",
                    mapOf("confirm" to confirm, "answer" to answer),
                    object : MethodChannel.Result {
                        override fun success(r: Any?) {}
                        override fun error(c: String, m: String?, d: Any?) = keep(context, confirm, answer)
                        override fun notImplemented() = keep(context, confirm, answer)
                    },
                )
            }
        } else {
            keep(context, confirm, answer)
        }
    }

    private fun keep(context: Context, confirm: String, answer: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(confirm, answer).apply()
    }

    private fun takeAnswers(context: Context): Map<String, String> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val all = prefs.all.mapNotNull { (k, v) -> (v as? String)?.let { k to it } }.toMap()
        prefs.edit().clear().apply()
        return all
    }
}

/** The launcher's answer to a Stick's ask (see [SticksLauncherBridge]). */
class SticksAnswerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != SticksLauncherBridge.ACTION_ANSWER) return
        val confirm = intent.getStringExtra("confirm") ?: return
        val answer = intent.getStringExtra("answer") ?: return
        SticksLauncherBridge.deliver(context, confirm, answer)
        // From this app's own home-screen widget: show the quiet line now.
        if (intent.getBooleanExtra("fromWidget", false)) SticksAskWidget.answered(context)
    }
}
