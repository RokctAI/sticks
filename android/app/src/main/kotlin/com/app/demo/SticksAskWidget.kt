package com.app.demo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * The Sticks widget for any launcher's home screen (Ray, 2026-11-28, approved
 * render home-widget-render.png): the Stick that needs the owner with
 * Approve/Decline, or a quiet line when nothing does. Dart (StickNotifier)
 * writes the words through the home_widget package into its
 * "HomeWidgetPreferences" store and asks for a redraw; all text arrives
 * already translated. Approve/Decline go to this app's own
 * SticksAnswerReceiver, the same path as the launcher's Bible card.
 */
class SticksAskWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        fun s(k: String) = data.getString(k, "") ?: ""
        val confirm = s("stick_confirm")
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.sticks_ask_widget)
            val asking = confirm.isNotEmpty()
            views.setTextViewText(R.id.sticks_widget_title, s(if (asking) "stick_title" else "idle_title"))
            views.setTextViewText(R.id.sticks_widget_body, s(if (asking) "stick_question" else "idle_body"))
            views.setTextViewText(R.id.sticks_widget_note, s("idle_note"))
            views.setViewVisibility(R.id.sticks_widget_note, if (asking || s("idle_note").isEmpty()) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.sticks_widget_actions, if (asking) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.sticks_widget_approve, s("approve_label"))
            views.setTextViewText(R.id.sticks_widget_decline, s("decline_label"))
            if (asking) {
                views.setOnClickPendingIntent(R.id.sticks_widget_approve, answer(context, confirm, s("stick_approve"), 1))
                views.setOnClickPendingIntent(R.id.sticks_widget_decline, answer(context, confirm, s("stick_decline"), 2))
            }
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
                views.setOnClickPendingIntent(
                    R.id.sticks_widget_root,
                    PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
                )
            }
            manager.updateAppWidget(id, views)
        }
    }

    private fun answer(context: Context, confirm: String, key: String, code: Int): PendingIntent {
        val intent = Intent(SticksLauncherBridge.ACTION_ANSWER)
            .setComponent(ComponentName(context, SticksAnswerReceiver::class.java))
            .putExtra("confirm", confirm)
            .putExtra("answer", key)
            .putExtra("fromWidget", true)
        return PendingIntent.getBroadcast(context, code, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    companion object {
        /** Shows the quiet line at once after an answer; Dart refreshes it later. */
        fun answered(context: Context) {
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .edit().putString("stick_confirm", "").apply()
            refresh(context)
        }

        /** Redraws every placed Sticks widget from the stored words. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, SticksAskWidget::class.java))
            if (ids.isNotEmpty()) SticksAskWidget().onUpdate(context, manager, ids)
        }
    }
}
