import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class MashwarRepository {
  final ApiClient apiClient;
  MashwarRepository({required this.apiClient});

  Future<Response> bootstrap() async {
    return apiClient.getData('${AppConstants.mashwarBootstrapUri}?manual=1');
  }

  Future<Response> fare(int zoneId, int areaId, int stopCount) async {
    return apiClient.getData(
      '${AppConstants.mashwarFareUri}?zone_id=$zoneId&delivery_area_id=$areaId&stop_count=$stopCount',
    );
  }

  Future<Response> placeRide(
    Map<String, dynamic> body, {
    XFile? image,
    FilePickerResult? attachment,
  }) async {
    if (image != null || attachment != null) {
      final formBody = <String, String>{
        for (final entry in body.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
      };
      return apiClient.postMultipartData(
        AppConstants.mashwarPlaceRideUri,
        formBody,
        image != null ? [MultipartBody('image', image)] : [],
        multipartDoc: attachment != null
            ? [MultipartDocument('image', attachment)]
            : null,
        handleError: false,
      );
    }
    return apiClient.postData(AppConstants.mashwarPlaceRideUri, body);
  }

  Future<Response> getRideDetails(int rideId) async {
    return apiClient.getData('${AppConstants.mashwarTasksUri}/$rideId');
  }

  // The order screen uses this list for both current and previous filters.
  // Request the server maximum so older Mashwar tasks are not silently left
  // outside the locally filtered history list.
  Future<Response> getRideList({int limit = 50}) async {
    return apiClient.getData('${AppConstants.mashwarTasksUri}?limit=$limit');
  }

  Future<Response> getActiveRide() async {
    return apiClient.getData(AppConstants.mashwarActiveRideUri);
  }

  Future<Response> getPendingReviewRide() async {
    return apiClient.getData(AppConstants.mashwarReviewPendingUri);
  }

  Future<Response> submitRideReview(
    int rideId, {
    required int rating,
    String? comment,
  }) async {
    return apiClient.postData(
      '${AppConstants.mashwarTasksUri}/$rideId/review',
      {'rating': rating, 'comment': comment ?? ''},
    );
  }

  Future<Response> cancelRide(int rideId, {String? reason}) async {
    return apiClient.postData(
      '${AppConstants.mashwarTasksUri}/$rideId/cancel',
      {'cancel_reason': reason ?? ''},
    );
  }
}
