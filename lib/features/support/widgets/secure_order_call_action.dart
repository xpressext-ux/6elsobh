import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/support/widgets/support_help_floating_button.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class SecureOrderCallAction extends StatelessWidget {
  final OrderModel order;
  final String recipientType;
  final int recipientId;
  final String? peerDisplayName;

  const SecureOrderCallAction({
    super.key,
    required this.order,
    required this.recipientType,
    required this.recipientId,
    this.peerDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final config = Get.find<SplashController>().configModel;
    final bool enabled =
        AuthHelper.isLoggedIn() &&
        config?.supportVoiceEnabled == true &&
        (recipientType != 'store' ||
            (config?.showStoreSipCallToCustomer ?? true)) &&
        (recipientType != 'deliveryman' ||
            (config?.showDeliverymanSipCallToCustomer ?? true));
    const ended = {
      'delivered',
      'failed',
      'canceled',
      'refund_requested',
      'refunded',
      'refund_request_canceled',
    };
    if (!enabled || ended.contains(order.orderStatus))
      return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final String label = recipientType == 'deliveryman'
        ? 'call_deliveryman'.tr
        : 'secure_call_with_store'.tr;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: colors.primaryContainer,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => Get.bottomSheet<void>(
              SupportHelpSheet(
                orderId: order.id,
                recipientType: recipientType,
                recipientId: recipientId,
                peerDisplayName: peerDisplayName,
                pstnOnly: true,
              ),
              isScrollControlled: true,
              backgroundColor: colors.surface.withValues(alpha: 0),
            ),
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: Dimensions.paddingSizeExtremeLarge,
              child: Icon(
                Icons.wifi_calling_3_rounded,
                size: Dimensions.fontSizeLarge,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
