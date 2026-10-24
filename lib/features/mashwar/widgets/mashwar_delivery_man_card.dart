import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_task_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/support/widgets/support_help_floating_button.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MashwarDeliveryManCard extends StatelessWidget {
  final MashwarDeliveryManModel deliveryMan;
  final bool allowContact;
  final int? taskId;

  const MashwarDeliveryManCard({
    super.key,
    required this.deliveryMan,
    this.allowContact = true,
    this.taskId,
  });

  static const double _actionSize = 52;
  static const double _iconSize = 28;

  Widget _contactActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: allowContact ? 1 : 0.45,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: allowContact ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: _actionSize,
            height: _actionSize,
            child: Icon(icon, size: _iconSize, color: color),
          ),
        ),
      ),
    );
  }

  Widget _assetContactActionButton({
    required BuildContext context,
    required String asset,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: allowContact ? 1 : 0.45,
      child: Material(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: allowContact ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: _actionSize,
            height: _actionSize,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(asset),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callDeliveryMan() async {
    final phone = deliveryMan.phone?.trim();
    if (phone == null || phone.isEmpty) {
      showCustomSnackBar('${'can_not_launch'.tr} -');
      return;
    }
    if (await canLaunchUrlString('tel:$phone')) {
      await launchUrlString('tel:$phone', mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dm = deliveryMan;
    final config = Get.find<SplashController>().configModel;
    // This is the customer -> deliveryman SIP action.  Keep it behind the
    // same dashboard switch used by normal orders and parcels so all order
    // types can be controlled from one place.
    final bool showSipCall =
        config?.supportVoiceEnabled == true &&
        (config?.showDeliverymanSipCallToCustomer ?? true);
    final bool showPhoneCall = config?.showDeliverymanPhoneToCustomer ?? true;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: CustomImage(
              image: dm.imageFullUrl ?? '',
              height: 48,
              width: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'delivery_man'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dm.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
              ],
            ),
          ),
          if (dm.id != null && (showSipCall || showPhoneCall)) ...[
            if (showPhoneCall) ...[
              _assetContactActionButton(
                context: context,
                asset: Images.newCallIcon,
                onTap: _callDeliveryMan,
              ),
              if (showSipCall)
                const SizedBox(width: Dimensions.paddingSizeSmall),
            ],
            if (showSipCall)
              _contactActionButton(
                context: context,
                icon: Icons.wifi_calling_3_rounded,
                color: Theme.of(context).primaryColor,
                onTap: () async {
                  if (taskId == null || dm.id == null) return;
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0),
                    builder: (_) => SupportHelpSheet(
                      mashwarId: taskId,
                      recipientType: 'deliveryman',
                      recipientId: dm.id,
                      peerDisplayName: dm.name,
                      // Mashwar uses the same secure customer-to-deliveryman
                      // flow as regular orders: the server resolves the
                      // deliveryman's registered phone and routes the call
                      // through PSTN, without waiting for a SIP-to-SIP peer.
                      pstnOnly: true,
                    ),
                  );
                },
              ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
          ],
          if (AuthHelper.isLoggedIn() && dm.id != null)
            _contactActionButton(
              context: context,
              icon: Icons.chat_rounded,
              color: Theme.of(context).primaryColor,
              onTap: () {
                Get.toNamed(
                  RouteHelper.getChatRoute(
                    notificationBody: NotificationBodyModel(
                      deliverymanId: dm.id,
                      orderId: taskId,
                    ),
                    user: User(
                      id: dm.id,
                      fName: dm.firstName,
                      lName: dm.lastName,
                      imageFullUrl: dm.imageFullUrl,
                    ),
                    // Keep the composer available only while the ride still
                    // allows contact actions. Completed/cancelled rides use
                    // the same read-only behavior as regular order chats.
                    forceComposer: allowContact,
                    hideComposer: !allowContact,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
