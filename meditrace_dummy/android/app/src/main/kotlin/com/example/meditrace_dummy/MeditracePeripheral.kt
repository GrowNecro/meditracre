package com.example.meditrace_dummy

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.os.Build
import android.os.ParcelUuid
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Collections
import java.util.Date
import java.util.Locale
import java.util.UUID

/** GATT peripheral khusus pengujian; tidak membaca sensor fisik HP. */
class MeditracePeripheral(
    private val activity: MainActivity,
    private val emit: (String, Any?) -> Unit,
) {
    private val serviceUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe001")
    private val infoUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe002")
    private val commandUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe003")
    private val statusUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe004")
    private val configUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe005")
    private val eventUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe006")
    private val otaUuid = UUID.fromString("7d2ea28a-f7bd-485a-bd9d-92ad6ecfe007")
    private val cccdUuid = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    private val manager = activity.getSystemService(BluetoothManager::class.java)
    private val connected = Collections.synchronizedSet(mutableSetOf<BluetoothDevice>())
    private val statusSubscribers = Collections.synchronizedSet(mutableSetOf<BluetoothDevice>())
    private val eventSubscribers = Collections.synchronizedSet(mutableSetOf<BluetoothDevice>())
    @Volatile private var server: BluetoothGattServer? = null
    @Volatile private var advertiser: android.bluetooth.le.BluetoothLeAdvertiser? = null
    @Volatile private var startResult: MethodChannel.Result? = null
    @Volatile private var advertising = false
    private var statusCharacteristic: BluetoothGattCharacteristic? = null
    private var eventCharacteristic: BluetoothGattCharacteristic? = null
    private var otaCharacteristic: BluetoothGattCharacteristic? = null
    @Volatile private var configJson = "{\"schedule\":[]}"
    @Volatile private var compartmentCount = 5
    @Volatile private var battery = 82
    @Volatile private var simulatedRssi: Int? = null
    @Volatile private var sensors = List(5) { 1 }
    @Volatile private var doors = List(5) { 1 }
    @Volatile private var timeSynced = false
    @Volatile private var otaBytes = 0

    @SuppressLint("MissingPermission")
    fun start(args: Map<*, *>, result: MethodChannel.Result) {
        stop()
        val adapter = manager?.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("BLUETOOTH_OFF", "Aktifkan Bluetooth terlebih dahulu.", null)
            return
        }
        val bleAdvertiser = adapter.bluetoothLeAdvertiser
        if (bleAdvertiser == null || !adapter.isMultipleAdvertisementSupported) {
            result.error("UNSUPPORTED", "HP ini tidak mendukung BLE Peripheral/advertising.", null)
            return
        }
        update(args)
        startResult = result
        advertiser = bleAdvertiser
        val gatt = manager.openGattServer(activity, callback)
        if (gatt == null) {
            failStart("GATT", "GATT server tidak dapat dibuka.")
            return
        }
        server = gatt
        val service = BluetoothGattService(serviceUuid, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val info = BluetoothGattCharacteristic(
            infoUuid,
            BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ,
        )
        val command = BluetoothGattCharacteristic(
            commandUuid,
            BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        val status = BluetoothGattCharacteristic(
            statusUuid,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ,
        )
        status.addDescriptor(cccd())
        val config = BluetoothGattCharacteristic(
            configUuid,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_READ or BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        val event = BluetoothGattCharacteristic(
            eventUuid,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            0,
        )
        event.addDescriptor(cccd())
        val ota = BluetoothGattCharacteristic(
            otaUuid,
            BluetoothGattCharacteristic.PROPERTY_WRITE or
                BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        listOf(info, command, status, config, event, ota).forEach(service::addCharacteristic)
        statusCharacteristic = status
        eventCharacteristic = event
        otaCharacteristic = ota
        if (!gatt.addService(service)) failStart("GATT", "Service MEDITRACE gagal ditambahkan.")
    }

    fun update(args: Map<*, *>) {
        compartmentCount = 5
        battery = ((args["battery"] as? Number)?.toInt() ?: battery).coerceIn(0, 100)
        simulatedRssi = (args["simulated_rssi"] as? Number)?.toInt()
        sensors = bits(args["sensors"], compartmentCount)
        doors = bits(args["doors"], compartmentCount)
        notifyStatus(statusJson())
    }

    fun sendEvent(args: Map<*, *>) {
        val name = args["event"] as? String ?: return
        if (name !in setOf("DOSE_REMOVED", "DOSE_STATE_CHANGED", "DOOR_STATE_CHANGED", "DOSE_ALARM")) return
        val id = ((args["sensor_id"] as? Number)?.toInt() ?: return)
        if (id !in 1..compartmentCount) return
        val time = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US).format(Date())
        val payload = JSONObject()
            .put("event", name)
            .put("sensor_id", id)
            .put("state", args["state"] == true)
            .put("schedule_id", args["schedule_id"] as? Number ?: 0)
            .put("status", args["status"] as? String ?: "TERCATAT")
            .put("timestamp", time)
            .toString()
        notify(eventCharacteristic, eventSubscribers, payload)
        emit("log", "$name ruang $id")
    }

    @SuppressLint("MissingPermission")
    fun stop() {
        val pending = startResult
        startResult = null
        if (pending != null) activity.runOnUiThread {
            pending.error("STOPPED", "Penyiaran dibatalkan.", null)
        }
        if (advertising) {
            try { advertiser?.stopAdvertising(advertiseCallback) } catch (_: SecurityException) { }
        }
        advertising = false
        synchronized(connected) {
            connected.toList().forEach { device ->
                try { server?.cancelConnection(device) } catch (_: Exception) { }
            }
        }
        try { server?.close() } catch (_: SecurityException) { }
        server = null
        advertiser = null
        connected.clear()
        statusSubscribers.clear()
        eventSubscribers.clear()
        statusCharacteristic = null
        eventCharacteristic = null
        emit("connection", false)
        emit("advertising", false)
    }

    private fun bits(value: Any?, count: Int): List<Int> =
        (value as? List<*>)?.take(count)?.map { if (it == true || it == 1) 1 else 0 }
            ?.let { it + List((count - it.size).coerceAtLeast(0)) { 1 } }
            ?: List(count) { 1 }

    private fun cccd() = BluetoothGattDescriptor(
        cccdUuid,
        BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE,
    )

    private fun infoJson(): String = JSONObject()
        .put("device_id", "MEDITRACE-DUMMY")
        .put("device_name", "MEDITRACE-DUMMY")
        .put("board", "ESP32-C3")
        .put("firmware", "dummy-c3-0.8.0")
        .put("battery", battery)
        .toString()

    private fun sensorJson(): String = JSONObject()
        .put("sensors", JSONArray(sensors))
        .put("doors", JSONArray(doors))
        .put("sensor_valid", true)
        .toString()

    private fun statusJson(): String = JSONObject()
        .put("battery", battery)
        .put("simulated_rssi", simulatedRssi)
        .put("rtc", false)
        .put("clock", "APP")
        .put("time_synced", timeSynced)
        .put("alarm", false)
        .put("pending", 0)
        .put("sensors", JSONArray(sensors))
        .put("doors", JSONArray(doors))
        .put("sensor_valid", true)
        .toString()

    private fun response(success: Boolean, command: String) = JSONObject()
        .put("success", success).put("command", command).toString()

    @SuppressLint("MissingPermission")
    private fun notifyStatus(payload: String) =
        notify(statusCharacteristic, statusSubscribers, payload)

    @SuppressLint("MissingPermission")
    private fun notify(
        characteristic: BluetoothGattCharacteristic?,
        subscribers: Set<BluetoothDevice>,
        payload: String,
    ) {
        val gatt = server ?: return
        val target = characteristic ?: return
        val bytes = payload.toByteArray(Charsets.UTF_8)
        target.value = bytes // Kompatibilitas Android 12 dan lebih lama.
        synchronized(subscribers) {
            subscribers.toList().forEach { device ->
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        gatt.notifyCharacteristicChanged(device, target, false, bytes)
                    } else {
                        @Suppress("DEPRECATION")
                        gatt.notifyCharacteristicChanged(device, target, false)
                    }
                } catch (_: Exception) { }
            }
        }
    }

    private fun handleCommand(raw: String) {
        val text = raw.trim()
        val command = if (text.startsWith("{")) {
            try { JSONObject(text).optString("command") } catch (_: Exception) { "" }
        } else text
        val normalized = command.uppercase(Locale.US)
        when {
            normalized == "GET_STATUS" -> notifyStatus(statusJson())
            normalized == "GET_SENSOR" -> notifyStatus(sensorJson())
            normalized == "GET_PENDING_EVENTS" -> notifyStatus("{\"pending_events\":0}")
            normalized.startsWith("SET_SCHEDULE") -> {
                configJson = text
                notifyStatus(response(true, "SET_SCHEDULE"))
            }
            normalized.startsWith("SYNC_TIME:") -> {
                timeSynced = normalized.substringAfter(':').toLongOrNull() != null
                notifyStatus(statusJson())
            }
            normalized.startsWith("OTA_BEGIN:") -> {
                otaBytes = 0
                notifyStatus(response(true, "OTA_BEGIN"))
            }
            normalized == "OTA_END" -> {
                notifyStatus(response(true, "OTA_END"))
            }
            normalized in setOf("PING", "LED_ON", "LED_OFF", "BUZZER_ON", "BUZZER_OFF", "CLEAR_SYNCED_EVENTS", "RESET") ->
                notifyStatus(response(true, normalized))
            else -> notifyStatus(response(false, normalized))
        }
        emit("log", "Perintah: $normalized")
    }

    private fun failStart(code: String, message: String) {
        val result = startResult
        startResult = null
        stop()
        activity.runOnUiThread { result?.error(code, message, null) }
    }

    @SuppressLint("MissingPermission")
    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            if (server == null || startResult == null) {
                advertiser?.stopAdvertising(this)
                return
            }
            advertising = true
            val result = startResult
            startResult = null
            activity.runOnUiThread {
                result?.success(null)
                emit("advertising", true)
            }
        }

        override fun onStartFailure(errorCode: Int) {
            failStart("ADVERTISE", "BLE advertising gagal (kode $errorCode).")
        }
    }

    @SuppressLint("MissingPermission")
    private val callback = object : BluetoothGattServerCallback() {
        override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
            if (server == null || startResult == null) return
            if (status != BluetoothGatt.GATT_SUCCESS) {
                failStart("GATT", "Service BLE tidak dapat diaktifkan (kode $status).")
                return
            }
            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setConnectable(true)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                .build()
            val data = AdvertiseData.Builder()
                .addServiceUuid(ParcelUuid(serviceUuid))
                .setIncludeDeviceName(false)
                .build()
            try { advertiser?.startAdvertising(settings, data, advertiseCallback) }
            catch (error: Exception) { failStart("ADVERTISE", error.message ?: "Tidak dapat menyiarkan BLE.") }
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == android.bluetooth.BluetoothProfile.STATE_CONNECTED) connected.add(device)
            else {
                connected.remove(device)
                statusSubscribers.remove(device)
                eventSubscribers.remove(device)
            }
            emit("connection", connected.isNotEmpty())
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            characteristic: BluetoothGattCharacteristic,
        ) {
            val payload = when (characteristic.uuid) {
                infoUuid -> infoJson()
                statusUuid -> statusJson()
                configUuid -> configJson
                else -> null
            }
            val bytes = payload?.toByteArray(Charsets.UTF_8)
            if (bytes == null || offset > bytes.size) {
                server?.sendResponse(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset, null)
            } else {
                server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, bytes.copyOfRange(offset, bytes.size))
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice, requestId: Int,
            characteristic: BluetoothGattCharacteristic, preparedWrite: Boolean,
            responseNeeded: Boolean, offset: Int, value: ByteArray,
        ) {
            val accepted = !preparedWrite && offset == 0 &&
                (characteristic.uuid == commandUuid || characteristic.uuid == configUuid ||
                    characteristic.uuid == otaUuid)
            if (responseNeeded) server?.sendResponse(
                device, requestId,
                if (accepted) BluetoothGatt.GATT_SUCCESS else BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED,
                offset, null,
            )
            if (!accepted) return
            val text = value.toString(Charsets.UTF_8)
            if (characteristic.uuid == otaUuid) {
                otaBytes += value.size
            } else if (characteristic.uuid == commandUuid) handleCommand(text)
            else {
                configJson = text
                notifyStatus(response(true, "SET_CONFIG"))
            }
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            descriptor: BluetoothGattDescriptor,
        ) {
            val subscribers = if (descriptor.characteristic.uuid == statusUuid) statusSubscribers else eventSubscribers
            val bytes = if (subscribers.contains(device))
                BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset,
                bytes.copyOfRange(offset.coerceAtMost(bytes.size), bytes.size))
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int, descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray,
        ) {
            val accepted = descriptor.uuid == cccdUuid && !preparedWrite && offset == 0 &&
                (value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE) ||
                    value.contentEquals(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE))
            if (responseNeeded) server?.sendResponse(device, requestId,
                if (accepted) BluetoothGatt.GATT_SUCCESS else BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED,
                offset, null)
            if (!accepted) return
            val subscribers = if (descriptor.characteristic.uuid == statusUuid) statusSubscribers else eventSubscribers
            if (value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) subscribers.add(device)
            else subscribers.remove(device)
            if (descriptor.characteristic.uuid == statusUuid && subscribers.contains(device)) {
                notifyStatus(statusJson())
            }
        }
    }
}
