import 'dart:async';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_status_bar_tint.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/support/widgets/global_support_overlay.dart';
import 'package:sixam_mart/features/support/services/support_call_notification_service.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/keyboard_dismiss_route_observer.dart';
import 'package:sixam_mart/helper/language_loader.dart';
import 'package:sixam_mart/helper/link_converter_helper.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/dark_theme.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/messages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/cookies_view.dart';
import 'helper/get_di.dart' as di;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_web_plugins/url_strategy.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupportCallPlatform();

  if (kIsWeb) {
    usePathUrlStrategy();
  }
  /*///Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };


  ///Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };*/

  if (GetPlatform.isWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD0Z911mOoWCVkeGdjhIKwWFPRgvd6ZyAw",
        authDomain: "stackmart-500c7.firebaseapp.com",
        projectId: "stackmart-500c7",
        storageBucket: "stackmart-500c7.appspot.com",
        messagingSenderId: "491987943015",
        appId: "1:491987943015:web:d8bc7ab8dbc9991c8f1ec2",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  Map<String, Map<String, String>> languages = await di.init();

  NotificationBodyModel? body;
  Map<String, dynamic>? initialSupportCallData;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage? remoteMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (remoteMessage != null) {
        final bool isIncomingSupportCall =
            remoteMessage.data['type'] == 'secure_customer_incoming_call';
        final bool isVoiceCall = isIncomingSupportCall
            ? true
            : await handleSupportVoicePushData(remoteMessage.data);
        if (!isVoiceCall) {
          body = NotificationHelper.convertNotification(remoteMessage.data);
        }
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      try {
        final NotificationAppLaunchDetails? launchDetails =
            await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails();
        final String? payload = launchDetails?.notificationResponse?.payload;
        if (launchDetails?.didNotificationLaunchApp == true &&
            payload != null &&
            payload.startsWith('support_call:')) {
          // Incoming support-call surfaces are disabled in the customer app.
        }
      } catch (_) {}
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  } catch (_) {}

  if (ResponsiveHelper.isWeb()) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "380903914182154",
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }

  runApp(
    MyApp(
      languages: languages,
      body: body,
      initialSupportCallData: initialSupportCallData,
    ),
  );
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  final Map<String, dynamic>? initialSupportCallData;
  const MyApp({
    super.key,
    required this.languages,
    required this.body,
    this.initialSupportCallData,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  String? deeplinkRoute;
  String? _initialRoute;
  final ValueNotifier<String> _currentRoute = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();

    if (!GetPlatform.isWeb) {
      _initAppLinks();
    }

    _route();

    _initialRoute = GetPlatform.isWeb
        ? RouteHelper.getInitialRoute()
        : RouteHelper.getSplashRoute(widget.body, deeplinkRoute);
    _currentRoute.value = _initialRoute ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(SupportCallNotificationService.instance.attach());
      final data = widget.initialSupportCallData;
      if (data != null) {
        unawaited(handleSupportVoicePushData(data));
      }
      unawaited(LanguageLoader.loadRemaining());
    });
  }

  @override
  void dispose() {
    unawaited(SupportCallNotificationService.instance.dispose());
    _currentRoute.dispose();
    super.dispose();
  }

  void _initAppLinks() async {
    _appLinks = AppLinks();

    // Listen for any subsequent incoming links
    _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          if (kDebugMode) {
            print(
              '=======Received URI: $uri and previous deeplinkRoute: ${Get.find<SplashController>().deeplinkRoute}',
            );
          }
          LinkConverter.convertDeepLink(uri);
        }
      },
      onError: (err) {
        if (kDebugMode) {
          print('catch Error in initAppLinksStream: $err');
        }
      },
    );
  }

  void _route() async {
    if (GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
      if (AddressHelper.getUserAddressFromSharedPref() != null &&
          AddressHelper.getUserAddressFromSharedPref()!.zoneIds == null) {
        Get.find<AuthController>().clearSharedAddress();
      }

      if (!AuthHelper.isLoggedIn() && !AuthHelper.isGuestLoggedIn()) {
        await Get.find<AuthController>().guestLogin();
      }

      if ((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) &&
          Get.find<SplashController>().cacheModule != null) {
        Get.find<CartController>().getAllCarts();
      }

      Get.find<SplashController>().getConfigData(
        loadLandingData:
            (GetPlatform.isWeb &&
            AddressHelper.getUserAddressFromSharedPref() == null),
        fromMainFunction: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetBuilder<LocalizationController>(
          builder: (localizeController) {
            return GetBuilder<SplashController>(
              builder: (splashController) {
                return (GetPlatform.isWeb &&
                        splashController.configModel == null)
                    ? const SizedBox()
                    : GetMaterialApp(
                        title: AppConstants.appName,
                        debugShowCheckedModeBanner: false,
                        navigatorKey: Get.key,
                        scrollBehavior: const MaterialScrollBehavior().copyWith(
                          dragDevices: {
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.touch,
                          },
                        ),
                        theme: themeController.darkTheme ? dark() : light(),
                        locale: localizeController.locale,
                        translations: Messages(languages: widget.languages),
                        fallbackLocale: Locale(
                          AppConstants.languages[0].languageCode!,
                          AppConstants.languages[0].countryCode,
                        ),
                        initialRoute: _initialRoute,
                        getPages: RouteHelper.routes,
                        navigatorObservers: [KeyboardDismissRouteObserver()],
                        routingCallback: (routing) {
                          HomeStatusBarTint.modalOpen.value =
                              routing != null &&
                              ((routing.isBottomSheet ?? false) ||
                                  (routing.isDialog ?? false));
                          if (routing != null &&
                              !(routing.isBottomSheet ?? false) &&
                              !(routing.isDialog ?? false)) {
                            _currentRoute.value = routing.current;
                          }
                          if (routing == null ||
                              (routing.isBottomSheet ?? false) ||
                              (routing.isDialog ?? false))
                            return;
                          if (Get.isRegistered<ProController>()) {
                            Get.find<ProController>().maybeShowRenewOnRoute(
                              routing.current,
                            );
                          }
                        },
                        defaultTransition: GetPlatform.isWeb
                            ? Transition.fadeIn
                            : Transition.topLevel,
                        transitionDuration: const Duration(milliseconds: 700),
                        builder: (BuildContext context, widget) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(textScaler: const TextScaler.linear(1)),
                            child: Material(
                              child: SafeArea(
                                top: false,
                                bottom: GetPlatform.isAndroid,
                                child: Stack(
                                  children: [
                                    widget!,

                                    ValueListenableBuilder<String>(
                                      valueListenable: _currentRoute,
                                      builder: (context, route, child) {
                                        final bool isMapRoute =
                                            route == '/MapScreen' ||
                                            route.startsWith(
                                              RouteHelper.pickMap,
                                            ) ||
                                            route.startsWith(RouteHelper.map) ||
                                            route.startsWith(
                                              RouteHelper.parcelLocation,
                                            ) ||
                                            route.startsWith(
                                              RouteHelper.rideMap,
                                            ) ||
                                            route.startsWith(
                                              RouteHelper.orderTracking,
                                            );
                                        final bool isModuleDashboard =
                                            route == RouteHelper.initial ||
                                            route.startsWith(RouteHelper.main);
                                        return ValueListenableBuilder<bool>(
                                          valueListenable:
                                              HomeStatusBarTint.modalOpen,
                                          builder: (context, modalOpen, child) {
                                            return GlobalSupportOverlay(
                                              isVisible:
                                                  !modalOpen &&
                                                  isModuleDashboard &&
                                                  !isMapRoute &&
                                                  !route.startsWith(
                                                    RouteHelper.orderDetails,
                                                  ) &&
                                                  !route.startsWith(
                                                    RouteHelper.support,
                                                  ) &&
                                                  !route.startsWith(
                                                    RouteHelper.messages,
                                                  ) &&
                                                  !route.startsWith(
                                                    RouteHelper.conversation,
                                                  ),
                                            );
                                          },
                                        );
                                      },
                                    ),

                                    GetBuilder<SplashController>(
                                      builder: (splashController) {
                                        if (!splashController
                                                .savedCookiesData &&
                                            !splashController
                                                .getAcceptCookiesStatus(
                                                  splashController
                                                              .configModel !=
                                                          null
                                                      ? splashController
                                                            .configModel!
                                                            .cookiesText!
                                                      : '',
                                                )) {
                                          return ResponsiveHelper.isWeb()
                                              ? const Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: CookiesView(),
                                                )
                                              : const SizedBox();
                                        } else {
                                          return const SizedBox();
                                        }
                                      },
                                    ),

                                    // Keeps the home dashboard status-bar tint stable above modal
                                    // barriers (bottom sheets / dialogs). Inert unless the home tab
                                    // is the visible, uncovered page.
                                    const HomeStatusBarTintOverlay(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            );
          },
        );
      },
    );
  }
}
