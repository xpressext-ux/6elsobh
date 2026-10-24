import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/support/controllers/support_sip_call_controller.dart';
import 'package:sixam_mart/features/support/controllers/support_voice_controller.dart';
import 'package:sixam_mart/features/support/domain/models/support_voice_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

const String _missedCallIdsKey = 'support_voice_missed_call_ids';
const String _missedCallHistoryKey = 'support_voice_missed_call_history';
final ValueNotifier<int> supportMissedCallCount = ValueNotifier<int>(0);

class SupportMissedCall {
  final String id;
  final DateTime happenedAt;
  final String callerName;
  final int count;

  /// missed, answered, or outgoing.
  final String status;
  const SupportMissedCall({
    required this.id,
    required this.happenedAt,
    this.callerName = 'خدمة عملاء تطبيق ستة الصبح',
    this.count = 1,
    this.status = 'missed',
  });
  factory SupportMissedCall.fromJson(Map<String, dynamic> json) =>
      SupportMissedCall(
        id: json['id']?.toString() ?? '',
        happenedAt:
            DateTime.tryParse(json['happened_at']?.toString() ?? '') ??
            DateTime.now(),
        callerName:
            json['caller_name']?.toString() ?? 'خدمة عملاء تطبيق ستة الصبح',
        count: int.tryParse(json['count']?.toString() ?? '') ?? 1,
        status: json['status']?.toString() ?? 'missed',
      );
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'happened_at': happenedAt.toIso8601String(),
    'caller_name': callerName,
    'count': count,
    'status': status,
  };
}

/// The app owns the SIP UI; no external phone-call framework is initialized.
Future<void> initializeSupportCallPlatform() async {}

Future<bool> handleSupportVoicePushData(Map<String, dynamic> data) async {
  final String type = data['type']?.toString() ?? '';
  final String callId = data['call_id']?.toString() ?? '';
  if (!_isSupportVoiceType(type) || callId.isEmpty) return false;
  // Incoming support calls are intentionally disabled to keep the customer
  // app lighter. Outgoing calls and their status events remain supported.
  if (type == 'secure_customer_incoming_call') return true;
  final service = SupportCallNotificationService.instance;
  if (type == 'support_call_answered') {
    service.markCallAnswered(callId);
  } else if (type == 'support_call_ended') {
    if (service._pendingCallIds.remove(callId)) {
      final callerFallback = service._callerNames.remove(callId);
      final currentCall = Get.find<SupportVoiceController>().currentCall;
      await recordSupportCall(
        callId,
        callerName:
            data['caller_name']?.toString() ??
            data['peer_display_name']?.toString() ??
            callerFallback,
        status:
            service._answeredCallIds.contains(callId) ||
                currentCall?.isAccepted == true
            ? 'answered'
            : 'missed',
      );
      service._answeredCallIds.remove(callId);
    }
    final controller = Get.find<SupportVoiceController>();
    if (controller.currentCall?.id == callId) {
      await controller.closeCall(
        callId,
        wasAccepted: controller.currentCall!.isAccepted,
      );
    }
  }
  return true;
}

class SupportCallNotificationService with WidgetsBindingObserver {
  SupportCallNotificationService._();
  static final SupportCallNotificationService instance =
      SupportCallNotificationService._();
  final Set<String> _shownCallIds = <String>{};
  final Set<String> _pendingCallIds = <String>{};
  final Map<String, String> _callerNames = <String, String>{};
  final Set<String> _answeredCallIds = <String>{};
  bool _attached = false;
  bool _checkingIncoming = false;
  SupportVoiceController get _controller => Get.find<SupportVoiceController>();

  Future<void> attach() async {
    if (_attached || kIsWeb) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (error) {
      debugPrint('Support call notification setup failed: $error');
    }
    await _refreshMissedCallCount();
    // Incoming-call polling is disabled. This avoids battery optimization
    // permission prompts and background work that the customer app does not
    // need; outgoing calls continue to work normally.
  }

  Future<bool> handleForegroundMessage(RemoteMessage message) async {
    final handled = await handleSupportVoicePushData(message.data);
    if (message.data['type'] == 'support_call_ended')
      _shownCallIds.remove(message.data['call_id']?.toString() ?? '');
    return handled;
  }

