import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:audio_session/audio_session.dart';

/// Shared audio lifecycle for every call handled by the app's SIP layer
/// (support, employee, delivery or store). It deliberately has one native
/// foreground service so a single call cannot be duplicated in background.
class SupportCallAudioService {
  static const MethodChannel _powerChannel = MethodChannel(
    'com.6elsobh/voice_call_power',
  );

  static Future<void> begin({
    required String callId,
    required String peerName,
    required String reference,
    required bool outgoing,
  }) async {
    await _activateVoiceSession();
    if (Platform.isAndroid) {
      try {
        await _powerChannel.invokeMethod<void>('start', <String, String>{
          'call_id': callId,
          'peer_name': peerName,
          'reference': reference,
        });
      } on PlatformException {
        // The native call service remains the fallback on older installations.
      }
    }
    // The app's own SIP screen and the
    // native audio foreground service remain responsible for the call UI/media.
    await setSpeaker(false);
  }

  static Future<void> setSpeaker(bool enabled) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // WebRTC may claim the communication route while its audio track starts.
    // Apply it first, then select Android's physical speaker/earpiece last.
    await Helper.setSpeakerphoneOn(enabled);
    if (Platform.isAndroid) {
      try {
        await _powerChannel.invokeMethod<void>('setSpeaker', <String, bool>{
          'enabled': enabled,
        });
      } on PlatformException {
        // flutter_webrtc below remains the fallback on older installations.
      }
    }
  }

  /// Gives WebRTC the same audio priority as a phone call. In particular this
  /// prevents music/audio apps from taking the speaker route and keeps wired
  /// or Bluetooth headset changes under Android's voice-communication policy.
  static Future<void> _activateVoiceSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    await session.setActive(true);
  }

  static Future<void> setProximityScreen(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _powerChannel.invokeMethod<void>(
        'setProximityScreen',
        <String, bool>{'enabled': enabled},
      );
    } on PlatformException {
      // Devices without a proximity sensor simply keep the screen on.
    }
  }

  static Future<void> end() async {
    try {
      await setProximityScreen(false);
      await setSpeaker(false);
    } finally {
      if (Platform.isAndroid) {
        await _powerChannel.invokeMethod<void>('stop');
      }
      final session = await AudioSession.instance;
      await session.setActive(false);
    }
  }
}
