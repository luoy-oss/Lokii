package com.example.lokii

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 开机自启广播接收器
 *
 * 设备重启后自动启动保活服务，确保通知监听不中断。
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        context ?: return
        intent ?: return

        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i(TAG, "设备启动完成，启动保活服务")
            KeepAliveService.start(context)
        }
    }
}
