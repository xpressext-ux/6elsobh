import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

bool isParcelServiceClosed() => Get.find<SplashController>().configModel?.parcelServiceOpen == false;

String parcelNextOpeningText() {
  final String raw = Get.find<SplashController>().configModel?.parcelNextOpening?.trim() ?? '';
  if (raw.isEmpty) return '';
  try {
    String value = DateConverter.convertRestaurantOpenTime(raw);
    final String languageCode = Get.find<LocalizationController>()
        .locale
        .languageCode
        .toLowerCase();
    final List<String> timeParts = value.split(' ');
    if (timeParts.length < 2) return value;
    final String marker = timeParts.last.toUpperCase();
    final String period = languageCode == 'ar' || languageCode == 'bn' || languageCode == 'es'
        ? (marker == 'AM' ? 'morning_period' : 'evening_period').tr
        : marker;
    return '${timeParts.first} $period';
  } catch (_) {
    return raw;
  }
}

Future<void> showParcelServiceClosedDialog(BuildContext context) async {
  if (!context.mounted) return;
  final String opening = parcelNextOpeningText();
  final String message = opening.isEmpty ? 'parcel_service_closed_message'.tr : 'parcel_service_closed_until'.trParams({'time': opening});
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity,
              height: 170,
              child: Image.asset(
                Images.parcelClosedDialogIllustration,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text('parcel_service_closed_title'.tr, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Theme.of(dialogContext).disabledColor, height: 1.5)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(dialogContext).primaryColor, foregroundColor: Theme.of(dialogContext).cardColor, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault))),
              child: Text('ok'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    ),
  );
}

class ParcelServiceClosedBanner extends StatelessWidget {
  const ParcelServiceClosedBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final String opening = parcelNextOpeningText();
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = colors.error;
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
      padding: const EdgeInsetsDirectional.fromSTEB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        SizedBox(
          width: 70,
          height: 64,
          child: Image.asset(
            Images.parcelClosedDialogIllustration,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('parcel_service_closed_banner'.tr, maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(color: accent, fontSize: Dimensions.fontSizeDefault)),
          if (opening.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('parcel_service_reopens_at'.trParams({'time': opening}), maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(color: colors.onSurfaceVariant, fontSize: Dimensions.fontSizeSmall)),
          ],
        ])),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Icon(Icons.schedule_rounded, color: accent, size: 24),
      ]),
    );
  }
}
