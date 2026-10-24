import 'package:sixam_mart/features/mashwar/domain/models/mashwar_area_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_price_model.dart';

class MashwarLocationModel {
  double? latitude;
  double? longitude;
  String? updatedAt;

  MashwarLocationModel.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'] != null
        ? (json['latitude'] as num).toDouble()
        : null;
    longitude = json['longitude'] != null
        ? (json['longitude'] as num).toDouble()
        : null;
    updatedAt = json['updated_at'];
  }
}

class MashwarDeliveryManModel {
  int? id;
  String? name;
  String? phone;
  String? image;
  MashwarLocationModel? location;

  MashwarDeliveryManModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    image = json['image'];
    location = json['location'] != null
        ? MashwarLocationModel.fromJson(json['location'])
        : null;
  }

  String? get imageFullUrl => image;

  String? get firstName {
    final full = name?.trim();
    if (full == null || full.isEmpty) return null;
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    return parts.sublist(0, parts.length - 1).join(' ');
  }

  String? get lastName {
    final full = name?.trim();
    if (full == null || full.isEmpty) return null;
    final parts = full.split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';
    return parts.last;
  }
}

class MashwarTaskModel {
  int? id;
  String? rideReference;
  int? zoneId;
  String? zoneName;
  MashwarAreaModel? deliveryArea;
  MashwarAreaModel? fromArea;
  MashwarAreaModel? toArea;
  String? description;
  int? stopCount;
  String? pickupNote;
  String? paymentMethod;
  MashwarPriceModel? rideAmount;
  String? rideStatus;
  String? rideStatusLabel;
  double? fromLat;
  double? fromLng;
  String? createdAt;
  String? completedAt;
  String? cancelledAt;
  String? cancelReason;
  bool? isReviewed;
  int? dmRating;
  String? dmReviewComment;
  String? reviewedAt;
  String? imageFullUrl;
  List<String>? attachmentsFullUrl;
  MashwarDeliveryManModel? deliveryMan;

  MashwarTaskModel({
    this.id,
    this.rideReference,
    this.zoneId,
    this.zoneName,
    this.deliveryArea,
    this.fromArea,
    this.toArea,
    this.description,
    this.stopCount,
    this.pickupNote,
    this.paymentMethod,
    this.rideAmount,
    this.rideStatus,
    this.rideStatusLabel,
    this.fromLat,
    this.fromLng,
    this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.isReviewed,
    this.dmRating,
    this.dmReviewComment,
    this.reviewedAt,
    this.imageFullUrl,
    this.attachmentsFullUrl,
    this.deliveryMan,
  });

  MashwarTaskModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rideReference = json['task_reference'] ?? json['ride_reference'];
    zoneId = json['zone_id'];
    zoneName = json['zone_name'];
    deliveryArea = json['delivery_area'] != null
        ? MashwarAreaModel.fromJson(json['delivery_area'])
        : null;
    fromArea = json['from_area'] != null
        ? MashwarAreaModel.fromJson(json['from_area'])
        : null;
    toArea = json['to_area'] != null
        ? MashwarAreaModel.fromJson(json['to_area'])
        : null;
    description = json['description']?.toString();
    stopCount = json['stop_count'] != null
        ? int.tryParse(json['stop_count'].toString())
        : null;
    pickupNote = json['pickup_note'];
    paymentMethod = json['payment_method'];
    final amountJson = json['task_amount'] ?? json['ride_amount'];
    rideAmount = amountJson != null
        ? MashwarPriceModel.fromJson(amountJson)
        : null;
    rideStatus = json['task_status'] ?? json['ride_status'];
    rideStatusLabel = json['task_status_label'] ?? json['ride_status_label'];
    fromLat = _asDouble(json['from_lat']);
    fromLng = _asDouble(json['from_lng']);
    createdAt = json['created_at'];
    completedAt = json['completed_at'];
    cancelledAt = json['cancelled_at'];
    cancelReason =
        (json['cancel_reason'] ??
                json['cancellation_reason'] ??
                json['cancelled_reason'] ??
                json['admin_cancel_reason'] ??
                json['deliveryman_cancel_reason'] ??
                json['reason'])
            ?.toString();
    isReviewed = json['is_reviewed'] == true || json['is_reviewed'] == 1;
    dmRating = json['dm_rating'] != null
        ? (json['dm_rating'] as num).toInt()
        : null;
    dmReviewComment = json['dm_review_comment'];
    reviewedAt = json['reviewed_at'];
    imageFullUrl = json['image_full_url']?.toString();
    if (json['attachments_full_url'] is List) {
      attachmentsFullUrl = (json['attachments_full_url'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (imageFullUrl != null && imageFullUrl!.isNotEmpty) {
      attachmentsFullUrl = [imageFullUrl!];
    }
    deliveryMan = json['delivery_man'] != null
        ? MashwarDeliveryManModel.fromJson(json['delivery_man'])
        : null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  List<String> get attachmentUrls {
    if (attachmentsFullUrl != null && attachmentsFullUrl!.isNotEmpty) {
      return attachmentsFullUrl!;
    }
    if (imageFullUrl != null && imageFullUrl!.isNotEmpty) {
      return [imageFullUrl!];
    }
    return const [];
  }

  /// A task can come from older server records with a slightly different
  /// terminal status spelling. Treat every terminal state as history so an
  /// old Mashwar order cannot remain hidden from the Previous tab.
  bool get isFinished {
    final String status = (rideStatus ?? '').trim().toLowerCase();
    final bool terminalStatus = const <String>{
      'completed',
      'cancelled',
      'canceled',
      'delivered',
      'returned',
      'failed',
      'finished',
      'refunded',
    }.contains(status);
    return terminalStatus ||
        (completedAt?.trim().isNotEmpty ?? false) ||
        (cancelledAt?.trim().isNotEmpty ?? false);
  }

  bool get isCancelled {
    final String status = (rideStatus ?? '').trim().toLowerCase();
    return status == 'cancelled' ||
        status == 'canceled' ||
        ((cancelledAt?.trim().isNotEmpty ?? false) &&
            !(completedAt?.trim().isNotEmpty ?? false));
  }

  bool get canContactActions => hasAssignedDriver && !isFinished;

  bool get isSearchingDriver => rideStatus == 'searching_driver';

  bool get hasAssignedDriver =>
      deliveryMan != null && !isSearchingDriver && !isCancelled;

  bool get showDeliveryManInfo => deliveryMan != null && !isSearchingDriver;

  bool get canCustomerCancel => !isFinished && !hasAssignedDriver;

  bool get needsReview =>
      rideStatus == 'completed' && isReviewed != true && deliveryMan != null;
}
