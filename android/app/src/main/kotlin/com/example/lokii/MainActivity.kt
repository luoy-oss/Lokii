package com.example.lokii

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 主 Activity - 平台通道注册
 *
 * 提供以下通道：
 * - MethodChannel: 权限检查、服务控制
 * - EventChannel: 实时通知流
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val METHOD_CHANNEL = "com.lokii/notification"
        private const val EVENT_CHANNEL = "com.lokii/notification_stream"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── MethodChannel ──────────────────────────────────────────
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openNotificationSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "openBatterySettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(LokiiNotificationListenerService.instance != null)
                }
                "startKeepAlive" -> {
                    KeepAliveService.start(this)
                    result.success(true)
                }
                "stopKeepAlive" -> {
                    KeepAliveService.stop(this)
                    result.success(true)
                }
                "getPaymentPackages" -> {
                    result.success(LokiiNotificationListenerService.PAYMENT_PACKAGES.toList())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ── EventChannel ───────────────────────────────────────────
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "EventChannel: Flutter 开始监听通知")
                LokiiNotificationListenerService.instance?.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "EventChannel: Flutter 停止监听通知")
                LokiiNotificationListenerService.instance?.setEventSink(null)
            }
        })

        // 启动保活服务
        KeepAliveService.start(this)

        Log.i(TAG, "FlutterEngine configured, channels registered")
    }

    /**
     * 检查通知监听权限是否已授予
     */
    private fun isNotificationListenerEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && TextUtils.equals(pkgName, cn.packageName)) {
                    return true
                }
            }
        }
        return false
    }

    /**
     * 打开通知监听设置页面
     */
    private fun openNotificationListenerSettings() {
        try {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
        } catch (e: Exception) {
            Log.e(TAG, "无法打开通知监听设置: $e")
            // 备用方案：打开应用详情设置
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = android.net.Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (e2: Exception) {
                Log.e(TAG, "无法打开应用设置: $e2")
            }
        }
    }

    /**
     * 打开电池优化设置页面
     */
    private fun openBatteryOptimizationSettings() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = android.net.Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "无法打开电池优化设置: $e")
            // 备用方案：打开电池设置
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (e2: Exception) {
                Log.e(TAG, "无法打开电池设置: $e2")
            }
        }
    }

    override fun onDestroy() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        super.onDestroy()
    }
}
