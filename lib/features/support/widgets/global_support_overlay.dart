import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/support/controllers/support_sip_call_controller.dart';
import 'package:sixam_mart/features/support/screens/support_sip_call_screen.dart';
import 'package:sixam_mart/features/support/widgets/support_help_floating_button.dart';
import 'package:sixam_mart/util/dimensions.dart';

class GlobalSupportOverlay extends StatelessWidget {
  final bool isVisible;

  const GlobalSupportOverlay({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<SupportSipCallController>()) {
      return GetBuilder<SupportSipCallController>(
        builder: (_) => _buildOverlay(context),
      );
    }
    return _buildOverlay(context);
  }

  Widget _buildOverlay(BuildContext context) {
    final bool callActive =
        Get.isRegistered<SupportSipCallController>() &&
        Get.find<SupportSipCallController>().hasActiveCall;
    final bool enabled =
        Get.isRegistered<SplashController>() &&
        Get.find<SplashController>().configModel?.supportVoiceEnabled == true;
    final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    if ((!isVisible && !callActive) ||
        !GetPlatform.isMobile ||
        (!enabled && !callActive) ||
        (keyboardVisible && !callActive)) {
      return const SizedBox.shrink();
    }

    if (callActive &&
        Get.find<SupportSipCallController>().isCallMinimized) {
      return const SizedBox.shrink();
    }

    if (callActive) {
      return const Positioned.fill(child: SupportSipCallScreen());
    }

    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: Dimensions.paddingSizeDefault,
          bottom:
              Dimensions.paddingSizeExtraLarge * 3 +
              Dimensions.paddingSizeSmall,
        ),
        child: RepaintBoundary(
          child: GetBuilder<SupportSipCallController>(
            builder: (controller) => controller.hasActiveCall
                ? const SizedBox.shrink()
                : const SupportHelpFloatingButton(),
          ),
        ),
      ),
    );
  }
}
