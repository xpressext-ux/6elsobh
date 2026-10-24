import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/delivery_area_model.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class DeliveryAreaSection extends StatelessWidget {
  final CheckoutController checkoutController;

  const DeliveryAreaSection({super.key, required this.checkoutController});

  @override
  Widget build(BuildContext context) {
    // A store may use the regular delivery rule and have no sub-areas at all.
    // In that case keep this optional section out of checkout and let the
    // normal delivery pricing apply. Show it only when the store actually
    // returned sub-areas.
    if (checkoutController.orderType != 'delivery' ||
        checkoutController.deliveryAreasLoading ||
        checkoutController.deliveryAreas.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      child: CustomCardCheckout(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delivery_area'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (checkoutController.isDeliveryAreaAutoDetected &&
                checkoutController.selectedDeliveryArea != null)
              _buildAutoAreaTile(context, checkoutController)
            else
              DropdownButtonFormField<DeliveryAreaModel>(
                value: checkoutController.selectedDeliveryArea,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'select_delivery_area'.tr,
                ),
                items: checkoutController.deliveryAreas.map((area) {
                  return DropdownMenuItem<DeliveryAreaModel>(
                    value: area,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            area.areaName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Text(PriceConverter.convertPrice(area.deliveryCharge)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: checkoutController.selectDeliveryArea,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoAreaTile(
    BuildContext context,
    CheckoutController controller,
  ) {
    final area = controller.selectedDeliveryArea!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.areaName,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'تلقائي من موقعك',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.enableManualDeliveryAreaSelection,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'تغيير',
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
