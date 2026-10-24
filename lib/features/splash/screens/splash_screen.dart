import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? body;
  final String? deeplinkUrl;
  const SplashScreen({
    super.key,
    required this.body,
    required this.deeplinkUrl,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      bool isConnected =
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);

      if (!firstTime) {
        isConnected
            ? ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar()
            : const SizedBox();
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: Duration(seconds: isConnected ? 3 : 6000),
            content: Text(
              isConnected ? 'connected'.tr : 'no_connection'.tr,
              textAlign: TextAlign.center,
            ),
          ),
        );
        if (isConnected) {
          print(
            '=========here coming-----1-->> ${Get.find<SplashController>().deeplinkRoute}',
          );
          if (Get.find<SplashController>().deeplinkRoute == null) {
            Get.find<SplashController>().getConfigData(
              notificationBody: widget.body,
              fromSplash: true,
            );
          }
        }
      }

      firstTime = false;
    });

    Get.find<SplashController>().initSharedData();
    if ((AuthHelper.getGuestId().isNotEmpty || AuthHelper.isLoggedIn()) &&
        Get.find<SplashController>().cacheModule != null) {
      Get.find<CartController>().getAllCarts();
    }
    // _route();
    print(
      '=========here coming-----2-->> ${Get.find<SplashController>().deeplinkRoute == null}',
    );
    if (Get.find<SplashController>().deeplinkRoute == null) {
      Get.find<SplashController>().getConfigData(
        notificationBody: widget.body,
        fromSplash: true,
      );
    }
    _route();
  }

  @override
  void dispose() {
    _onConnectivityChanged?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  void _route() {
    Get.find<SplashController>().getConfigData(
      handleMaintenanceMode: false,
      notificationBody: widget.body,
      fromSplash: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.find<SplashController>().initSharedData();
    if (AddressHelper.getUserAddressFromSharedPref() != null &&
        AddressHelper.getUserAddressFromSharedPref()!.zoneIds == null) {
      Get.find<AuthController>().clearSharedAddress();
    }

    return Scaffold(
      key: _globalKey,
      body: GetBuilder<SplashController>(
        builder: (splashController) {
          if (!splashController.hasConnection) {
            return NoInternetScreen(
              child: SplashScreen(
                body: widget.body,
                deeplinkUrl: widget.deeplinkUrl,
              ),
            );
          }

          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Expanded(
                            child: Image.asset(
                              Images.splashArtwork,
                              width: double.infinity,
                              // Fill the available width and height responsively.
                              // The artwork is centered, so only a small amount
                              // is trimmed from the side edges on taller phones.
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RotationTransition(
                            turns: _loadingController,
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 30,
                              color: Color(0xFF0B5960),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _SplashGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
