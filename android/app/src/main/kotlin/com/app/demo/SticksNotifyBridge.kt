package com.app.demo

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Sticks notifications, the WhatsApp way (Ray, 2026-11-21).
 *
 * Each notification carries the full message and a public version that only
 * says who needs the owner ("Ada · 1 ask"). With "Hide work" (the default)
 * it is VISIBILITY_PRIVATE: on a locked phone Android shows only the public
 * version, and the words appear after unlock. "Show work" makes it public.
 * Registered by MainActivity's OPTIONAL_BRIDGES.
 */
object SticksNotifyBridge {
    private const val CHANNEL = "rokct.agent_sdk/sticks_notify"
    private const val NOTIFY_CHANNEL = "sticks_asks"
    private const val WORK_CHANNEL = "sticks_working"
    private const val ASK_PERMISSION = 7311

    @JvmStatic
    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "ask" -> result.success(ask(activity))
                "show" -> result.success(
                    show(
                        activity,
                        id = call.argument<String>("id") ?: "",
                        title = call.argument<String>("title") ?: "",
                        body = call.argument<String>("body") ?: "",
                        publicTitle = call.argument<String>("publicTitle") ?: "",
                        publicBody = call.argument<String>("publicBody") ?: "",
                        channelName = call.argument<String>("channelName") ?: "Sticks",
                        showWork = call.argument<Boolean>("showWork") ?: false,
                    ),
                )
                "working" -> result.success(
                    working(
                        activity,
                        id = call.argument<String>("id") ?: "",
                        title = call.argument<String>("title") ?: "",
                        body = call.argument<String>("body") ?: "",
                        channelName = call.argument<String>("channelName") ?: "Working",
                    ),
                )
                "blindOn" -> {
                    SticksBlindService.start(
                        activity,
                        call.argument<String>("title") ?: "Sticks",
                        call.argument<String>("body") ?: "",
                        call.argument<String>("channelName") ?: "Blind mode",
                    )
                    result.success(true)
                }
                "blindOff" -> {
                    SticksBlindService.stop(activity)
                    result.success(true)
                }
                "clear" -> {
                    val id = call.argument<String>("id") ?: ""
                    val nm = NotificationManagerCompat.from(activity)
                    nm.cancel(NOTIFY_CHANNEL, id.hashCode())
                    nm.cancel(WORK_CHANNEL, id.hashCode())
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Android 13+ needs the owner's yes before any notification shows. */
    private fun ask(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT < 33) return true
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return true
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), ASK_PERMISSION)
        return false
    }

    private fun show(
        context: Context,
        id: String,
        title: String,
        body: String,
        publicTitle: String,
        publicBody: String,
        channelName: String,
        showWork: Boolean,
    ): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(NotificationChannel(NOTIFY_CHANNEL, channelName, NotificationManager.IMPORTANCE_HIGH))
        }
        val icon = context.applicationInfo.icon
        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            PendingIntent.getActivity(context, id.hashCode(), it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        val public = NotificationCompat.Builder(context, NOTIFY_CHANNEL)
            .setSmallIcon(icon)
            .setContentTitle(publicTitle)
            .setContentText(publicBody)
            .build()
        val full = NotificationCompat.Builder(context, NOTIFY_CHANNEL)
            .setSmallIcon(icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVisibility(if (showWork) NotificationCompat.VISIBILITY_PUBLIC else NotificationCompat.VISIBILITY_PRIVATE)
            .setPublicVersion(public)
            .apply { if (open != null) setContentIntent(open) }
            .build()
        return try {
            NotificationManagerCompat.from(context).notify(NOTIFY_CHANNEL, id.hashCode(), full)
            true
        } catch (e: SecurityException) {
            false
        }
    }

    /** Live working status: quiet, ongoing, no sound; says only who works. */
    private fun working(context: Context, id: String, title: String, body: String, channelName: String): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(NotificationChannel(WORK_CHANNEL, channelName, NotificationManager.IMPORTANCE_LOW))
        }
        val n = NotificationCompat.Builder(context, WORK_CHANNEL)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
        return try {
            NotificationManagerCompat.from(context).notify(WORK_CHANNEL, id.hashCode(), n)
            true
        } catch (e: SecurityException) {
            false
        }
    }
}
