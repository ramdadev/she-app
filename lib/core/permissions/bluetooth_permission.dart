import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class BluetoothPermission {
  static Future<bool> request() async {
    if (Platform.isAndroid) {
      final permissions = <Permission>[];

      if (await Permission.bluetoothScan.isDenied ||
          await Permission.bluetoothConnect.isDenied) {
        permissions.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ]);
      }

      // Android 11 and below need the location permission for Bluetooth scanning
      permissions.add(Permission.locationWhenInUse);

      final result = await permissions.request();

      return result.values.every((status) => status.isGranted);
    }

    return true;
  }
}
