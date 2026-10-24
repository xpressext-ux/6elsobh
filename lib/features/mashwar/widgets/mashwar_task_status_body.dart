import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/mashwar/controllers/mashwar_controller.dart';
import 'package:sixam_mart/features/mashwar/helpers/mashwar_rating_prompt.dart';
import 'package:sixam_mart/features/mashwar/widgets/mashwar_delivery_man_card.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MashwarTaskStatusBody extends StatefulWidget {
  final int rideId;
  final bool showHomeButtonWhenFinished;

  const MashwarTaskStatusBody({
    super.key,
    required this.rideId,
    this.showHomeButtonWhenFinished = true,
  });

  @override
  State<MashwarTaskStatusBody> createState() => _MashwarTaskStatusBodyState();
}

class _MashwarTaskStatusBodyState extends State<MashwarTaskStatusBody> {
  Timer? _timer;
  int? _ratingPromptRideId;

  @override
  void initState() {
    super.initState();
    final c = Get.find<MashwarController>();
    c.fetchRideDetails(widget.rideId);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      c.fetchRideDetails(widget.rideId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'searching_driver':
        return 'mashwar_status_searching'.tr;
      case 'accepted':
        return 'mashwar_status_accepted'.tr;
      case 'driver_en_route':
        return 'mashwar_status_en_route'.tr;
      case 'arrived_pickup':
        return 'mashwar_status_arrived'.tr;
      case 'trip_started':
        return 'mashwar_status_started'.tr;
      case 'completed':
        return 'mashwar_status_completed'.tr;
      case 'cancelled':
        return 'mashwar_status_cancelled'.tr;
      default:
        return s ?? '';
    }
  }

  Future<void> _confirmCancel(MashwarController c) async {
    final reasonController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('mashwar_cancel_task'.tr, style: robotoMedium),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'سبب الإلغاء (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'تأكيد',
              style: robotoMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await c.cancelActiveRide(reason: reasonController.text.trim());
      if (mounted) setState(() {});
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MashwarController>(
      builder: (c) {
        final ride = c.activeRide;
        if (ride == null || ride.id != widget.rideId) {
          return const Center(child: CircularProgressIndicator());
        }

        final searching = ride.isSearchingDriver;

        if (ride.needsReview && _ratingPromptRideId != ride.id) {
          _ratingPromptRideId = ride.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MashwarRatingPrompt.checkAndShow(ride: ride);
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '#${ride.rideReference ?? ''}',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                ride.rideStatusLabel ?? _statusLabel(ride.rideStatus),
                style: robotoMedium.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (searching) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'mashwar_searching_hint'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ],
              if (ride.isCancelled &&
                  ride.cancelReason != null &&
                  ride.cancelReason!.trim().isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mashwar_cancel_reason'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.cancelReason!,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Dimensions.paddingSizeLarge),
              if (ride.description != null &&
                  ride.description!.trim().isNotEmpty)
                _row('mashwar_task_details'.tr, ride.description),
              if (ride.attachmentUrls.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'mashwar_attachment'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ride.attachmentUrls.map((url) {
                    final isImage = RegExp(
                      r'\.(jpe?g|png|gif|webp)$',
                      caseSensitive: false,
                    ).hasMatch(url);
                    return InkWell(
                      onTap: () async {
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: isImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSmall,
                              ),
                              child: CustomImage(
                                image: url,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 88,
                              height: 88,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).disabledColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSmall,
                                ),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 32,
                              ),
                            ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],
              _row(
                'mashwar_delivery_zone'.tr,
                ride.deliveryArea?.name ??
                    ride.toArea?.name ??
                    ride.fromArea?.name,
              ),
              if ((ride.stopCount ?? 1) > 1)
                _row('mashwar_stop_count'.tr, '${ride.stopCount}'),
              _row('المبلغ', ride.rideAmount?.formatted),
              if (ride.isReviewed == true && ride.dmRating != null) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تقييمك',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            (ride.dmRating ?? 0) > index
                                ? Icons.star
                                : Icons.star_border,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          );
                        }),
                      ),
                      if (ride.dmReviewComment != null &&
                          ride.dmReviewComment!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          ride.dmReviewComment!,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (ride.showDeliveryManInfo && ride.deliveryMan != null) ...[
                const SizedBox(height: Dimensions.paddingSizeLarge),
                MashwarDeliveryManCard(
                  deliveryMan: ride.deliveryMan!,
                  allowContact: ride.canContactActions,
                  taskId: ride.id,
                ),
              ],
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              if (ride.canCustomerCancel)
                CustomButton(
                  buttonText: 'mashwar_cancel_task'.tr,
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _confirmCancel(c),
                ),
              if (ride.isFinished &&
                  widget.showHomeButtonWhenFinished &&
                  ride.isReviewed == true) ...[
                CustomButton(
                  buttonText: 'رجوع للرئيسية',
                  onPressed: () {
                    c.clearFinishedActiveRide();
                    Get.offAllNamed(RouteHelper.getInitialRoute());
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(String k, String? v) => Padding(
    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
    child: Row(
      children: [
        SizedBox(width: 70, child: Text(k, style: robotoMedium)),
        Expanded(child: Text(v ?? '—')),
      ],
    ),
  );
}
