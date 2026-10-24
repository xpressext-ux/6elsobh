abstract class SupportCallStateServiceInterface {
  String? getAuthToken();
  String getLanguageCode();
  String? getPendingAcceptedCall();
  Future<void> savePendingAcceptedCall(String callId);
  Future<void> clearPendingAcceptedCall();
}
