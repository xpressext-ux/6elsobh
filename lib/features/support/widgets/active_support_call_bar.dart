import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/support/controllers/support_sip_call_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Compact in-app call controls for the app-owned SIP call session.
class ActiveSupportCallBar extends StatelessWidget {
  const ActiveSupportCallBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SupportSipCallController>(
      builder: (call) {
        if (!call.hasActiveCall) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        return GestureDetector(
          onTap: call.restoreCall,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              Dimensions.paddingSizeSmall,
              0,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
            ),
            child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(color: colors.primary.withValues(alpha: .25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.call_rounded,
                    color: colors.onPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مكالمة جارية مع ${call.peerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${call.durationLabel} • ${call.statusLabel}',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: colors.onPrimaryContainer.withValues(
                            alpha: .72,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _CallAction(
                  tooltip: call.isMuted ? 'فتح الميكروفون' : 'كتم الميكروفون',
                  icon: call.isMuted
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  // Green is reserved for the explicitly toggled mute state.
                  active: call.isMuted,
                  onTap: call.toggleMute,
                ),
                _CallAction(
                  tooltip: 'إنهاء المكالمة',
                  icon: Icons.call_end_rounded,
                  destructive: true,
                  onTap: call.end,
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

class _CallAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;
  final bool destructive;
  final Future<void> Function() onTap;

  const _CallAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color background = destructive
        ? colors.error
        : active
        ? Colors.green.shade600
        : colors.surface;
    final Color foreground = destructive || active
        ? (destructive ? colors.onError : colors.onPrimary)
        : colors.onSurface;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        padding: EdgeInsets.zero,
        onPressed: () => onTap(),
        style: IconButton.styleFrom(backgroundColor: background),
        icon: Icon(icon, size: 19, color: foreground),
      ),
    );
  }
}
