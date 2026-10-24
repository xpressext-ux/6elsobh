import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/support/domain/repositories/support_call_state_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class SupportCallStateRepository
    implements SupportCallStateRepositoryInterface {
  final SharedPreferences sharedPreferences;

  const SupportCallStateRepository({required this.sharedPreferences});

  @override
  String? getAuthToken() => sharedPreferences.getString(AppConstants.token);

  @override
  String getLanguageCode() {
    return sharedPreferences.getString(AppConstants.languageCode) ?? 'ar';
  }

  @override
  String? getPendingAcceptedCall() {
    return sharedPreferences.getString(
      AppConstants.supportVoicePendingAcceptedCall,
    );
  }

  @override
  Future<void> savePendingAcceptedCall(String callId) {
    return sharedPreferences.setString(
      AppConstants.supportVoicePendingAcceptedCall,
      callId,
    );
  }

  @override
  Future<void> clearPendingAcceptedCall() {
    return sharedPreferences.remove(
      AppConstants.supportVoicePendingAcceptedCall,
    );
  }
}
