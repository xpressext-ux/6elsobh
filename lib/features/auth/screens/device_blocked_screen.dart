import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class DeviceBlockedScreen extends StatelessWidget {
  const DeviceBlockedScreen({super.key});

  void _retryLogin() {
    final ApiClient apiClient = Get.find<ApiClient>();
    apiClient.sharedPreferences.remove(AppConstants.deviceBlocked);
    Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/image/service/device_blocked.png',
                      height: 270,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'device_blocked_title'.tr,
                      textAlign: TextAlign.center,
                      style: robotoBold.copyWith(fontSize: 25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'device_blocked_message'.tr,
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings_rounded, color: colors.onErrorContainer),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'device_blocked_admin_notice'.tr,
                              textAlign: TextAlign.center,
                              style: robotoMedium.copyWith(color: colors.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _retryLogin,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
