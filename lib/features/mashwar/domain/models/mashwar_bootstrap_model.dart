import 'package:sixam_mart/features/mashwar/domain/models/mashwar_area_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_price_model.dart';

class MashwarBootstrapModel {
  bool? available;
  int? zoneId;
  String? zoneName;
  String? message;
  String? nextOpeningTime;
  List<MashwarAreaModel>? deliveryAreas;
  MashwarPriceModel? extraStopFee;
  int? maxStops;
  List<int> enabledStops;

  MashwarBootstrapModel({
    this.available,
    this.zoneId,
    this.zoneName,
    this.message,
    this.nextOpeningTime,
    this.deliveryAreas,
    this.extraStopFee,
    this.maxStops,
    this.enabledStops = const [1, 2],
  });

  List<MashwarAreaModel>? get areas => deliveryAreas;

  factory MashwarBootstrapModel.fromJson(Map<String, dynamic> json) {
    final int? maxStops = json['max_stops'] != null
        ? int.tryParse(json['max_stops'].toString())
        : 2;

    List<int> enabledStops = const [1, 2];
    final enabledJson = json['enabled_stops'];
    if (enabledJson is List) {
      enabledStops =
          enabledJson
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((n) => n >= 1 && n <= 5)
              .toSet()
              .toList()
            ..sort();
      if (enabledStops.isEmpty) {
        enabledStops = [1];
      }
    } else {
      final max = maxStops ?? 2;
      enabledStops = max <= 1 ? [1] : List<int>.generate(max, (i) => i + 1);
    }

    List<MashwarAreaModel>? deliveryAreas;
    final areasJson = json['delivery_areas'] ?? json['areas'];
    if (areasJson != null) {
      deliveryAreas = <MashwarAreaModel>[];
      areasJson.forEach(
        (v) => deliveryAreas!.add(MashwarAreaModel.fromJson(v)),
      );
    }

    MashwarPriceModel? extraStopFee;
    if (json['extra_stop_fee'] != null) {
      extraStopFee = MashwarPriceModel.fromJson(
        Map<String, dynamic>.from(json['extra_stop_fee']),
      );
    }

    final String rawMessage = json['message']?.toString() ?? '';
    final String? openingTime =
        json['next_opening_time']?.toString() ??
        json['opens_at']?.toString() ??
        _openingTimeFromMessage(rawMessage);

    return MashwarBootstrapModel(
      available: json['available'],
      zoneId: json['zone_id'],
      zoneName: json['zone_name'],
      message: json['message'],
      nextOpeningTime: openingTime,
      deliveryAreas: deliveryAreas,
      extraStopFee: extraStopFee,
      maxStops: maxStops,
      enabledStops: enabledStops,
    );
  }

  bool get isOutsideWorkingHours {
    final String value = (message ?? '').toLowerCase();
    return value.contains('closed') ||
        value.contains('opens at') ||
        value.contains('مغلق') ||
        value.contains('يفتح');
  }

  static String? _openingTimeFromMessage(String message) {
    final RegExpMatch? match = RegExp(
      r'(?:opens?\s+at|يفتح(?:\s+الساعة)?)[\s:]*([0-9]{1,2}(?::[0-9]{2})?:?\s*(?:am|pm)?)',
      caseSensitive: false,
    ).firstMatch(message);
    return match?.group(1)?.replaceAll(': ', ':').trim();
  }
}
