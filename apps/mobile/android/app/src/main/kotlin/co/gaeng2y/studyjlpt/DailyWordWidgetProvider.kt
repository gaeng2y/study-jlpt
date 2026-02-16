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

class DailyWordWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val json = widgetData.getString("today_word_json", null)
        val jp = parseString(json, "jp", "단어 없음")
        val reading = parseString(json, "reading", "")
        val meaning = parseString(json, "meaningKo", "")
        val level = parseString(json, "jlptLevel", "")

        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_word).apply {
                setTextViewText(R.id.widget_daily_word_title, "오늘의 단어")
                setTextViewText(R.id.widget_daily_word_jp, jp)
                setTextViewText(R.id.widget_daily_word_reading, reading)
                setTextViewText(
                    R.id.widget_daily_word_meaning,
                    if (level.isBlank()) meaning else "[$level] $meaning"
                )
                val launchIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("studyjlpt://content/today-word"),
                    context,
                    MainActivity::class.java
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                setOnClickPendingIntent(
                    R.id.widget_daily_word_root,
                    PendingIntent.getActivity(
                        context,
                        appWidgetId + 1000,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun parseString(json: String?, key: String, fallback: String): String {
        if (json.isNullOrBlank()) return fallback
        return try {
            JSONObject(json).optString(key, fallback)
        } catch (_: Exception) {
            fallback
        }
    }
}
