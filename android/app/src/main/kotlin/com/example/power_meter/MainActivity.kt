package com.example.power_meter

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.power_meter/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartEntrypoint.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryDetails") {
                val batteryDetails = getBatteryDetails()
                result.success(batteryDetails)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getBatteryDetails(): HashMap<String, Any> {
        val details = HashMap<String, Any>()
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = registerReceiver(null, intentFilter)

        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: 0
        details["voltage"] = voltage / 1000.0

        var currentMicro = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        if (currentMicro < 0) {
            currentMicro = -currentMicro
        }
        details["current"] = currentMicro / 1000.0

        val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: 0
        details["temperature"] = temp / 10.0

        details["capacity"] = 5000

        return details
    }
}
