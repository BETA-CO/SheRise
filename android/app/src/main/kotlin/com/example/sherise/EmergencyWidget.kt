package com.example.sherise

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class EmergencyWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val views = RemoteViews(context.packageName, R.layout.widget_layout)

    val widgetData = HomeWidgetPlugin.getData(context)
    val widgetText = widgetData.getString("widget_text", "SOS")
    val widgetBg = widgetData.getString("widget_bg", "idle")

    views.setTextViewText(R.id.widget_text, widgetText)
    
    if (widgetBg == "active") {
        views.setInt(R.id.widget_button, "setBackgroundResource", R.drawable.circular_button_active)
        views.setTextColor(R.id.widget_text, Color.parseColor("#FF5252"))
    } else {
        views.setInt(R.id.widget_button, "setBackgroundResource", R.drawable.circular_button_idle)
        views.setTextColor(R.id.widget_text, Color.parseColor("#FFFFFF"))
    }

    // Trigger Background Intent
    val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
        context,
        Uri.parse("homeWidget://emergency")
    )

    views.setOnClickPendingIntent(R.id.widget_button, backgroundIntent)
    appWidgetManager.updateAppWidget(appWidgetId, views)
}
