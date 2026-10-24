import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/support/widgets/web_help_support_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/support/widgets/support_button_widget.dart';
import 'package:sixam_mart/features/support/widgets/support_help_floating_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _supportImagePrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_supportImagePrecached) {
      _supportImagePrecached = true;
      precacheImage(
        const AssetImage('assets/image/support_headset_new.png'),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'help_support'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SingleChildScrollView(
        padding: ResponsiveHelper.isDesktop(context)
            ? EdgeInsets.zero
            : const EdgeInsets.all(Dimensions.paddingSizeSmall),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: FooterView(
            child: ResponsiveHelper.isDesktop(context)
                ? const SizedBox(
                    width: double.infinity,
                    height: 650,
                    child: WebSupportScreen(),
                  )
                : SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: Column(
                      children: [
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusExtraLarge,
                          ),
                          child: Image.asset(
                            'assets/image/support_headset_new.png',
                            width: 170,
                            height: 170,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        SupportButtonWidget(
                          icon: Icons.location_on,
                          title: 'address'.tr,
                          color: Colors.blue,
                          info:
                              Get.find<SplashController>().configModel!.address,
                          onTap: () {},
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        SupportButtonWidget(
                          icon: Icons.mail_outline,
                          title: 'email_us'.tr,
                          color: Colors.green,
                          info: Get.find<SplashController>().configModel!.email,
                          onTap: () {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: Get.find<SplashController>()
                                  .configModel!
                                  .email,
                            );
                            launchUrlString(emailLaunchUri.toString());
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        _buildCallButton(context),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Get.bottomSheet<void>(
            const SupportHelpSheet(),
            isScrollControlled: true,
            backgroundColor: colors.surface.withValues(alpha: 0),
          );
        },
        icon: const Icon(Icons.support_agent_rounded),
        label: Text('call_us_free_now'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
      ),
    );
  }
}
