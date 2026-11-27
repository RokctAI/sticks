package com.app.demo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Keeps blind mode listening while the app is in the background or the
 * screen is off (Ray, 2026-11-11: "will blind mode work when closed or in
 * background? … always on notification"). A foreground service of type
 * microphone with one always-on notification; it stops when blind mode ends.
 * Started and stopped by SticksNotifyBridge ("blindOn" / "blindOff").
 */
class SticksBlindService : Service() {
    companion object {
        private const val CHANNEL = "sticks_blind"
        private const val ID = 7312

        fun start(context: Context, title: String, body: String, channelName: String) {
            val i = Intent(context, SticksBlindService::class.java)
                .putExtra("title", title).putExtra("body", body).putExtra("channelName", channelName)
            ContextCompat.startForegroundService(context, i)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SticksBlindService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra("title") ?: "Sticks"
        val body = intent?.getStringExtra("body") ?: ""
        val channelName = intent?.getStringExtra("channelName") ?: "Blind mode"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(NotificationChannel(CHANNEL, channelName, NotificationManager.IMPORTANCE_LOW))
        }
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, ID, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        val n: Notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .apply { if (open != null) setContentIntent(open) }
            .build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            } else {
                startForeground(ID, n)
            }
        } catch (e: Exception) {
            // Android refused (no microphone permission yet): blind mode still
            // works while the app is open.
            stopSelf()
        }
        return START_NOT_STICKY
    }
}
