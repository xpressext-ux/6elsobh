import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class SupportVoiceRepositoryInterface extends RepositoryInterface {
  Future<Response> getOptions();
  Future<Response> getIncomingCall();
  Future<Response> startCall({
    int? orderId,
    int? mashwarId,
    String recipientType = 'support',
    int? recipientId,
    String? sipRoute,
    required bool recordingConsent,
  });
  Future<Response> getCall(String callId);
  Future<Response> acceptCall(String callId, {required bool recordingConsent});
  Future<Response> declineCall(String callId);
  Future<Response> cancelCall(String callId);
  Future<Response> endCall(String callId);
  Future<Response> getSession(String callId);
  Future<Response> createSipSession({int? orderId});
}
