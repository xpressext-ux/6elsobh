import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class MashwarAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showModuleSwitch;

  const MashwarAppBarWidget({
    super.key,
    this.title = 'mashwar_title',
    this.showModuleSwitch = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Theme.of(context).cardColor,
      elevation: 2,
      shadowColor: Theme.of(context).disabledColor.withValues(alpha: 0.5),
      title: GetBuilder<SplashController>(
        builder: (splashController) {
          final canSwitchModule =
              showModuleSwitch &&
              splashController.module != null &&
              splashController.configModel!.module == null &&
              splashController.moduleList != null &&
              splashController.moduleList!.length != 1;

          return Row(
            children: [
              if (canSwitchModule)
                InkWell(
                  onTap: () => splashController.removeModule(),
                  child: Image.asset(
                    Images.moduleIcon,
                    height: 25,
                    width: 25,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                )
              else
                const SizedBox(width: 25),
              SizedBox(
                width: canSwitchModule ? Dimensions.paddingSizeSmall : 0,
              ),
              Expanded(
                child: Text(
                  title.tr,
                  textAlign: TextAlign.center,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                child: GetBuilder<NotificationController>(
                  builder: (notificationController) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          CupertinoIcons.bell,
                          size: 25,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                        if (notificationController.hasNotification)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 1,
                                  color: Theme.of(context).cardColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size(Get.width, GetPlatform.isDesktop ? 100 : 50);
}
