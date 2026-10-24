import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/support/domain/repositories/support_voice_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class SupportVoiceRepository implements SupportVoiceRepositoryInterface {
  final ApiClient apiClient;

  SupportVoiceRepository({required this.apiClient});

  @override
  Future<Response> getOptions() {
    return apiClient.getData(AppConstants.supportVoiceOptionsUri);
  }

  @override
  Future<Response> getIncomingCall() {
    return apiClient.getData(AppConstants.supportVoiceIncomingUri);
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
    return apiClient.postData(AppConstants.supportVoiceCallsUri, {
      'order_id': orderId,
      'mashwar_id': mashwarId,
      'recipient_type': recipientType,
      'recipient_id': recipientId,
      if (sipRoute != null) 'sip_route': sipRoute,
      'recording_consent': recordingConsent,
    }, handleError: false);
  }

  @override
  Future<Response> getCall(String callId) {
    return apiClient.getData('${AppConstants.supportVoiceCallsUri}/$callId');
  }

  @override
  Future<Response> acceptCall(String callId, {required bool recordingConsent}) {
    return apiClient.postData(
      '${AppConstants.supportVoiceCallsUri}/$callId/accept',
      {'recording_consent': recordingConsent},
      handleError: false,
    );
  }

  @override
  Future<Response> declineCall(String callId) {
    return apiClient.postData(
      '${AppConstants.supportVoiceCallsUri}/$callId/decline',
      {},
      handleError: false,
    );
  }

  @override
  Future<Response> cancelCall(String callId) {
    return apiClient.postData(
      '${AppConstants.supportVoiceCallsUri}/$callId/cancel',
      {},
    );
  }

  @override
  Future<Response> endCall(String callId) {
    return apiClient.postData(
      '${AppConstants.supportVoiceCallsUri}/$callId/end',
      {},
    );
  }

  @override
  Future<Response> getSession(String callId) {
    return apiClient.postData(
      '${AppConstants.supportVoiceCallsUri}/$callId/session',
      {},
    );
  }

  @override
  Future<Response> createSipSession({int? orderId}) {
    return apiClient.postData(AppConstants.supportVoiceSipSessionUri, {
      'order_id': orderId,
    }, handleError: false);
  }

  @override
  Future add(value) => throw UnimplementedError();

  @override
  Future delete(int? id) => throw UnimplementedError();

  @override
  Future get(String? id) => throw UnimplementedError();

  @override
  Future getList({int? offset}) => throw UnimplementedError();

  @override
  Future update(Map<String, dynamic> body, int? id) =>
      throw UnimplementedError();
}
