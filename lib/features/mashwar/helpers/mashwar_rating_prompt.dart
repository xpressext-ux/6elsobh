import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/mashwar/controllers/mashwar_controller.dart';
import 'package:sixam_mart/features/mashwar/domain/models/mashwar_task_model.dart';
import 'package:sixam_mart/features/mashwar/widgets/mashwar_task_rating_dialog.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class MashwarRatingPrompt {
  static bool _dialogOpen = false;

  static bool get isDialogOpen => _dialogOpen;

  static Future<void> checkAndShow({MashwarTaskModel? ride}) async {
    if (!AuthHelper.isLoggedIn() || _dialogOpen) {
      return;
    }
    if (!Get.isRegistered<MashwarController>()) {
      return;
    }

    MashwarTaskModel? target = ride;
    if (target == null) {
      target = await Get.find<MashwarController>().fetchPendingReviewRide();
    }

    if (target == null || target.id == null || !target.needsReview) {
      return;
    }

    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }

    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MashwarTaskRatingDialog(ride: target!),
      );
    } finally {
      _dialogOpen = false;
    }
  }
}
