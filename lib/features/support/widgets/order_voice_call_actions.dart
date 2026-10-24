import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/support/widgets/support_help_floating_button.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class OrderVoiceCallActions extends StatelessWidget {
  final OrderModel order;

  const OrderVoiceCallActions({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final bool enabled =
        Get.find<SplashController>().configModel?.supportVoiceEnabled == true;
    final int? deliverymanId = order.deliveryMan?.id;
    final int? storeId = order.store?.id;

    if (!enabled || (deliverymanId == null && storeId == null)) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
        margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.14),
              blurRadius: Dimensions.radiusExtraLarge,
              offset: const Offset(0, Dimensions.paddingSizeExtraSmall),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deliverymanId != null)
              _OrderVoiceCallButton(
                icon: Icons.delivery_dining_rounded,
                label: 'call_deliveryman'.tr,
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0),
                    builder: (_) => SupportHelpSheet(
                      orderId: order.id,
                      recipientType: 'deliveryman',
                      recipientId: deliverymanId,
                      peerDisplayName:
                          [order.deliveryMan?.fName, order.deliveryMan?.lName]
                              .whereType<String>()
                              .where((name) => name.isNotEmpty)
                              .join(' '),
                    ),
                  );
                },
              ),
            if (deliverymanId != null && storeId != null)
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            if (storeId != null)
              _OrderVoiceCallButton(
                icon: Icons.storefront_rounded,
                label: 'call_store'.tr,
                filled: true,
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0),
                    builder: (_) => SupportHelpSheet(
                      orderId: order.id,
                      recipientType: 'store',
                      recipientId: storeId,
                      peerDisplayName: order.store?.name,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderVoiceCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const _OrderVoiceCallButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: filled ? colors.primary : colors.primaryContainer,
        foregroundColor: filled ? colors.onPrimary : colors.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
          vertical: Dimensions.paddingSizeDefault,
        ),
        textStyle: robotoBold,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
