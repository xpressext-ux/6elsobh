import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/support/controllers/support_voice_controller.dart';
import 'package:sixam_mart/features/support/controllers/support_sip_call_controller.dart';
import 'package:sixam_mart/features/support/domain/models/support_voice_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_status_bar_tint.dart';

class SupportHelpFloatingButton extends StatelessWidget {
  final int? orderId;

  const SupportHelpFloatingButton({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String label = 'support_and_help'.tr;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: Dimensions.floatingButtonTouchSize,
        child: Center(
          child: Container(
            width: Dimensions.floatingButtonCoreSize,
            height: Dimensions.floatingButtonCoreSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Keep the support button clearly visible in both themes.  A
              // black button works on the light surface, but disappears into
              // the dark screen, so use the app primary colour there.
              color: Theme.of(context).brightness == Brightness.dark
                  ? colors.primary
                  : Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.55
                        : 0.35,
                  ),
                  blurRadius: Dimensions.radiusExtraLarge,
                  offset: const Offset(0, Dimensions.paddingSizeExtraSmall),
                ),
              ],
            ),
            child: Material(
              color: colors.surface.withValues(alpha: 0),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Get.bottomSheet<void>(
                    SupportHelpSheet(orderId: orderId),
                    isScrollControlled: true,
                    backgroundColor: colors.surface.withValues(alpha: 0),
                  );
                },
                child: Icon(
                  Icons.support_agent_rounded,
                  size: Dimensions.floatingButtonIconSize,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupportHelpSheet extends StatefulWidget {
  final int? orderId;
  final int? mashwarId;
  final String recipientType;
  final int? recipientId;
  final String? peerDisplayName;
  final bool pstnOnly;

  const SupportHelpSheet({
    super.key,
    this.orderId,
    this.mashwarId,
    this.recipientType = 'support',
    this.recipientId,
    this.peerDisplayName,
    this.pstnOnly = false,
  });

  @override
  State<SupportHelpSheet> createState() => _SupportHelpSheetState();
}

class _SupportHelpSheetState extends State<SupportHelpSheet> {
  bool _openingCall = false;

  void _dismissCallSheet() {
    if (mounted) Navigator.of(context).pop();
    // GetX does not always emit a routing callback when a bottom sheet is
    // dismissed from an async call flow. Clear the modal flag explicitly so
    // the floating support button can return immediately after a failed call.
    HomeStatusBarTint.modalOpen.value = false;
  }

  @override
  void dispose() {
    HomeStatusBarTint.modalOpen.value = false;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthHelper.isLoggedIn()) {
        Get.find<SupportVoiceController>().loadOptions();
      }
    });
  }

  Future<void> _start(SupportVoiceController controller) async {
    if (_openingCall || controller.isStarting) return;
    // The SIP controller is app-wide. Never open a second call sheet/session
    // while an outgoing or incoming call is already being displayed.
    if (Get.find<SupportSipCallController>().hasActiveCall) {
      _dismissCallSheet();
      return;
    }
    setState(() => _openingCall = true);
    try {
      // Guests use the public browser dialer, which does not require an
      // account or a customer token. The web dialer identifies the caller as
      // "Guest App" for the support team.
      if (!AuthHelper.isLoggedIn()) {
        _dismissCallSheet();
        final launched = await launchUrlString(
          'https://6elsobh.com/call-us',
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          Get.snackbar(
            'الدعم والمساعدة',
            'تعذر فتح خدمة الاتصال الآن، حاول مرة أخرى.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      if (widget.recipientType == 'support' &&
          controller.options?.sipReady == true) {
        final launch = await controller.createSipSession(
          orderId: widget.orderId,
        );
        if (!mounted || launch == null) return;
        _dismissCallSheet();
        await Get.find<SupportSipCallController>().start(launch);
        return;
      }

      if (widget.recipientType != 'support') {
        final call = await controller.startCall(
          orderId: widget.orderId,
          mashwarId: widget.mashwarId,
          recipientType: widget.recipientType,
          recipientId: widget.recipientId,
          sipRoute: widget.pstnOnly ? 'pstn' : null,
          recordingConsent: false,
        );
        if (!mounted || call == null) return;
        _dismissCallSheet();
        // Store calls are routed by Issabel to the store's normal phone
        // number. Do not wait for a vendor app/push acceptance first.
        if (widget.recipientType == 'store') {
          final sipController = Get.find<SupportSipCallController>();
          sipController.showPendingCall(call);
          final launch = await controller.getSipCallSession(call.id);
          if (launch != null) {
            await sipController.start(launch);
            return;
          }
        }
        // Secure order-call buttons are PSTN-only: attach the SIP media
        // session immediately so Issabel dials the recipient's real phone
        // number instead of waiting for an in-app peer acceptance.
        final sipController = Get.find<SupportSipCallController>();
        sipController.showPendingCall(call);
        if (widget.pstnOnly) {
          final launch = await controller.getSipCallSession(call.id);
          if (launch != null) {
            await sipController.start(launch);
            return;
          }
        }
        if (call.pstnCall) {
          final launch = await controller.getSipCallSession(call.id);
          if (launch != null) {
            await sipController.start(launch);
          }
          return;
        }
        unawaited(_waitForParticipantAcceptance(controller, call.id));
        return;
      }

      Get.snackbar(
        'Voice call',
        'This call is currently available through the Issabel SIP service only.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _openingCall = false);
    }
  }

  Future<void> _waitForParticipantAcceptance(
    SupportVoiceController controller,
    String callId,
  ) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final call = await controller.refreshCall(callId);
      if (call == null || call.isFinished) {
        await Get.find<SupportSipCallController>().end(closeRemote: false);
        Get.snackbar('المكالمة الآمنة', 'لم يتم الرد على المكالمة.');
        return;
      }
      if (call.isAccepted) {
        SupportSipLaunch? launch;
        for (
          var sessionAttempt = 0;
          sessionAttempt < 5 && launch == null;
          sessionAttempt++
        ) {
          launch = await controller.getSipCallSession(callId);
          if (launch == null) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
          }
        }
        if (launch == null) {
          await Get.find<SupportSipCallController>().end(closeRemote: false);
          Get.snackbar('المكالمة الآمنة', 'تعذر تشغيل الصوت الآن.');
          return;
        }
        await Get.find<SupportSipCallController>().start(launch);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    await controller.closeCall(callId, wasAccepted: false);
    await Get.find<SupportSipCallController>().end(closeRemote: false);
    Get.snackbar('المكالمة الآمنة', 'انتهى وقت انتظار الرد.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isSupportCall = widget.recipientType == 'support';
    final String title = isSupportCall
        ? 'support_and_help'.tr
        : widget.recipientType == 'deliveryman'
        ? 'secure_call_with_deliveryman'.tr
        : 'secure_call_with_store'.tr;
    final String description = isSupportCall
        ? 'secure_support_call_description'.tr
        : '${'secure_order_call_description'.tr} ${widget.peerDisplayName ?? ''}';
    final IconData recipientIcon = isSupportCall
        ? Icons.support_agent_rounded
        : widget.recipientType == 'deliveryman'
        ? Icons.delivery_dining_rounded
        : Icons.storefront_rounded;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: GetBuilder<SupportVoiceController>(
          builder: (controller) {
            final options = controller.options;
            final bool isGuest = !AuthHelper.isLoggedIn();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: Dimensions.paddingSizeExtraLarge,
                  height: Dimensions.paddingSizeExtraSmall,
                  margin: const EdgeInsets.only(
                    bottom: Dimensions.paddingSizeLarge,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusExtraLarge,
                    ),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: Dimensions.radiusExtraLarge,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(
                        recipientIcon,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                          Text(
                            description.trim(),
                            style: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                if (isGuest) ...[
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  ElevatedButton.icon(
                    onPressed: controller.isStarting || _openingCall
                        ? null
                        : () => _start(controller),
                    icon: const Icon(Icons.call_rounded),
                    label: Text('call_support_now'.tr, style: robotoBold),
                  ),
                ] else if (controller.isLoadingOptions)
                  const Center(child: CircularProgressIndicator())
                else if (controller.errorMessage != null)
                  _SupportNotice(
                    icon: Icons.error_outline_rounded,
                    message: controller.errorMessage!,
                  )
                else if (options != null && !options.enabled)
                  _SupportNotice(
                    icon: Icons.schedule_rounded,
                    message: 'voice_support_unavailable'.tr,
                  )
                else ...[
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  ElevatedButton.icon(
                    onPressed: controller.isStarting || _openingCall
                        ? null
                        : () => _start(controller),
                    icon: controller.isStarting || _openingCall
                        ? const SizedBox(
                            width: Dimensions.paddingSizeDefault,
                            height: Dimensions.paddingSizeDefault,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.call_rounded),
                    label: Text(
                      controller.currentCall != null &&
                              !controller.currentCall!.isFinished
                          ? 'return_to_support_call'.tr
                          : isSupportCall
                          ? 'call_support_now'.tr
                          : widget.recipientType == 'deliveryman'
                          ? 'call_deliveryman'.tr
                          : 'call_store'.tr,
                      style: robotoBold,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SupportNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SupportNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(child: Text(message, style: robotoMedium)),
        ],
      ),
    );
  }
}
