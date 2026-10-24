import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../../features/store/domain/models/store_model.dart';

bool isStoreClosedForCustomer(Store store) {
  if (store.isBusy == true) return false;
  if (Get.isRegistered<StoreController>()) {
    return !Get.find<StoreController>().isStoreOpen(store);
  }
  return store.active == false || store.open == 0;
}

Future<void> showBusyStoreDialog(
  BuildContext context, {
  Store? store,
}) async {
  return _showStoreStatusDialog(context, store: store, busy: true);
}

Future<void> showClosedStoreDialog(
  BuildContext context, {
  Store? store,
}) async {
  return _showStoreStatusDialog(context, store: store, busy: false);
}

/// Returns true when navigation into a store is allowed. Every store card and
/// shortcut should call this before opening the store screen.
Future<bool> guardStoreAccess(BuildContext context, Store store) async {
  if (store.isBusy == true) {
    await showBusyStoreDialog(context, store: store);
    return false;
  }
  if (isStoreClosedForCustomer(store)) {
    await showClosedStoreDialog(context, store: store);
    return false;
  }
  return true;
}

/// Same protection for promotional/shortcut cards that only carry a store id.
/// If the full store payload is cached, use its live busy/closed flags; if it
/// is not cached yet, leave the existing navigation flow untouched.
Future<bool> guardStoreAccessById(BuildContext context, int? storeId) async {
  if (storeId == null || !Get.isRegistered<StoreController>()) return true;
  final StoreController controller = Get.find<StoreController>();
  final List<Store> stores = <Store>[
    ...?controller.popularStoreList,
    ...?controller.latestStoreList,
    ...?controller.topOfferStoreList,
    ...?controller.featuredStoreList,
    ...?controller.verifiedStoreList,
    ...?controller.visitAgainStoreList,
    ...?controller.recommendedStoreList,
    ...?controller.storeModel?.stores,
    ...?controller.quickDeliveryStoreList?.stores,
    ...?controller.expressDeliveryStoreList?.stores,
    ...?controller.nearbyStoreList?.stores,
    ...?controller.topRatedStoreList?.stores,
  ];
  for (final Store store in stores) {
    if (store.id == storeId) return guardStoreAccess(context, store);
  }
  return true;
}

Future<void> _showStoreStatusDialog(
  BuildContext context, {
  Store? store,
  required bool busy,
}) async {
  if (!context.mounted) return;
  final String moduleType = (store?.moduleType ??
          (Get.isRegistered<SplashController>()
              ? Get.find<SplashController>().module?.moduleType
              : null) ??
      '')
      .trim()
      .toLowerCase();
  final bool isGrocery = moduleType == AppConstants.grocery;
  final bool isPharmacy = moduleType == AppConstants.pharmacy;
  final bool isEcommerce = moduleType == AppConstants.ecommerce;
  final String storeType = isGrocery
      ? 'grocery'.tr
      : isPharmacy
      ? 'pharmacy'.tr
      : isEcommerce
      ? 'ecommerce'.tr
      : 'restaurant_definite'.tr;
  final String titleKey = isPharmacy
      ? (busy ? 'pharmacy_busy_dialog_title' : 'pharmacy_closed_dialog_title')
      : (busy ? 'store_busy_dialog_title' : 'store_closed_dialog_title');
  final String messageKey = isPharmacy
      ? (busy
            ? 'pharmacy_busy_dialog_message'
            : 'pharmacy_closed_dialog_message')
      : (busy
            ? 'store_busy_dialog_message'
            : 'store_closed_dialog_message');
  final String title = titleKey.trParams({'type': storeType});
  final String message = messageKey.trParams({'type': storeType}) +
      _scheduledOpeningNotice(store: store, busy: busy, isPharmacy: isPharmacy);
  final String image = busy
      ? (isGrocery
            ? Images.groceryBusyDialog
            : isPharmacy
            ? Images.pharmacyBusyDialog
            : isEcommerce
            ? Images.ecommerceBusyDialog
            : Images.storeBusyDialog)
      : (isGrocery
            ? Images.groceryClosedDialog
            : isPharmacy
            ? Images.pharmacyClosedDialog
            : isEcommerce
            ? Images.ecommerceClosedDialog
            : Images.restaurantClosedDialog);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Directionality(
            textDirection: Get.locale?.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    image,
                    height: 138,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      color: Theme.of(dialogContext).disabledColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(dialogContext).primaryColor,
                        foregroundColor: Theme.of(dialogContext).cardColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                      ),
                      child: Text(
                        'ok'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

String _scheduledOpeningNotice({
  Store? store,
  required bool busy,
  bool isPharmacy = false,
}) {
  if (busy || store == null || store.active == false) return '';

  final String? rawOpeningTime = store.storeOpeningTime?.trim();
  if (rawOpeningTime == null ||
      rawOpeningTime.isEmpty ||
      rawOpeningTime.toLowerCase() == 'closed') {
    return '';
  }

  try {
    String openingTime =
        DateConverter.convertRestaurantOpenTime(rawOpeningTime);
    if (Get.locale?.languageCode == 'ar') {
      openingTime = openingTime
          .replaceFirst('AM', 'صباحًا')
          .replaceFirst('PM', 'مساءً');
    }
    return '\n\n${(isPharmacy ? 'pharmacy_open_at' : 'open_at').tr} $openingTime';
  } catch (_) {
    return '';
  }
}

class NotAvailableWidget extends StatelessWidget {
  final double fontSize;
  final bool isStore;
  final bool isAllSideRound;
  final double? radius;
  final Store? store;
  const NotAvailableWidget({
    super.key,
    this.fontSize = 12,
    this.isStore = false,
    this.isAllSideRound = true,
    this.radius = Dimensions.radiusSmall,
    this.store,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isStore && (store?.isBusy ?? false);
    final String moduleType = (store?.moduleType ??
            (Get.isRegistered<SplashController>()
                ? Get.find<SplashController>().module?.moduleType
                : null) ??
        '')
        .trim()
        .toLowerCase();
    final String storeType = moduleType == AppConstants.grocery
        ? 'grocery'.tr
        : moduleType == AppConstants.pharmacy
        ? 'pharmacy'.tr
        : moduleType == AppConstants.ecommerce
        ? 'ecommerce'.tr
        : 'restaurant'.tr;
    final String busyLabel = 'store_busy_dialog_title'.trParams({'type': storeType});
    return Positioned(
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: isAllSideRound
              ? BorderRadius.circular(radius!)
              : BorderRadius.vertical(top: Radius.circular(radius!)),
          color: isBusy
              ? Colors.red.shade700.withValues(alpha: 0.82)
              : Colors.black.withValues(alpha: 0.6),
        ),
        child: Text(
          isBusy
              ? busyLabel
              : isStore
              ? store != null
                    ? store!.storeOpeningTime == 'closed'
                          ? 'closed_now'.tr
                          : '${'closed_now'.tr} ${!store!.active! ? '' : '(${'open_at'.tr} ${store!.storeOpeningTime != null ? DateConverter.convertRestaurantOpenTime(store!.storeOpeningTime!) : ''})'}'
                    : 'closed_now'.tr
              : 'not_available_now_break'.tr,
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
      ),
    );
  }
}
