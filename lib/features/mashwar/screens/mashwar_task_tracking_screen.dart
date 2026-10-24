import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/mashwar/widgets/mashwar_app_bar_widget.dart';
import 'package:sixam_mart/features/mashwar/widgets/mashwar_task_status_body.dart';

class MashwarTaskTrackingScreen extends StatelessWidget {
  final int rideId;
  const MashwarTaskTrackingScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MashwarAppBarWidget(title: 'mashwar_track_task'.tr),
      body: MashwarTaskStatusBody(
        rideId: rideId,
        showHomeButtonWhenFinished: true,
      ),
    );
  }
}
