import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/order/screens/my_order_screen.dart';
import 'package:sixam_mart/features/mashwar/controllers/mashwar_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileStatCardsWidget extends StatelessWidget {
  const ProfileStatCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final bool isLoggedIn = AuthHelper.isLoggedIn();
        if (!isLoggedIn || profileController.userInfoModel == null) {
          return const SizedBox.shrink();
        }

        final user = profileController.userInfoModel!;
        final MashwarController? mashwar = Get.isRegistered<MashwarController>()
            ? Get.find<MashwarController>()
            : null;
        if (mashwar != null && !mashwar.loading && !mashwar.historyLoaded) {
          mashwar.fetchRideHistory().then((_) => profileController.update());
        }
        final int totalOrders =
            (user.orderCount ?? 0) + (mashwar?.rideHistory.length ?? 0);
        final List<_StatItemData> items = [
          _StatItemData(
            iconAsset: Images.loyaltyIcon2,
            iconBgColor: const Color(0xFFFFF4D6),
            backgroundGradient: const [Color(0xFFFFFDF3), Color(0xFFFFF3D2)],
            value: (user.loyaltyPoint ?? 0).toString(),
            labelKey: 'loyalty_point',
            onTap: () => Get.toNamed(RouteHelper.getLoyaltyRoute()),
          ),
          _StatItemData(
            iconAsset: Images.walletIcon2,
            iconBgColor: const Color(0xFFE6F0FF),
            backgroundGradient: const [Color(0xFFF5F7FF), Color(0xFFE8EEFF)],
            value: PriceConverter.convertPrice(
              user.walletBalance,
              forMenuWallet: true,
            ),
            labelKey: 'wallet',
            onTap: () => Get.toNamed(RouteHelper.getWalletRoute()),
          ),
          _StatItemData(
            iconAsset: Images.shoppingBagIcon,
            iconBgColor: const Color(0xFFE7F7EC),
            backgroundGradient: const [Color(0xFFF1FFF5), Color(0xFFE1F6E9)],
            value: totalOrders.toString(),
            labelKey: 'total_orders_profile',
            onTap: () => Get.to(() => const MyOrderScreen()),
          ),
        ];

        final double cardHeight = (MediaQuery.of(context).size.width * 0.22)
            .clamp(76.0, 96.0);

        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeSmall,
          ),
          height: cardHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int index = 0; index < items.length; index++) ...[
                if (index > 0)
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(child: _StatCard(data: items[index])),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatItemData {
  final String iconAsset;
  final Color iconBgColor;
  final List<Color> backgroundGradient;
  final String value;
  final String labelKey;
  final VoidCallback onTap;

  const _StatItemData({
    required this.iconAsset,
    required this.iconBgColor,
    required this.backgroundGradient,
    required this.value,
    required this.labelKey,
    required this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItemData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final Brightness cardBrightness =
        ThemeData.estimateBrightnessForColor(data.backgroundGradient.last);
    final Color textColor = cardBrightness == Brightness.light
        ? Colors.black87
        : Colors.white;
    final Color labelColor = cardBrightness == Brightness.light
        ? Colors.black54
        : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: data.backgroundGradient,
            ),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeExtraSmall,
              vertical: 3,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: data.iconBgColor.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(data.iconAsset, fit: BoxFit.contain),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.value,
                    maxLines: 1,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(
                      fontSize: 10,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SUMMARY
// Row of profile stat cards. Values remain dynamic and each card opens its matching
// screen when tapped.
