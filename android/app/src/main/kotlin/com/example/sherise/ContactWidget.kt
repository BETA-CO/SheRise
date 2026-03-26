package com.example.sherise

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri

class ContactWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_contact_layout)
            
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val flutterContact = prefs.getString("flutter.emergency_contact", "100")
            val contact = if (flutterContact.isNullOrEmpty()) "100" else flutterContact

            val intent = Intent(Intent.ACTION_CALL)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            intent.data = Uri.parse("tel:$contact")
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            views.setOnClickPendingIntent(R.id.widget_button, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
