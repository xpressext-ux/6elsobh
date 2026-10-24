import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/mashwar/controllers/mashwar_controller.dart';
import 'package:sixam_mart/features/mashwar/screens/mashwar_task_tracking_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MashwarTaskListScreen extends StatefulWidget {
  const MashwarTaskListScreen({super.key});

  @override
  State<MashwarTaskListScreen> createState() => _MashwarTaskListScreenState();
}

class _MashwarTaskListScreenState extends State<MashwarTaskListScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<MashwarController>().fetchRideHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'mashwar_my_tasks'.tr),
      body: GetBuilder<MashwarController>(
        builder: (c) {
          if (c.loading && c.rideHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.rideHistory.isEmpty) {
            return Center(
              child: Text('mashwar_no_tasks'.tr, style: robotoMedium),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            itemCount: c.rideHistory.length,
            itemBuilder: (_, i) {
              final r = c.rideHistory[i];
              return Card(
                child: ListTile(
                  title: Text(r.rideReference ?? ''),
                  subtitle: Text(
                    '${r.deliveryArea?.name ?? r.toArea?.name ?? r.fromArea?.name ?? ''}\n${r.rideStatusLabel ?? r.rideStatus ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Text(r.rideAmount?.formatted ?? ''),
                  onTap: () {
                    if (r.id != null) {
                      Get.to(() => MashwarTaskTrackingScreen(rideId: r.id!));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
