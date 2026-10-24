import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/mashwar/controllers/mashwar_controller.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_task_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MashwarTaskRatingDialog extends StatefulWidget {
  final MashwarTaskModel ride;

  const MashwarTaskRatingDialog({super.key, required this.ride});

  @override
  State<MashwarTaskRatingDialog> createState() =>
      _MashwarTaskRatingDialogState();
}

class _MashwarTaskRatingDialogState extends State<MashwarTaskRatingDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final dm = ride.deliveryMan;

    return Dialog(
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'قيّم رحلتك',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
            Text(
              '${'mashwar_task'.tr} #${ride.rideReference ?? ''}',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            const SizedBox(height: 4),
            Text(
              '${ride.fromArea?.name ?? ''} ← ${ride.toArea?.name ?? ''}',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            if (dm != null) ...[
              Row(
                children: [
                  ClipOval(
                    child: CustomImage(
                      image: dm.imageFullUrl ?? '',
                      height: 44,
                      width: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      dm.name ?? '',
                      style: robotoMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
            Text(
              'التقييم مطلوب',
              style: robotoMedium.copyWith(
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    _rating >= star ? Icons.star : Icons.star_border,
                    color: _rating >= star
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'mashwar_review_comment'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            GetBuilder<MashwarController>(
              builder: (c) {
                return CustomButton(
                  buttonText: 'إرسال التقييم',
                  isLoading: c.submittingReview,
                  onPressed: () async {
                    if (_rating == 0) {
                      showCustomSnackBar('give_a_rating'.tr);
                      return;
                    }
                    final ok = await c.submitRideReview(
                      rideId: ride.id!,
                      rating: _rating,
                      comment: _commentController.text.trim(),
                    );
                    if (ok && mounted) {
                      // Mark the same ride instance as reviewed so any live
                      // update cannot reopen the prompt, then close the
                      // dialog immediately after the server confirms it.
                      ride.isReviewed = true;
                      Navigator.of(context).pop(true);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
