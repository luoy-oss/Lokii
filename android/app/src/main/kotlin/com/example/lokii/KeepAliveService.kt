package com.example.lokii

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 前台保活服务
 *
 * 通过显示一个最小化的常驻通知，防止系统杀死 NotificationListenerService。
 * 支持 Android 14+ 的前台服务类型声明。
 */
class KeepAliveService : Service() {

    companion object {
        private const val TAG = "KeepAliveService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "lokii_keep_alive"
        private const val CHANNEL_NAME = "自动记账服务"

        var instance: KeepAliveService? = null
            private set

        /**
         * 启动保活服务
         */
        fun start(context: Context) {
            val intent = Intent(context, KeepAliveService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /**
         * 停止保活服务
         */
        fun stop(context: Context) {
            context.stopService(Intent(context, KeepAliveService::class.java))
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        Log.i(TAG, "KeepAliveService started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 如果服务被杀死，自动重启
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        instance = null
        super.onDestroy()
        Log.i(TAG, "KeepAliveService destroyed")
    }

    /**
     * 创建通知渠道（Android 8.0+）
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW  // 低优先级，不打扰用户
            ).apply {
                description = "Lokii 自动记账服务运行状态"
                setShowBadge(false)  // 不显示角标
                enableVibration(false)  // 不振动
                enableLights(false)  // 不亮灯
                setSound(null, null)  // 无声音
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * 构建前台服务通知
     */
    private fun buildNotification(): Notification {
        // 点击通知打开应用
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Lokii 自动记账")
            .setContentText("正在监听支付通知")
            .setSmallIcon(android.R.drawable.ic_popup_reminder)  // 使用系统图标，后续可替换
            .setContentIntent(pendingIntent)
            .setOngoing(true)  // 不可滑动删除
            .setSilent(true)  // 静默通知
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
