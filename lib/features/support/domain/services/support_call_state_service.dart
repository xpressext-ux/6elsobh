import 'package:sixam_mart/features/support/domain/repositories/support_call_state_repository_interface.dart';
import 'package:sixam_mart/features/support/domain/services/support_call_state_service_interface.dart';

class SupportCallStateService implements SupportCallStateServiceInterface {
  final SupportCallStateRepositoryInterface supportCallStateRepositoryInterface;

  const SupportCallStateService({
    required this.supportCallStateRepositoryInterface,
  });

  @override
  String? getAuthToken() {
    return supportCallStateRepositoryInterface.getAuthToken();
  }

  @override
  String getLanguageCode() {
    return supportCallStateRepositoryInterface.getLanguageCode();
  }

  @override
  String? getPendingAcceptedCall() {
    return supportCallStateRepositoryInterface.getPendingAcceptedCall();
  }

  @override
  Future<void> savePendingAcceptedCall(String callId) {
    return supportCallStateRepositoryInterface.savePendingAcceptedCall(callId);
  }

  @override
  Future<void> clearPendingAcceptedCall() {
    return supportCallStateRepositoryInterface.clearPendingAcceptedCall();
  }
}
