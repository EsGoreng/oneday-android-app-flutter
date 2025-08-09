package com.urdev.oneday // Ganti dengan package name Anda

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.balance_widget_layout).apply {
                // Ambil data dari SharedPreferences yang disimpan oleh Flutter
                val balance = widgetData.getString("balance", "Rp0")
                val income = widgetData.getString("income", "Rp0")
                val expenses = widgetData.getString("expenses", "Rp0")

                // Set teks ke TextViews
                setTextViewText(R.id.tv_balance, balance)
                setTextViewText(R.id.tv_income, income)
                setTextViewText(R.id.tv_expenses, expenses)

                // Set warna (contoh)
                // Warna sudah di-set di XML, tapi ini cara jika ingin dinamis
                // setTextColor(R.id.tv_income, Color.parseColor("#2ECC71"))
                // setTextColor(R.id.tv_expenses, Color.parseColor("#E74C3C"))
                
                // Intent untuk membuka aplikasi saat widget di-klik
                val launchIntent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}