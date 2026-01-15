// data/repositories/device_repository_impl.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:she/features/device/data/datasources/ble_datasource.dart';
import 'package:she/features/device/domain/entities/ble_device.dart';
import 'package:she/features/device/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final BleDataSource dataSource;

  DeviceRepositoryImpl(this.dataSource);

  @override
  Future<bool> checkPermission() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) return false;
    }

    return true;
  }

  @override
  Future<bool> isBluetoothOn() async {
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  @override
  Stream<List<BleDevice>> scanDevices() {
    return dataSource.scan();
  }

  @override
  Future<void> stopScan() {
    return dataSource.stopScan();
  }
}
