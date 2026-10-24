import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/common/widgets/offer_card_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import 'package:sixam_mart/features/store/domain/models/store_model.dart';

class FeaturedStoreCard extends StatelessWidget {
  final Store data;
  final double? width;
  final double imageHeight;
  final bool isQuick;
  final GestureTapCallback? onTap;
  final bool? isFeatured;
  const FeaturedStoreCard({
    super.key,
    required this.data,
    this.width,
    this.imageHeight = 150.0,
    required this.isQuick,
    this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    double discount = data.discount?.discount ?? 0;
    String discountType = data.discount?.discountType ?? '';
    bool isRightSide =
        Get.find<SplashController>().configModel!.currencySymbolDirection ==
        'right';
    String currencySymbol =
        Get.find<SplashController>().configModel!.currencySymbol!;

    return CustomInkWell(
      onTap: () {
        if (data.isBusy == true) {
          showBusyStoreDialog(context, store: data);
          return;
        }
        if (isStoreClosedForCustomer(data)) {
          showClosedStoreDialog(context, store: data);
          return;
        }
        onTap?.call();
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopPickImageHeader(
              data: data,
              imageHeight: imageHeight,
              favoriteButtonSize: 22,
              favoriteIconSize: 13,
              isQuick: isQuick,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            data.verifiedSeller == 1
                                ? Image.asset(
                                    Images.verifiedBadge2,
                                    width: 16,
                                    height: 16,
                                  )
                                : const SizedBox.shrink(),
                            SizedBox(width: data.verifiedSeller == 1 ? 5 : 0),

                            Flexible(
                              child: Text(
                                data.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      _TopPickRating(
                        rating: data.avgRating ?? 0,
                        reviewCount: data.ratingCount ?? data.reviewsCount ?? 0,
                      ),
                    ],
                  ),

                  if (!isFeatured! &&
                      ((data.categoryIds?.isNotEmpty ?? false) ||
                          (data.categoryNames?.isNotEmpty ?? false))) ...[
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    _CategoryTagsRow(
                      categoryIds: data.categoryIds ?? const <int>[],
                      categoryNames: data.categoryNames,
                    ),
                  ],

                  const SizedBox(height: Dimensions.paddingSizeExtraSmall - 1),
                  _TopPickMetaRow(data: data),

                  ...[
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Wrap(
                      spacing: Dimensions.paddingSizeExtraSmall,
                      runSpacing: Dimensions.paddingSizeExtraSmall,
                      children: [
                        if (data.discount != null &&
                            data.discount?.discount != 0.0)
                          OfferCardWidget(
                            label: discount > 0
                                ? '${(isRightSide || discountType == 'percent') ? '' : currencySymbol}-$discount${discountType == 'percent'
                                      ? '%'
                                      : isRightSide
                                      ? currencySymbol
                                      : ''}'
                                : 'free_delivery'.tr,
                            textDirection: discount > 0
                                ? TextDirection.ltr
                                : null,
                          ),
                        if (data.freeDelivery ?? false)
                          OfferCardWidget(
                            label: 'free'.tr,
                            iconData: Icons.directions_bike_outlined,
                          ),
                        if (data.offerLabel != null)
                          OfferCardWidget(
                            label: data.offerLabel!,
                            iconData: Icons.discount,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPickImageHeader extends StatelessWidget {
  final Store data;
  final double imageHeight;
  final double favoriteButtonSize;
  final double favoriteIconSize;
  final bool isQuick;

  const _TopPickImageHeader({
    required this.data,
    required this.imageHeight,
    required this.favoriteButtonSize,
    required this.favoriteIconSize,
    required this.isQuick,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = Get.find<StoreController>().isStoreOpen(data);

    return SizedBox(
      height: imageHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: CustomImage(
                    image: data.coverPhotoFullUrl ?? '',
                    fit: BoxFit.cover,
                    cacheWidth: ImageCacheHelper.pixels(
                      context,
                      constraints.maxWidth,
                    ),
                    cacheHeight: ImageCacheHelper.pixels(
                      context,
                      constraints.maxHeight,
                    ),
                  ),
                );
              },
            ),
          ),

          isAvailable
              ? const Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: SizedBox(),
                )
              : NotAvailableWidget(
                  isStore: true,
                  store: data,
                  fontSize: Dimensions.fontSizeExtraSmall,
                  isAllSideRound: true,
                  radius: Dimensions.radiusLarge,
                ),

          AddFavouriteView(
            top: Dimensions.paddingSizeSmall,
            right: Dimensions.paddingSizeSmall,
            item: null,
            storeId: data.id,
          ),

          Positioned(
            left: Dimensions.paddingSizeSmall,
            bottom: Dimensions.paddingSizeSmall,
            child: Row(
              spacing: Dimensions.paddingSizeExtraSmall,
              children: [
                if (data.isNew ?? false)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xffEFB135),
                      borderRadius: BorderRadius.all(
                        Radius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: Text(
                      "new".tr,
                      style: robotoSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (data.proDiscount != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(200),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(Dimensions.radiusDefault),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.red,
                                size: 12,
                              ),
                              Text(
                                "pro".tr,
                                style: robotoSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: const Color(0xffAA4949),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(
                          '-${data.proDiscount?.discount ?? '0.0'}%',
                          textDirection: TextDirection.ltr,
                          style: robotoSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (data.ad == 1)
            Positioned(
              right: Dimensions.paddingSizeSmall,
              bottom: Dimensions.paddingSizeSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Colors.black.withAlpha(100),
                ),
                child: Text(
                  "AD",
                  style: robotoBold.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopPickRating extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _TopPickRating({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    if (rating == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: Dimensions.fontSizeDefault,
          color: const Color(0xFFFFB400),
        ),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '($reviewCount)',
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopPickMetaRow extends StatelessWidget {
  final Store data;

  const _TopPickMetaRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final String timeText = data.deliveryTime ?? '';
    final double? meters =
        data.distance ??
        (data.distanceKm != null ? data.distanceKm! * 1000 : null);
    final String? distLabel =
        data.distanceLabel ?? (meters != null ? formatDistance(meters) : null);
    final String distText = distLabel != null ? ' ($distLabel)' : '';
    final String label = '$timeText$distText'.trim();
    if (label.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.access_time_filled_rounded,
          size: 14,
          color: Theme.of(context).disabledColor,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTagsRow extends StatelessWidget {
  final List<int> categoryIds;
  final List<String>? categoryNames;
  const _CategoryTagsRow({required this.categoryIds, this.categoryNames});

  @override
  Widget build(BuildContext context) {
    final serverNames =
        categoryNames
            ?.map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList() ??
        const <String>[];

    // The store endpoint can return category_names using the API/default
    // locale. Resolve the category ids through CategoryController first so
    // the labels always follow the language currently selected in the app.
    // Keep the server values only as a fallback for categories not present in
    // the currently loaded category list.
    List<String> names = <String>[];
    if (Get.isRegistered<CategoryController>() && categoryIds.isNotEmpty) {
      final CategoryController cc = Get.find<CategoryController>();
      final Set<int> seenPrimaryIds = <int>{};
      for (final int id in categoryIds) {
        final CategoryModel? category = cc.categoryList
            ?.cast<CategoryModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null);
        final int primaryId = (category?.parentId ?? 0) > 0
            ? category!.parentId!
            : id;
        if (!seenPrimaryIds.add(primaryId)) continue;
        final String? primaryName = cc.getCategoryNameById(primaryId)?.trim();
        if (primaryName != null && primaryName.isNotEmpty) {
          names.add(primaryName);
        }
      }
    }
    if (names.isEmpty) names = serverNames;
    if (names.isEmpty) return const SizedBox.shrink();
    return Text(
      names.join(', '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: robotoRegular.copyWith(
        fontSize: Dimensions.fontSizeSmall,
        color: Theme.of(context).disabledColor,
      ),
    );
  }
}

String getCategoryListAsString(List<int> ids) {
  String res = '';
  ids.map((id) {
    res += (' ${Get.find<CategoryController>().getCategoryNameById(id)}');
  }).toList();
  return res;
}

String formatDistance(double distanceInMeters) {
  if (distanceInMeters < 1000) {
    return '${distanceInMeters.toStringAsFixed(0)} m';
  } else {
    double km = distanceInMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}
