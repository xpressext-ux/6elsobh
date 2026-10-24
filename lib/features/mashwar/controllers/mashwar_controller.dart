import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_area_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_bootstrap_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_price_model.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_task_model.dart';
import 'package:sixam_mart/features/mashwar/domain/repositories/mashwar_repository.dart';
import 'package:sixam_mart/features/mashwar/helpers/mashwar_rating_prompt.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class MashwarController extends GetxController implements GetxService {
  static const formUpdateId = 'mashwar_form';

  final MashwarRepository mashwarRepository;
  MashwarController({required this.mashwarRepository});

  void _refreshForm() => update([formUpdateId]);

  bool _loading = false;
  bool get loading => _loading;

  bool _bootstrapping = false;
  bool get bootstrapping => _bootstrapping;

  bool _submittingRide = false;
  bool get submittingRide => _submittingRide;

  MashwarBootstrapModel? _bootstrap;
  MashwarBootstrapModel? get bootstrap => _bootstrap;

  MashwarAreaModel? _selectedArea;
  MashwarAreaModel? get selectedArea => _selectedArea;

  int _stopCount = 1;
  int get stopCount => _stopCount;

  MashwarPriceModel? _fare;
  MashwarPriceModel? get fare => _fare;

  String _description = '';
  String get description => _description;

  String _pickupNote = '';
  String get pickupNote => _pickupNote;

  XFile? _taskImage;
  XFile? get taskImage => _taskImage;

  FilePickerResult? _taskAttachment;
  FilePickerResult? get taskAttachment => _taskAttachment;

  String? get taskAttachmentName =>
      _taskImage?.name ?? _taskAttachment?.files.single.name;

  MashwarTaskModel? _activeRide;
  MashwarTaskModel? get activeRide => _activeRide;

  bool get hasOngoingRide => _activeRide != null && !_activeRide!.isFinished;

  bool _checkingActiveRide = false;
  bool get checkingActiveRide => _checkingActiveRide;

  bool _submittingReview = false;
  bool get submittingReview => _submittingReview;

  MashwarTaskModel? _pendingReviewRide;
  MashwarTaskModel? get pendingReviewRide => _pendingReviewRide;

  List<MashwarTaskModel> _rideHistory = [];
  List<MashwarTaskModel> get rideHistory => _rideHistory;
  bool _historyLoaded = false;
  bool get historyLoaded => _historyLoaded;

  bool _liveUpdatesActive = false;

  List<int> get enabledStops => _bootstrap?.enabledStops ?? const [1, 2];

  void startLiveUpdates() {
    if (_liveUpdatesActive) return;
    _liveUpdatesActive = true;
    loadBootstrap(silent: _bootstrap != null);
    if (AuthHelper.isLoggedIn()) {
      fetchActiveRide(silent: true);
      fetchPendingReviewRide().then((_) {
        MashwarRatingPrompt.checkAndShow();
      });
    }
  }

  void stopLiveUpdates() {
    _liveUpdatesActive = false;
  }

  void setDescription(String v) => _description = v;

  void setPickupNote(String v) => _pickupNote = v;

  void setStopCount(int count) {
    final allowed = enabledStops;
    if (!allowed.contains(count)) {
      return;
    }
    _stopCount = count;
    _refreshForm();
    if (_selectedArea?.id != null) {
      loadFare();
    }
  }

  void _syncStopCountWithBootstrap() {
    final allowed = enabledStops;
    if (allowed.isEmpty) {
      _stopCount = 1;
      return;
    }
    if (!allowed.contains(_stopCount)) {
      _stopCount = allowed.first;
    }
  }

  Future<void> pickTaskImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) {
      _taskImage = file;
      _taskAttachment = null;
      _refreshForm();
    }
  }

  Future<void> pickTaskAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'pdf',
        'doc',
        'docx',
      ],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;
      if (picked.path != null || picked.bytes != null) {
        _taskAttachment = result;
        _taskImage = null;
        _refreshForm();
      }
    }
  }

  void clearTaskImage() {
    _taskImage = null;
    _taskAttachment = null;
    _refreshForm();
  }

  void resetOnModuleExit() {
    stopLiveUpdates();
    _loading = false;
    _bootstrapping = false;
    _submittingRide = false;
    _bootstrap = null;
    _selectedArea = null;
    _stopCount = 1;
    _fare = null;
    _description = '';
    _pickupNote = '';
    _taskImage = null;
    _taskAttachment = null;
    _refreshForm();
  }

  Future<void> loadBootstrap({bool silent = false}) async {
    _bootstrapping = true;
    if (!silent) {
      _refreshForm();
    }

    final response = await mashwarRepository.bootstrap();
    if (response.statusCode == 200 && response.body is Map) {
      _bootstrap = MashwarBootstrapModel.fromJson(response.body);
      _syncStopCountWithBootstrap();
      if (_selectedArea?.id != null) {
        final areas = _bootstrap?.deliveryAreas ?? [];
        final stillValid = areas.any((a) => a.id == _selectedArea?.id);
        if (!stillValid) {
          _selectedArea = null;
          _fare = null;
        } else if (_fare == null) {
          loadFare();
        }
      }
    } else if (_bootstrap == null) {
      final body = response.body;
      final msg = body is Map && body['message'] != null
          ? body['message'].toString()
          : (response.statusText ?? 'تعذر تحميل ابعت مشوار');
      showCustomSnackBar(msg);
    }

    _bootstrapping = false;
    _refreshForm();
  }

  Future<void> selectArea(MashwarAreaModel? area) async {
    _selectedArea = area;
    _fare = null;
    _refreshForm();
    if (area?.id != null) {
      await loadFare();
    }
  }

  Future<void> loadFare() async {
    if (_bootstrap?.zoneId == null || _selectedArea?.id == null) return;

    final response = await mashwarRepository.fare(
      _bootstrap!.zoneId!,
      _selectedArea!.id!,
      _stopCount,
    );

    final body = response.body;
    if (response.statusCode == 200 &&
        body is Map &&
        body['found'] == true &&
        body['price'] != null) {
      _fare = MashwarPriceModel.fromJson(
        Map<String, dynamic>.from(body['price']),
      );
    } else {
      _fare = null;
      final msg = body is Map && body['message'] != null
          ? body['message'].toString()
          : 'لا يوجد سعر لهذه المنطقة';
      showCustomSnackBar(msg);
    }
    _refreshForm();
  }

  Future<bool> placeRide() async {
    if (_submittingRide) {
      return false;
    }
    if (!AuthHelper.isLoggedIn()) {
      Get.toNamed(RouteHelper.getSignInRoute('mashwar'));
      return false;
    }
    if (_description.trim().isEmpty) {
      showCustomSnackBar('اكتب تفاصيل المشوار');
      return false;
    }
    if (_selectedArea?.id == null || _fare == null) {
      showCustomSnackBar('اختر منطقة التوصيل');
      return false;
    }
    if (!enabledStops.contains(_stopCount)) {
      showCustomSnackBar('عدد المحطات غير متاح');
      return false;
    }
    if (hasOngoingRide) {
      showCustomSnackBar('لديك مشوار جارٍ — تابع حالته أدناه');
      return false;
    }

    _submittingRide = true;
    _refreshForm();

    await fetchActiveRide(silent: true);
    if (hasOngoingRide) {
      _submittingRide = false;
      _refreshForm();
      showCustomSnackBar('لديك مشوار جارٍ — تابع حالته أدناه');
      return false;
    }

    final body = <String, dynamic>{
      'zone_id': _bootstrap!.zoneId,
      'delivery_area_id': _selectedArea!.id,
      'stop_count': _stopCount,
      'description': _description.trim(),
      'pickup_note': _pickupNote,
      'payment_method': 'cash_on_delivery',
    };

    final response = await mashwarRepository.placeRide(
      body,
      image: _taskImage,
      attachment: _taskAttachment,
    );
    _submittingRide = false;
    _refreshForm();

    if (response.statusCode == 200 && response.body['ride'] != null) {
      _activeRide = MashwarTaskModel.fromJson(response.body['ride']);
      showCustomSnackBar(
        response.body['message'] ?? 'تم الطلب',
        isError: false,
      );
      return true;
    }
    showCustomSnackBar(response.statusText ?? 'فشل إنشاء المشوار');
    return false;
  }

  Future<void> fetchRideDetails(int rideId) async {
    final response = await mashwarRepository.getRideDetails(rideId);
    if (response.statusCode == 200 && response.body['ride'] != null) {
      _activeRide = MashwarTaskModel.fromJson(response.body['ride']);
      update();
    }
  }

  Future<void> fetchActiveRide({bool silent = false}) async {
    if (!AuthHelper.isLoggedIn()) {
      _checkingActiveRide = false;
      return;
    }
    if (!silent) {
      _checkingActiveRide = true;
      _refreshForm();
    }

    final response = await mashwarRepository.getActiveRide();
    _checkingActiveRide = false;

    if (response.statusCode == 200 && response.body is Map) {
      final rideJson = response.body['ride'];
      if (rideJson != null) {
        _activeRide = MashwarTaskModel.fromJson(
          Map<String, dynamic>.from(rideJson),
        );
      } else {
        _activeRide = null;
      }
    }

    _refreshForm();
    update();
  }

  void clearFinishedActiveRide() {
    if (_activeRide?.isFinished == true) {
      _activeRide = null;
      update();
    }
  }

  Future<void> fetchRideHistory() async {
    if (!AuthHelper.isLoggedIn()) return;
    _loading = true;
    _historyLoaded = false;
    update();

    // The active ride is returned by a separate endpoint and is not guaranteed
    // to be included in the customer ride-list response. Load it first so the
    // current ride can appear in the "all" and "current" order filters too.
    await fetchActiveRide(silent: true);

    final response = await mashwarRepository.getRideList();
    _loading = false;
    final dynamic body = response.body;
    if (response.statusCode == 200) {
      // Deployments have returned the collection under different keys
      // (`rides`, `tasks`, `items`, or nested `data`). Accept all of them so a
      // server response shape change cannot silently empty the order screen.
      final dynamic rides;
      if (body is List) {
        rides = body;
      } else if (body is Map) {
        final dynamic data = body['data'];
        final dynamic nestedData = data is Map ? data['data'] : null;
        rides =
            body['rides'] ??
            body['tasks'] ??
            body['items'] ??
            body['results'] ??
            (data is Map
                ? data['rides'] ??
                      data['tasks'] ??
                      data['items'] ??
                      data['results'] ??
                      nestedData
                : data);
      } else {
        rides = null;
      }
      if (rides is List) {
        _rideHistory = rides
            .whereType<Map>()
            .map((v) => MashwarTaskModel.fromJson(Map<String, dynamic>.from(v)))
            .toList();
      }
    }

    // Keep the active ride visible even when the list endpoint intentionally
    // returns completed rides only. Avoid adding it twice if the API included
    // it in the list response already.
    final MashwarTaskModel? active = _activeRide;
    if (active?.id != null &&
        !_rideHistory.any((ride) => ride.id == active!.id)) {
      _rideHistory.insert(0, active!);
    }

    _historyLoaded = true;
    update();
  }

  Future<bool> cancelActiveRide({String? reason}) async {
    if (_activeRide?.id == null) return false;
    if (!_activeRide!.canCustomerCancel) {
      showCustomSnackBar('لا يمكن إلغاء المشوار بعد تعيين مندوب');
      return false;
    }
    final response = await mashwarRepository.cancelRide(
      _activeRide!.id!,
      reason: reason,
    );
    if (response.statusCode == 200) {
      await fetchRideDetails(_activeRide!.id!);
      return true;
    }
    final body = response.body;
    final msg =
        body is Map &&
            body['errors'] is List &&
            (body['errors'] as List).isNotEmpty
        ? body['errors'][0]['message']?.toString()
        : (body is Map ? body['message']?.toString() : null);
    showCustomSnackBar(msg ?? response.statusText ?? 'تعذر الإلغاء');
    return false;
  }

  Future<MashwarTaskModel?> fetchPendingReviewRide() async {
    if (!AuthHelper.isLoggedIn()) {
      _pendingReviewRide = null;
      return null;
    }
    final response = await mashwarRepository.getPendingReviewRide();
    if (response.statusCode == 200 && response.body is Map) {
      final rideJson = response.body['ride'];
      if (rideJson != null) {
        _pendingReviewRide = MashwarTaskModel.fromJson(
          Map<String, dynamic>.from(rideJson),
        );
        return _pendingReviewRide;
      }
    }
    _pendingReviewRide = null;
    return null;
  }

  Future<bool> submitRideReview({
    required int rideId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      showCustomSnackBar('give_a_rating'.tr);
      return false;
    }
    _submittingReview = true;
    update();

    final response = await mashwarRepository.submitRideReview(
      rideId,
      rating: rating,
      comment: comment,
    );

    _submittingReview = false;

    if (response.statusCode == 200 &&
        response.body is Map &&
        response.body['ride'] != null) {
      final reviewed = MashwarTaskModel.fromJson(
        Map<String, dynamic>.from(response.body['ride']),
      );
      if (_activeRide?.id == rideId) {
        _activeRide = reviewed;
      }
      _pendingReviewRide = null;
      showCustomSnackBar(
        response.body['message']?.toString() ?? 'تم إرسال التقييم',
        isError: false,
      );
      update();
      return true;
    }

    final body = response.body;
    final msg = body is Map && body['errors'] != null
        ? body['errors'][0]['message']?.toString()
        : (response.statusText ?? 'تعذر إرسال التقييم');
    showCustomSnackBar(msg ?? 'تعذر إرسال التقييم');
    update();
    return false;
  }
}
