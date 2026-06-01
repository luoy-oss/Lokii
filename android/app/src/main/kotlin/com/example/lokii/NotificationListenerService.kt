package com.example.lokii

import android.app.Notification
import android.content.Intent
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 通知监听服务 - 捕获支付类通知
 *
 * 使用 NotificationListenerService API，无需无障碍权限。
 * 用户需在系统设置中授权"通知使用权"。
 */
class LokiiNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "LokiiNLService"

        // 平台通道名称
        const val METHOD_CHANNEL = "com.lokii/notification"
        const val EVENT_CHANNEL = "com.lokii/notification_stream"

        // 服务实例（供 MainActivity 查询状态）
        var instance: LokiiNotificationListenerService? = null
            private set

        // 支付应用包名白名单
        val PAYMENT_PACKAGES = setOf(
            "com.tencent.mm",                // 微信
            "com.eg.android.AlipayGphone",   // 支付宝
            "com.unionpay",                  // 云闪付
            "com.jingdong.app.mall",         // 京东
            "com.xunmeng.pinduoduo",         // 拼多多
            "com.sankuai.meituan",           // 美团
            "me.ele",                        // 饿了么
            "com.sdu.didi.psnger",           // 滴滴出行
            "com.autonavi.minimap",          // 高德地图
            "com.taobao.taobao",             // 淘宝
            "com.ss.android.ugc.aweme",      // 抖音
            "com.smile.gifmaker",            // 快手
            "com.MobileTicket",              // 12306
            "com.ctrip.ticket",              // 携程
            "meituan.takeoutnew",            // 美团外卖
            "com.dianping.v1",               // 大众点评
            "com.eg.android.AlipayGphone",   // 支付宝（国际版）
            "com.tencent.mobileqq",          // QQ（QQ 钱包）
            "com.pingan.paces.ccms",         // 平安壹钱包
            "com.chinamworld.bocmbci",       // 中国银行
            "com.icbc",                      // 工商银行
            "com.chinamworld.main",          // 中信银行
            "cmb.pb",                        // 招商银行
            "com.ccb.start",                 // 建设银行
            "com.abchina.abcpocket",         // 农业银行
            "com.boc.bocsoft.bocmbsassistant", // 交通银行
        )

        // 通知去重缓存（5 秒内相同内容不重复处理）
        private val recentNotifications = LinkedHashMap<String, Long>(50, 0.75f, true)
        private const val DEDUP_WINDOW_MS = 5000L
    }

    // EventChannel 事件接收器
    private var eventSink: EventChannel.EventSink? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.i(TAG, "NotificationListenerService created")
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.i(TAG, "NotificationListenerService bound")
        return super.onBind(intent)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        Log.i(TAG, "NotificationListener connected - 开始监听通知")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "NotificationListener disconnected - 尝试重新连接")
        // 尝试重新连接
        try {
            requestRebind(componentName)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request rebind: $e")
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName ?: return

        // 只处理白名单内的支付应用
        if (packageName !in PAYMENT_PACKAGES) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val content = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""

        // 合并通知文本
        val fullContent = buildString {
            if (title.isNotEmpty()) append(title)
            if (content.isNotEmpty()) {
                if (isNotEmpty()) append(" | ")
                append(content)
            }
            if (subText.isNotEmpty()) {
                if (isNotEmpty()) append(" | ")
                append(subText)
            }
            if (bigText.isNotEmpty() && bigText != content) {
                if (isNotEmpty()) append(" | ")
                append(bigText)
            }
        }

        if (fullContent.isEmpty()) return

        // 通知去重
        val dedupKey = "$packageName:$fullContent"
        val now = System.currentTimeMillis()
        synchronized(recentNotifications) {
            val lastTime = recentNotifications[dedupKey]
            if (lastTime != null && now - lastTime < DEDUP_WINDOW_MS) {
                return
            }
            recentNotifications[dedupKey] = now
            // 清理过期缓存
            if (recentNotifications.size > 100) {
                val iterator = recentNotifications.entries.iterator()
                while (iterator.hasNext()) {
                    if (now - iterator.next().value > DEDUP_WINDOW_MS * 2) {
                        iterator.remove()
                    } else break
                }
            }
        }

        Log.d(TAG, "捕获通知: pkg=$packageName, title=$title, content=$content")

        // 通过 EventChannel 发送到 Flutter
        val notificationData = mapOf(
            "packageName" to packageName,
            "title" to title,
            "content" to content,
            "subText" to subText,
            "bigText" to bigText,
            "timestamp" to now,
        )

        // 在主线程发送到 Flutter
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(notificationData)
        }

        // 同时通过广播发送（备用方案）
        val broadcastIntent = Intent("com.lokii.NOTIFICATION_RECEIVED").apply {
            putExtra("packageName", packageName)
            putExtra("title", title)
            putExtra("content", content)
            putExtra("subText", subText)
            putExtra("bigText", bigText)
            putExtra("timestamp", now)
            setPackage(packageName) // 限制在本应用内
        }
        sendBroadcast(broadcastIntent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // 通知被移除时不需要处理
    }

    /**
     * 设置 EventChannel 的事件接收器
     */
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    /**
     * 检查服务是否正在运行
     */
    fun isRunning(): Boolean {
        return instance != null
    }

    override fun onDestroy() {
        instance = null
        eventSink = null
        super.onDestroy()
        Log.i(TAG, "NotificationListenerService destroyed")
    }
}