  Future<void> checkIncoming() async {
    if (_checkingIncoming || !AuthHelper.isLoggedIn()) return;
    _checkingIncoming = true;
    try {
      final call = await _controller.getIncomingCall();
      if (call != null && call.isWaiting && _shownCallIds.add(call.id))
        await _showIncomingCall(call.id);
    } catch (error) {
      debugPrint('Support incoming-call check failed: $error');
    } finally {
      _checkingIncoming = false;
    }
  }

  Future<void> _showIncomingCall(String callId) async {
    // A notification tap or duplicate push must not put a second call surface
    // over an already active call.
    final sipController = Get.find<SupportSipCallController>();
    if (sipController.hasActiveCall) return;
    if (!_pendingCallIds.add(callId)) return;
    final call = await _controller.getIncomingCall();
    if (call != null && call.isWaiting && !sipController.hasActiveCall) {
      if (call.peerDisplayName.trim().isNotEmpty) {
        _callerNames[callId] = call.peerDisplayName.trim();
      }
      sipController.showPendingCall(call);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshMissedCallCount());
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  void markCallAnswered(String callId) => _answeredCallIds.add(callId);
  static ValueListenable<int> get missedCallCount => supportMissedCallCount;

  static Future<List<SupportMissedCall>> getMissedCallHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_missedCallHistoryKey);
    if (raw == null || raw.isEmpty)
      return (prefs.getStringList(_missedCallIdsKey) ?? <String>[])
          .map((id) => SupportMissedCall(id: id, happenedAt: DateTime.now()))
          .toList();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .whereType<Map>()
          .map((e) => SupportMissedCall.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
      // Keep one row per caller and show the number of missed attempts.
      final grouped = <String, SupportMissedCall>{};
      for (final entry in entries) {
        final dayKey =
            '${entry.happenedAt.year}-${entry.happenedAt.month}-${entry.happenedAt.day}';
        final key =
            '${entry.callerName.trim().isEmpty ? 'خدمة عملاء تطبيق ستة الصبح' : entry.callerName.trim()}|$dayKey|${entry.status}';
        final previous = grouped[key];
        if (previous == null) {
          grouped[key] = SupportMissedCall(
            id: entry.id,
            happenedAt: entry.happenedAt,
            callerName: entry.callerName.trim().isEmpty
                ? 'خدمة عملاء تطبيق ستة الصبح'
                : entry.callerName.trim(),
            count: entry.count,
            status: entry.status,
          );
        } else {
          final latest = entry.happenedAt.isAfter(previous.happenedAt)
              ? entry
              : previous;
          grouped[key] = SupportMissedCall(
            id: latest.id,
            happenedAt: latest.happenedAt,
            callerName: previous.callerName,
            count: previous.count + entry.count,
            status: previous.status,
          );
        }
      }
      final result = grouped.values.toList()
        ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
      return result;
    } catch (_) {
      return <SupportMissedCall>[];
    }
  }

  static Future<void> markMissedCallsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_missedCallIdsKey);
    supportMissedCallCount.value = 0;
  }
}

Future<void> recordSupportCall(
  String callId, {
  String? callerName,
  String status = 'missed',
}) async {
  final prefs = await SharedPreferences.getInstance();
  final ids = (prefs.getStringList(_missedCallIdsKey) ?? <String>[]).toSet();
  if (status == 'missed') ids.add(callId);
  while (ids.length > 99) ids.remove(ids.first);
  await prefs.setStringList(_missedCallIdsKey, ids.toList());
  supportMissedCallCount.value = ids.length;
  final history = await SupportCallNotificationService.getMissedCallHistory();
  history.removeWhere((item) => item.id == callId);
  history.insert(
    0,
    SupportMissedCall(
      id: callId,
      happenedAt: DateTime.now(),
      callerName: callerName?.trim().isNotEmpty == true
          ? callerName!.trim()
          : 'خدمة عملاء تطبيق ستة الصبح',
      status: status,
    ),
  );
  if (history.length > 100) history.removeRange(100, history.length);
  await prefs.setString(
    _missedCallHistoryKey,
    jsonEncode(history.map((item) => item.toJson()).toList()),
  );
}

Future<void> _refreshMissedCallCount() async {
  final prefs = await SharedPreferences.getInstance();
  supportMissedCallCount.value =
      (prefs.getStringList(_missedCallIdsKey) ?? <String>[]).toSet().length;
}

bool _isSupportVoiceType(String type) =>
    type == 'secure_customer_incoming_call' ||
    type == 'support_call_answered' ||
    type == 'support_call_ended';
