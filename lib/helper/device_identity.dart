import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentity {
  static const String _idKey = 'customer_installation_id';
  static const String _stableIdKey = 'customer_stable_device_id';

  static Future<String> getOrCreate(SharedPreferences preferences) async {
    final stableId = preferences.getString(_stableIdKey);
    if (stableId != null && stableId.isNotEmpty) {
      return stableId;
    }

    final platformId = await _readPlatformId();
    if (platformId != null && platformId.isNotEmpty) {
      final value = '${type}_$platformId';
      await preferences.setString(_stableIdKey, value);
      return value;
    }

    final existing = preferences.getString(_idKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final id = List<String>.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await preferences.setString(_idKey, id);
    return id;
  }

  static Future<String?> _readPlatformId() async {
    try {
      final DeviceInfoPlugin info = DeviceInfoPlugin();
      if (GetPlatform.isAndroid) {
        return await const MethodChannel('com.ammart.shop/device_identity').invokeMethod<String>('androidId');
      }
      if (GetPlatform.isIOS) {
        final IosDeviceInfo ios = await info.iosInfo;
        return ios.identifierForVendor?.trim();
      }
    } catch (_) {}
    return null;
  }

  static Future<String> get model async {
    try {
      final DeviceInfoPlugin info = DeviceInfoPlugin();
      if (GetPlatform.isAndroid) {
        final AndroidDeviceInfo android = await info.androidInfo;
        final brand = android.brand.trim();
        final deviceModel = android.model.trim();
        if (brand.isNotEmpty && deviceModel.isNotEmpty) {
          return '$brand $deviceModel';
        }
        return deviceModel.isNotEmpty ? deviceModel : brand;
      }
      if (GetPlatform.isIOS) {
        final IosDeviceInfo ios = await info.iosInfo;
        return ios.utsname.machine.trim().isNotEmpty
            ? ios.utsname.machine.trim()
            : ios.name.trim();
      }
    } catch (_) {}
    return '';
  }

  static String get type {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    if (GetPlatform.isWeb) return 'web';
    return 'unknown';
  }
}
