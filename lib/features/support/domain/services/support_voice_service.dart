import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/support/domain/repositories/support_voice_repository_interface.dart';
import 'package:sixam_mart/features/support/domain/services/support_voice_service_interface.dart';

class SupportVoiceService implements SupportVoiceServiceInterface {
  final SupportVoiceRepositoryInterface supportVoiceRepositoryInterface;

  SupportVoiceService({required this.supportVoiceRepositoryInterface});

  @override
  Future<Response> getOptions() => supportVoiceRepositoryInterface.getOptions();

  @override
  Future<Response> getIncomingCall() {
    return supportVoiceRepositoryInterface.getIncomingCall();
  }

  @override
  Future<Response> startCall({
    int? orderId,
    int? mashwarId,
    String recipientType = 'support',
    int? recipientId,
    String? sipRoute,
    required bool recordingConsent,
  }) {
    return supportVoiceRepositoryInterface.startCall(
      orderId: orderId,
      mashwarId: mashwarId,
      recipientType: recipientType,
      recipientId: recipientId,
      sipRoute: sipRoute,
      recordingConsent: recordingConsent,
    );
  }

  @override
  Future<Response> getCall(String callId) {
    return supportVoiceRepositoryInterface.getCall(callId);
  }

  @override
  Future<Response> acceptCall(String callId, {required bool recordingConsent}) {
    return supportVoiceRepositoryInterface.acceptCall(
      callId,
      recordingConsent: recordingConsent,
    );
  }

  @override
  Future<Response> declineCall(String callId) {
    return supportVoiceRepositoryInterface.declineCall(callId);
  }

  @override
  Future<Response> cancelCall(String callId) {
    return supportVoiceRepositoryInterface.cancelCall(callId);
  }

  @override
  Future<Response> endCall(String callId) {
    return supportVoiceRepositoryInterface.endCall(callId);
  }

  @override
  Future<Response> getSession(String callId) {
    return supportVoiceRepositoryInterface.getSession(callId);
  }

  @override
  Future<Response> createSipSession({int? orderId}) {
    return supportVoiceRepositoryInterface.createSipSession(orderId: orderId);
  }
}
