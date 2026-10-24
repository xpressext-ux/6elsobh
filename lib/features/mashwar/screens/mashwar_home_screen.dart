import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/mashwar/controllers/mashwar_controller.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_area_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_bootstrap_model.dart';
import 'package:sixam_mart/features/mashwar/screens/mashwar_task_list_screen.dart';
import 'package:sixam_mart/features/mashwar/widgets/mashwar_app_bar_widget.dart';
import 'package:sixam_mart/features/mashwar/widgets/mashwar_task_status_body.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class MashwarHomeScreen extends StatefulWidget {
  final bool asModule;
  const MashwarHomeScreen({super.key, this.asModule = false});

  @override
  State<MashwarHomeScreen> createState() => _MashwarHomeScreenState();
}

class _MashwarHomeScreenState extends State<MashwarHomeScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  static const double _dashboardBottomNavClearance = 88;

  double _bottomClearance(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + _dashboardBottomNavClearance;
  }

  @override
  void initState() {
    super.initState();
    Get.find<MashwarController>().startLiveUpdates();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    if (Get.isRegistered<MashwarController>()) {
      Get.find<MashwarController>().stopLiveUpdates();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = GetBuilder<MashwarController>(
      id: MashwarController.formUpdateId,
      builder: (c) {
        if (c.hasOngoingRide && c.activeRide?.id != null) {
          return MashwarTaskStatusBody(
            rideId: c.activeRide!.id!,
            showHomeButtonWhenFinished: false,
          );
        }

        if (c.bootstrap != null && c.bootstrap!.available != true) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: _MashwarUnavailableNotice(bootstrap: c.bootstrap!),
            ),
          );
        }

        final enabledStops = c.enabledStops;
        final extraFee = c.bootstrap?.extraStopFee?.formatted ?? '';
        final canSubmit =
            c.bootstrap?.available == true &&
            !c.submittingRide &&
            !c.hasOngoingRide &&
            !c.bootstrapping;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeDefault,
              _bottomClearance(context) + Dimensions.paddingSizeSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'المنطقة: ${c.bootstrap?.zoneName ?? '...'}',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ),
                    if (c.bootstrapping)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () =>
                          Get.to(() => const MashwarTaskListScreen()),
                      icon: const Icon(Icons.history, size: 16),
                      label: Text(
                        'mashwar_my_tasks'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        decoration: InputDecoration(
                          labelText: 'mashwar_task_details'.tr,
                          hintText: 'mashwar_task_details_hint'.tr,
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault,
                            ),
                          ),
                        ),
                        onChanged: c.setDescription,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'mashwar_delivery_zone'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _areaDropdown(
                        value: c.selectedArea,
                        items: c.bootstrap?.deliveryAreas ?? [],
                        hint: 'mashwar_select_delivery_zone'.tr,
                        onChanged: (v) => c.selectArea(v),
                      ),
                      if (enabledStops.length > 1) ...[
                        const SizedBox(height: 14),
                        Text(
                          'mashwar_stop_count'.tr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        if (extraFee.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'mashwar_extra_stop_fee_hint'.trParams({
                              'fee': extraFee,
                            }),
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: enabledStops.map((stop) {
                            return ChoiceChip(
                              label: Text(_stopLabel(stop)),
                              selected: c.stopCount == stop,
                              onSelected: (_) => c.setStopCount(stop),
                            );
                          }).toList(),
                        ),
                      ],
                      if (c.fare != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('mashwar_task_cost'.tr, style: robotoMedium),
                              Text(c.fare!.formatted ?? '', style: robotoBold),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'mashwar_pickup_note'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault,
                            ),
                          ),
                        ),
                        onChanged: c.setPickupNote,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: c.pickTaskImage,
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: Text('mashwar_add_image'.tr),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: c.pickTaskAttachment,
                              icon: const Icon(Icons.attach_file, size: 18),
                              label: Text('mashwar_add_file'.tr),
                            ),
                          ),
                        ],
                      ),
                      if (c.taskImage != null || c.taskAttachment != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (c.taskImage != null && !kIsWeb)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(c.taskImage!.path),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 28,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.taskAttachmentName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: c.clearTaskImage,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      CustomButton(
                        height: 46,
                        buttonText: 'mashwar_place_task'.tr,
                        isLoading: c.submittingRide,
                        onPressed: canSubmit
                            ? () async {
                                if (c.submittingRide) return;
                                c.setDescription(
                                  _descriptionController.text.trim(),
                                );
                                c.setPickupNote(_noteController.text.trim());
                                await c.placeRide();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return widget.asModule
        ? body
        : Scaffold(appBar: const MashwarAppBarWidget(), body: body);
  }

  String _stopLabel(int stop) {
    switch (stop) {
      case 1:
        return 'mashwar_one_stop'.tr;
      case 2:
        return 'mashwar_two_stops'.tr;
      default:
        return 'mashwar_places_count'.trParams({'count': '$stop'});
    }
  }

  Widget _areaDropdown({
    required MashwarAreaModel? value,
    required List<MashwarAreaModel> items,
    required void Function(MashwarAreaModel?)? onChanged,
    required String hint,
  }) {
    final Color inputTextColor = Theme.of(context).colorScheme.onSurface;
    final Color hintColor = inputTextColor.withValues(alpha: 0.6);

    return DropdownButtonFormField<MashwarAreaModel>(
      isExpanded: true,
      value: value != null && items.any((e) => e.id == value.id)
          ? items.firstWhere((e) => e.id == value.id)
          : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
      hint: Text(hint, style: robotoRegular.copyWith(color: hintColor)),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                '${e.name ?? ''}${e.price?.formatted != null ? ' — ${e.price!.formatted}' : ''}',
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(color: inputTextColor),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _MashwarUnavailableNotice extends StatelessWidget {
  final MashwarBootstrapModel bootstrap;

  const _MashwarUnavailableNotice({required this.bootstrap});

  @override
  Widget build(BuildContext context) {
    final bool outsideHours = bootstrap.isOutsideWorkingHours;
    final String openingTime = _localizedMashwarTime(bootstrap.nextOpeningTime ?? '');
    final String subtitle = outsideHours && openingTime.isNotEmpty
        ? 'mashwar_closed_until'.trParams({'time': openingTime})
        : 'mashwar_unavailable'.tr;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = colors.primary;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
             height: 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
             clipBehavior: Clip.antiAlias,
             decoration: const BoxDecoration(
               borderRadius: BorderRadius.vertical(
                 top: Radius.circular(Dimensions.radiusExtraLarge),
               ),
             ),
            child: Stack(
              children: [
                 Positioned.fill(
                   child: Image.asset(
                     Images.mashwarClosedCardIllustration,
                     fit: BoxFit.cover,
                   ),
                ),
                 Positioned.fill(
                   child: DecoratedBox(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [
                           Colors.black.withValues(alpha: 0.06),
                           Colors.transparent,
                           Colors.black.withValues(alpha: 0.12),
                         ],
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                       ),
                     ),
                  ),
                ),
                 PositionedDirectional(
                   top: 14,
                   end: 16,
                   child: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.92),
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.12),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Icon(Icons.schedule, color: accent, size: 22),
                   ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              outsideHours ? 'mashwar_closed_title'.tr : 'mashwar_unavailable'.tr,
              textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedMashwarTime(String raw) {
  if (raw.trim().isEmpty) return '';
  final bool isArabic = Get.locale?.languageCode == 'ar';
  return raw.trim().replaceAllMapped(
    RegExp(r'\b(am|pm)\b', caseSensitive: false),
    (match) {
      final String marker = match.group(1)!.toUpperCase();
      if (!isArabic) return marker;
      return marker == 'AM' ? 'صباحًا' : 'مساءً';
    },
  );
}
