import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:she/features/device/domain/entities/ble_device.dart';

class BleDataSource {
  Stream<List<BleDevice>> scan() async* {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    await for (final results in FlutterBluePlus.scanResults) {
      yield results
          .map(
            (r) => BleDevice(
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'Unknown',
              address: r.device.remoteId.str,
              rssi: r.rssi,
            ),
          )
          .toList();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
}
