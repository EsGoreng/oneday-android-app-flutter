package com.urdev.oneday

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONException
import android.view.View
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TaskWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.home_widget_layout).apply {
                    // Fungsi klik untuk membuka aplikasi
                    val launchIntent = Intent(context, MainActivity::class.java)
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                    // Atur tanggal saat ini
                    val dayNameFormat = SimpleDateFormat("EEEE", Locale.getDefault())
                    val dateFormat = SimpleDateFormat("dd/MM/yy", Locale.getDefault())
                    val currentDate = Date()
                    val dateText = "${dayNameFormat.format(currentDate)}\n${dateFormat.format(currentDate)}"
                    setTextViewText(R.id.widget_date, dateText)

                    // Logika untuk menampilkan list task
                    removeAllViews(R.id.tasks_list)

                    val tasksJsonString = widgetData.getString("tasks_json", "[]")
                    val tasks = JSONArray(tasksJsonString)

                    if (tasks.length() == 0) {
                        // Tampilkan pesan jika tidak ada tugas
                        val noTaskView = RemoteViews(context.packageName, R.layout.widget_task_item).apply {
                            setTextViewText(R.id.task_title, "No Task Today")
                            setTextViewText(R.id.task_description, "Enjoy your day!")
                            setViewVisibility(R.id.status_icon, View.GONE)
                        }
                        addView(R.id.tasks_list, noTaskView)
                    } else {
                        // Loop melalui setiap tugas dan tambahkan ke view
                        for (i in 0 until tasks.length()) {
                            val task = tasks.getJSONObject(i)
                            val taskStatus = task.optBoolean("status", false)
                            val taskTitle = task.optString("title", "No Title")
                            // Ambil deskripsi dari JSON
                            val taskDescription = task.optString("description", "")

                            val statusIconRes = if (taskStatus) {
                                R.drawable.ic_checkbox_checked
                            } else {
                                R.drawable.ic_checkbox_unchecked
                            }

                            val taskItemView = RemoteViews(context.packageName, R.layout.widget_task_item).apply {
                                setTextViewText(R.id.task_title, taskTitle)
                                // Set teks untuk deskripsi
                                setTextViewText(R.id.task_description, taskDescription)
                                // Tampilkan deskripsi hanya jika tidak kosong
                                setViewVisibility(R.id.task_description, if (taskDescription.isNotEmpty()) View.VISIBLE else View.GONE)
                                setImageViewResource(R.id.status_icon, statusIconRes)
                                setViewVisibility(R.id.status_icon, View.VISIBLE)
                            }
                            addView(R.id.tasks_list, taskItemView)
                        }
                    }
                }
                appWidgetManager.updateAppWidget(widgetId, views)

            } catch (e: JSONException) {
                Log.e("TaskWidgetProvider", "Error parsing JSON", e)
                val errorViews = RemoteViews(context.packageName, R.layout.home_widget_layout).apply{
                    removeAllViews(R.id.tasks_list)
                    val errorItemView = RemoteViews(context.packageName, R.layout.widget_task_item).apply {
                        setTextViewText(R.id.task_title, "Error loading tasks.")
                        setViewVisibility(R.id.status_icon, View.GONE)
                    }
                    addView(R.id.tasks_list, errorItemView)
                }
                appWidgetManager.updateAppWidget(widgetId, errorViews)
            
            } catch (e: Exception) {
                 Log.e("TaskWidgetProvider", "An unexpected error occurred", e)
            }
        }
    }
}