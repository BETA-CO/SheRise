package com.example.sherise

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class LocationWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_location_layout)
            
            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("homeWidget://location")
            )

            views.setOnClickPendingIntent(R.id.widget_button, backgroundIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
