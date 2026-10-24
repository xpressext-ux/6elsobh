import 'package:flutter/material.dart';
import 'package:sixam_mart/features/support/services/support_call_notification_service.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MissedSupportCallsScreen extends StatefulWidget {
  const MissedSupportCallsScreen({super.key});

  @override
  State<MissedSupportCallsScreen> createState() =>
      _MissedSupportCallsScreenState();
}

class _MissedSupportCallsScreenState extends State<MissedSupportCallsScreen> {
  late Future<List<SupportMissedCall>> _history;

  @override
  void initState() {
    super.initState();
    _history = SupportCallNotificationService.getMissedCallHistory();
    // Opening the log means the user has seen the missed calls.
    SupportCallNotificationService.markMissedCallsAsRead();
  }

  String _timeLabel(DateTime value) {
    final String hour = value.hour.remainder(12).toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour >= 12 ? 'م' : 'ص';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('سجل المكالمات', style: robotoBold),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SupportMissedCall>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<SupportMissedCall> calls =
              snapshot.data ?? <SupportMissedCall>[];
          if (calls.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_missed_rounded,
                      size: 56,
                      color: colors.outline,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Text('لا توجد مكالمات مسجلة', style: robotoBold),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'ستظهر هنا المكالمات الفائتة والمُجاب عليها والصادرة.',
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(color: colors.outline),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            itemCount: calls.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              final SupportMissedCall call = calls[index];
              final bool outgoing = call.status == 'outgoing';
              final bool answered = call.status == 'answered';
              final Color statusColor = outgoing
                  ? colors.primary
                  : answered
                  ? Colors.green
                  : colors.error;
              return Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        outgoing
                            ? Icons.phone_forwarded_rounded
                            : answered
                            ? Icons.phone_callback_rounded
                            : Icons.phone_missed_rounded,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(call.callerName, style: robotoBold),
                          const SizedBox(height: 3),
                          Text(
                            _timeLabel(call.happenedAt),
                            style: robotoRegular.copyWith(
                              color: colors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _statusLabel(call),
                      style: robotoMedium.copyWith(color: statusColor),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(SupportMissedCall call) {
    final String label = switch (call.status) {
      'answered' => 'تم الرد',
      'outgoing' => 'صادرة',
      _ => 'فائتة',
    };
    return call.count > 1 ? '$label × ${call.count}' : label;
  }
}
