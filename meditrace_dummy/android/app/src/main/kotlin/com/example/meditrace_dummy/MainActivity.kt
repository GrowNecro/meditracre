package com.example.meditrace_dummy

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "meditrace_dummy/ble"
    private val permissionRequestCode = 4031
    private lateinit var channel: MethodChannel
    private lateinit var peripheral: MeditracePeripheral
    private var pendingStart: Pair<MethodChannel.Result, Map<*, *>>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        peripheral = MeditracePeripheral(this) { method, value ->
            runOnUiThread { channel.invokeMethod(method, value) }
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !hasBlePermissions()) {
                        pendingStart = result to args
                        requestPermissions(
                            arrayOf(Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT),
                            permissionRequestCode,
                        )
                    } else {
                        peripheral.start(args, result)
                    }
                }
                "stop" -> {
                    peripheral.stop()
                    result.success(null)
                }
                "update" -> {
                    peripheral.update(call.arguments as? Map<*, *> ?: emptyMap<String, Any>())
                    result.success(null)
                }
                "event" -> {
                    peripheral.sendEvent(call.arguments as? Map<*, *> ?: emptyMap<String, Any>())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasBlePermissions(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return
        val pending = pendingStart ?: return
        pendingStart = null
        if (hasBlePermissions()) {
            peripheral.start(pending.second, pending.first)
        } else {
            pending.first.error("PERMISSION", "Izinkan Perangkat terdekat untuk menyiarkan MEDITRACE Dummy.", null)
        }
    }

    override fun onDestroy() {
        if (::peripheral.isInitialized) peripheral.stop()
        super.onDestroy()
    }
}
