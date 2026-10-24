import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/support/controllers/support_sip_call_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Full-screen customer call surface. The SIP controller remains permanent,
/// so the audio session survives route changes while this screen only renders
/// the customer-safe controls: mute and hang up.
class SupportSipCallScreen extends StatelessWidget {
  const SupportSipCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GetBuilder<SupportSipCallController>(
      builder: (call) {
        if (!call.hasActiveCall) return const SizedBox.shrink();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (call.hasPendingCall) {
                call.declinePendingCall();
              } else {
                call.end();
              }
            }
          },
          child: Material(
            color: colors.surface,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        onPressed: call.hasPendingCall
                            ? (call.isPendingActionInProgress
                                  ? null
                                  : call.declinePendingCall)
                            : call.minimizeCall,
                        icon: Icon(
                          call.hasPendingCall
                              ? Icons.close_rounded
                              : Icons.keyboard_arrow_down_rounded,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [colors.primary, colors.primaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: .22),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.phone_in_talk_rounded,
                        size: 62,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    Text(
                      call.peerName,
                      textAlign: TextAlign.center,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeOverLarge,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      call.statusLabel,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeExtraLarge,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                      ),
                      child: Text(
                        call.durationLabel,
                        style: robotoBold.copyWith(
                          fontSize: 30,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    if (call.error != null) ...[
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        call.error!,
                        textAlign: TextAlign.center,
                        style: robotoMedium.copyWith(color: colors.error),
                      ),
                    ],
                    const Spacer(),
                    if (call.hasPendingCall)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallButton(
                            icon: Icons.call_end_rounded,
                            label: 'cancel'.tr,
                            destructive: true,
                            enabled: !call.isPendingActionInProgress,
                            onTap: call.declinePendingCall,
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallButton(
                            icon: call.isMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            label: call.isMuted
                                ? 'unmute_microphone'.tr
                                : 'mute_microphone'.tr,
                            active: call.isMuted,
                            enabled: call.canControlMedia,
                            onTap: call.toggleMute,
                          ),
                          _CallButton(
                            icon: Icons.call_end_rounded,
                            label: 'end_call'.tr,
                            destructive: true,
                            onTap: call.end,
                          ),
                        ],
                      ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    Text(
                      'phone_number_hidden_for_privacy'.tr,
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool destructive;
  final bool enabled;
  final Future<void> Function() onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.destructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = destructive
        ? colors.error
        : active
        ? colors.primary
        : colors.surfaceContainerHighest;
    final foreground = destructive || active ? Colors.white : colors.onSurface;
    return Column(
      children: [
        IconButton.filled(
          onPressed: enabled ? onTap : null,
          style: IconButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            fixedSize: const Size(62, 62),
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(label, style: robotoMedium),
      ],
    );
  }
}

class _IncomingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function() onTap;
  final bool enabled;

  const _IncomingButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: enabled ? onTap : null,
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            fixedSize: const Size(70, 70),
          ),
          icon: Icon(icon, size: 30),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(label, style: robotoMedium),
      ],
    );
  }
}
