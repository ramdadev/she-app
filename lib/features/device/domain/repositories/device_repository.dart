import 'package:she/features/device/domain/entities/ble_device.dart';

abstract class DeviceRepository {
  Future<bool> checkPermission();
  Future<bool> isBluetoothOn();
  Stream<List<BleDevice>> scanDevices();
  Future<void> stopScan();
}
