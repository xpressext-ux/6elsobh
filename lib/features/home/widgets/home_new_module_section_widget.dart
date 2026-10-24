import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class HomeNewModuleSectionWidget extends StatefulWidget {
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  const HomeNewModuleSectionWidget({
    super.key,
    this.isExpanded = false,
    this.onExpandedChanged,
  });

  @override
  State<HomeNewModuleSectionWidget> createState() =>
      _HomeNewModuleSectionWidgetState();
}

class _HomeNewModuleSectionWidgetState
    extends State<HomeNewModuleSectionWidget> {
  static const int _collapsedCount = 6;
  static const double _singleCardMaxWidth = 180;
  static const double _gridGap = Dimensions.paddingSizeSmall;

  bool get _isExpanded => widget.isExpanded;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        final List<ModuleModel>? apiModules = splashController.moduleList;

        if (apiModules == null) {
          return const _ModuleSectionShimmer();
        }
        if (apiModules.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Dimensions.paddingSizeLarge,
            ),
            child: Center(
              child: Text('no_module_found'.tr, style: robotoMedium),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: _buildGrid(context, _mapApiModules(apiModules)),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<_ModuleData> modules) {
    final bool canToggle = modules.length > _collapsedCount;
    final List<_ModuleData> visibleModules = !canToggle || _isExpanded
        ? modules
        : modules.sublist(0, _collapsedCount);
    final List<int> rowSizes = _balancedRowSizes(visibleModules.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final List<Widget> rows = <Widget>[];
        final int widestRowSize = rowSizes.reduce(math.max);
        final double availableWidth = constraints.maxWidth;
        final double widestRowWidth =
            availableWidth - (_gridGap * math.max(0, widestRowSize - 1));
        final double cardWidth = widestRowSize == 1
            ? math.min(widestRowWidth, _singleCardMaxWidth)
            : widestRowWidth / widestRowSize;
        int offset = 0;

        for (final int rowSize in rowSizes) {
          final List<_ModuleData> rowModules = visibleModules.sublist(
            offset,
            offset + rowSize,
          );
          offset += rowSize;

          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int index = 0; index < rowModules.length; index++) ...[
                  if (index > 0) const SizedBox(width: _gridGap),
                  SizedBox(
                    width: cardWidth,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _ModuleCard(
                        module: rowModules[index],
                        onTap: () =>
                            Get.find<SplashController>().selectModuleByTabIndex(
                              modules.indexOf(rowModules[index]) + 1,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: _gridGap),
              rows[index],
            ],
            if (canToggle) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              InkWell(
                onTap: () => widget.onExpandedChanged?.call(!_isExpanded),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Text(
                    _isExpanded ? 'see_less'.tr : 'see_more'.tr,
                    style: robotoSemiBold.copyWith(
                      color: Colors.blueAccent,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Splits [count] into the smallest number of rows that can fit four cards,
  /// then distributes the cards evenly. This gives 3+2 for five cards,
  /// 3+3 for six, 4+3 for seven, and never leaves a single-card last row.
  List<int> _balancedRowSizes(int count) {
    if (count <= 0) return const <int>[];
    final int rowCount = (count + 3) ~/ 4;
    final int baseSize = count ~/ rowCount;
    final int remainder = count % rowCount;
    return List<int>.generate(
      rowCount,
      (index) => baseSize + (index < remainder ? 1 : 0),
    );
  }

  List<_ModuleData> _mapApiModules(List<ModuleModel> apiModules) {
    return apiModules
        .map((ModuleModel module) => _ModuleData(iconUrl: module.iconFullUrl))
        .toList();
  }
}

class _ModuleData {
  final String? iconUrl;

  const _ModuleData({required this.iconUrl});
}

class _ModuleCard extends StatelessWidget {
  final _ModuleData module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: module.iconUrl == null || module.iconUrl!.isEmpty
          ? const SizedBox.expand()
          : CustomImage(
              image: module.iconUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: ImageCacheHelper.pixels(
                context,
                MediaQuery.sizeOf(context).width,
              ),
              cacheHeight: ImageCacheHelper.pixels(
                context,
                MediaQuery.sizeOf(context).width,
              ),
            ),
    );
  }
}

class _ModuleSectionShimmer extends StatelessWidget {
  const _ModuleSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 100);
  }
}
