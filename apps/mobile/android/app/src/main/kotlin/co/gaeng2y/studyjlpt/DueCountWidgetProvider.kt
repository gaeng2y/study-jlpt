package co.gaeng2y.studyjlpt

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.app.PendingIntent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class DueCountWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val json = widgetData.getString("today_summary_json", null)
        val dueCount = parseInt(json, "dueCount", 0)
        val estMinutes = parseInt(json, "estMinutes", 1)
        val streak = parseInt(json, "streak", 0)

        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_due_count).apply {
                setTextViewText(R.id.widget_due_count_title, "오늘 복습")
                setTextViewText(R.id.widget_due_count_value, "${dueCount}개 · 약 ${estMinutes}분")
                setTextViewText(R.id.widget_due_count_sub, "연속 ${streak}일")
                val launchIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("studyjlpt://review"),
                    context,
                    MainActivity::class.java
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                setOnClickPendingIntent(
                    R.id.widget_due_count_root,
                    PendingIntent.getActivity(
                        context,
                        appWidgetId,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun parseInt(json: String?, key: String, fallback: Int): Int {
        if (json.isNullOrBlank()) return fallback
        return try {
            JSONObject(json).optInt(key, fallback)
        } catch (_: Exception) {
            fallback
        }
    }
}
