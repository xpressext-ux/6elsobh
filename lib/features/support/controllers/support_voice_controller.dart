import 'dart:async';

import 'package:get/get.dart';
import 'package:sixam_mart/features/support/domain/models/support_voice_model.dart';
import 'package:sixam_mart/features/support/domain/services/support_voice_service_interface.dart';

class SupportVoiceController extends GetxController implements GetxService {
  final SupportVoiceServiceInterface supportVoiceServiceInterface;

  SupportVoiceController({required this.supportVoiceServiceInterface});

  SupportVoiceOptions? _options;
  SupportVoiceOptions? get options => _options;

  SupportVoiceCall? _currentCall;
  SupportVoiceCall? get currentCall => _currentCall;

  bool _isLoadingOptions = false;
  bool get isLoadingOptions => _isLoadingOptions;

  bool _isStarting = false;
  bool get isStarting => _isStarting;

  bool _isClosing = false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadOptions() async {
    _isLoadingOptions = true;
    _errorMessage = null;
    update();
    final response = await supportVoiceServiceInterface.getOptions();
    if (response.statusCode == 200 && response.body is Map) {
      _options = SupportVoiceOptions.fromJson(
        Map<String, dynamic>.from(response.body),
      );
      _currentCall = _options?.activeCall;
    } else {
      _errorMessage = _message(response.body, response.statusText);
    }
    _isLoadingOptions = false;
    update();
  }

  Future<SupportVoiceCall?> startCall({
    int? orderId,
    int? mashwarId,
    String recipientType = 'support',
    int? recipientId,
    String? sipRoute,
    required bool recordingConsent,
  }) async {
    if (_isStarting) return null;
    _isStarting = true;
    _errorMessage = null;
    update();
    final response = await supportVoiceServiceInterface.startCall(
      orderId: orderId,
      mashwarId: mashwarId,
      recipientType: recipientType,
      recipientId: recipientId,
      sipRoute: sipRoute,
      recordingConsent: recordingConsent,
    );
    final bool isSuccessful =
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
    if (isSuccessful) {
      _currentCall = _callFromBody(response.body);
      _currentCall ??= await _recoverCreatedCall();
    }
    if (!isSuccessful) {
      _errorMessage = _message(response.body, response.statusText);
    } else if (_currentCall == null) {
      _errorMessage = 'something_went_wrong'.tr;
    }
    _isStarting = false;
    update();
    return _currentCall;
  }

  Future<SupportSipLaunch?> createSipSession({int? orderId}) async {
    if (_isStarting) return null;
    _isStarting = true;
    _errorMessage = null;
    update();

    // Do not create a second support call when the user taps the button again
    // or reopens the help sheet. Resume the existing server-side call instead.
    final SupportVoiceCall? activeCall = _currentCall;
    if (activeCall != null &&
        !activeCall.isFinished &&
        activeCall.recipientType == 'support') {
      final SupportSipLaunch? existingLaunch = await getSipCallSession(
        activeCall.id,
      );
      _isStarting = false;
      update();
      return existingLaunch;
    }

    SupportSipLaunch? launch;
    try {
      final response = await supportVoiceServiceInterface
          .createSipSession(orderId: orderId)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.body is Map) {
        final body = Map<String, dynamic>.from(response.body);
        if (body['call'] is Map && body['session'] is Map) {
          launch = SupportSipLaunch.fromJson(body);
          _currentCall = launch.call;
        }
      }
      if (launch == null) {
        _errorMessage = _message(response.body, response.statusText);
      }
    } on TimeoutException {
      _errorMessage = 'انتهى وقت انتظار الاتصال، حاول مرة أخرى';
    } catch (error) {
      _errorMessage = error.toString();
    }
    _isStarting = false;
    update();
    return launch;
  }

  SupportVoiceCall? _callFromBody(dynamic body) {
    if (body is! Map) return null;

    final Map<String, dynamic> responseMap = Map<String, dynamic>.from(body);
    dynamic payload = responseMap['call'];
    final dynamic data = responseMap['data'];
    if (payload is! Map && data is Map) {
      final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
      payload = dataMap['call'] ?? dataMap;
    }
    if (payload is! Map && responseMap['id'] != null) {
      payload = responseMap;
    }

    return payload is Map
        ? SupportVoiceCall.fromJson(Map<String, dynamic>.from(payload))
        : null;
  }

  Future<SupportVoiceCall?> _recoverCreatedCall() async {
    final response = await supportVoiceServiceInterface.getOptions();
    if (response.statusCode == 200 && response.body is Map) {
      _options = SupportVoiceOptions.fromJson(
        Map<String, dynamic>.from(response.body),
      );
      return _options?.activeCall;
    }
    return null;
  }

  Future<SupportVoiceCall?> refreshCall(String callId) async {
    final response = await supportVoiceServiceInterface.getCall(callId);
    final SupportVoiceCall? call = _callFromBody(response.body);
    if (response.statusCode == 200 && call != null) {
      _currentCall = call;
      update();
      return _currentCall;
    }
    return null;
  }

  Future<SupportVoiceCall?> getIncomingCall() async {
    final response = await supportVoiceServiceInterface.getIncomingCall();
    final SupportVoiceCall? call = _callFromBody(response.body);
    if (response.statusCode == 200 && call != null) {
      _currentCall = call;
      update();
      return call;
    }
    return null;
  }

  Future<SupportVoiceCall?> acceptIncomingCall(
    String callId, {
    required bool recordingConsent,
  }) async {
    final response = await supportVoiceServiceInterface.acceptCall(
      callId,
      recordingConsent: recordingConsent,
    );
    final SupportVoiceCall? call = _callFromBody(response.body);
    if (response.statusCode == 200 && call != null) {
      _currentCall = call;
      update();
      return call;
    }
    _errorMessage = _message(response.body, response.statusText);
    update();
    return null;
  }

  Future<void> declineIncomingCall(String callId) async {
    await supportVoiceServiceInterface.declineCall(callId);
    if (_currentCall?.id == callId) _currentCall = null;
    update();
  }

  Future<SupportVoiceSession?> getSession(String callId) async {
    final response = await supportVoiceServiceInterface.getSession(callId);
    final dynamic responseCall = response.body is Map
        ? response.body['call']
        : null;
    if (response.statusCode == 200 && responseCall is Map) {
      return SupportVoiceSession.fromJson(
        Map<String, dynamic>.from(responseCall),
      );
    } else {
      _errorMessage = _message(response.body, response.statusText);
    }
    update();
    return null;
  }

  Future<SupportSipLaunch?> getSipCallSession(
    String callId, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final response = await supportVoiceServiceInterface
          .getSession(callId)
          .timeout(timeout);
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body);
        if (body['call'] is Map && body['session'] is Map) {
          return SupportSipLaunch.fromJson(body);
        }
      }
      _errorMessage = _message(response.body, response.statusText);
    } on TimeoutException {
      _errorMessage = 'انتهى وقت انتظار الاتصال، حاول مرة أخرى';
    } catch (error) {
      _errorMessage = error.toString();
    }
    update();
    return null;
  }

  Future<void> closeCall(String callId, {required bool wasAccepted}) async {
    if (_isClosing) return;
    _isClosing = true;
    try {
      if (wasAccepted) {
        await supportVoiceServiceInterface.endCall(callId);
      } else {
        await supportVoiceServiceInterface.cancelCall(callId);
      }
    } finally {
      if (_currentCall?.id == callId) _currentCall = null;
      _isClosing = false;
      update();
    }
  }

  String _message(dynamic body, String? fallback) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return fallback ?? 'something_went_wrong'.tr;
  }
}
