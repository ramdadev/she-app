import 'package:she/features/device/domain/entities/ble_device.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceModel extends BleDevice {
  BleDeviceModel({
    required super.name,
    required super.address,
    required super.rssi,
  });

  factory BleDeviceModel.fromScanResult(ScanResult r) {
    return BleDeviceModel(
      name: r.device.platformName.isNotEmpty
          ? r.device.platformName
          : 'Unknown Device',
      address: r.device.remoteId.toString(),
      rssi: r.rssi,
    );
  }
}
