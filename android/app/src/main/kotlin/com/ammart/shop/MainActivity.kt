package com.ammart.shop

import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var callWakeLock: PowerManager.WakeLock? = null
    private var callWifiLock: WifiManager.WifiLock? = null
    private var proximityWakeLock: PowerManager.WakeLock? = null
    private var voiceChannel: MethodChannel? = null
    private var deviceIdentityChannel: MethodChannel? = null
    private var speakerRouteRequest = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceIdentityChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_IDENTITY_CHANNEL)
        deviceIdentityChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "androidId" -> result.success(android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.ANDROID_ID))
                else -> result.notImplemented()
            }
        }
        voiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_POWER_CHANNEL)
        voiceChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        acquireCallLocks()
                        SupportCallForegroundService.start(
                            applicationContext,
                            call.argument<String>("peer_name").orEmpty(),
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        setProximityScreen(false)
                        releaseCallLocks()
                        SupportCallForegroundService.stop(applicationContext)
                        result.success(null)
                    }
                    "setSpeaker" -> {
                        setSpeaker(call.argument<Boolean>("enabled") == true)
                        result.success(null)
                    }
                    "setProximityScreen" -> {
                        setProximityScreen(call.argument<Boolean>("enabled") == true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }


    @Suppress("DEPRECATION")
    private fun acquireCallLocks() {
        if (callWakeLock?.isHeld != true) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            callWakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "$packageName:voice-call",
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
        }
        if (callWifiLock?.isHeld != true) {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            callWifiLock = wifiManager.createWifiLock(
                WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                "$packageName:voice-call-wifi",
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
        }
    }

    private fun releaseCallLocks() {
        if (callWifiLock?.isHeld == true) callWifiLock?.release()
        if (callWakeLock?.isHeld == true) callWakeLock?.release()
        callWifiLock = null
        callWakeLock = null
    }

    @Suppress("DEPRECATION")
    private fun setSpeaker(enabled: Boolean) {
        // flutter_webrtc selects its AudioSwitch device on its own worker a
        // moment after receiving the Dart request. Apply the system route now
        // and once again after that worker settles; otherwise it can silently
        // put an Android 12+ device back on the earpiece.
        val request = ++speakerRouteRequest
        applySpeakerRoute(enabled)
        Handler(Looper.getMainLooper()).postDelayed({
            if (request == speakerRouteRequest) applySpeakerRoute(enabled)
        }, 280L)
    }

    @Suppress("DEPRECATION")
    private fun applySpeakerRoute(enabled: Boolean) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // WebRTC/Bluetooth can retain a previous device selection. Reset
            // it before selecting the requested physical output.
            audioManager.clearCommunicationDevice()
            if (enabled) {
                val speaker = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                    .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                if (speaker != null) audioManager.setCommunicationDevice(speaker)
            } else {
                val earpiece = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                    .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
                if (earpiece != null) audioManager.setCommunicationDevice(earpiece)
                else audioManager.clearCommunicationDevice()
            }
        }
        audioManager.isSpeakerphoneOn = enabled
    }

    @Suppress("DEPRECATION")
    private fun setProximityScreen(enabled: Boolean) {
        if (!enabled) {
            if (proximityWakeLock?.isHeld == true) proximityWakeLock?.release()
            proximityWakeLock = null
            return
        }
        if (proximityWakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) return
        proximityWakeLock = powerManager.newWakeLock(
            PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
            "$packageName:voice-call-proximity",
        ).apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    override fun onDestroy() {
        setProximityScreen(false)
        releaseCallLocks()
        super.onDestroy()
    }

    companion object {
        private const val VOICE_POWER_CHANNEL = "com.6elsobh/voice_call_power"
        private const val DEVICE_IDENTITY_CHANNEL = "com.ammart.shop/device_identity"
    }
}
