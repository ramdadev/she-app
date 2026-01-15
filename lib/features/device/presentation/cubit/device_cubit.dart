// presentation/cubit/device_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:she/features/device/domain/entities/ble_device.dart';
import 'package:she/features/device/domain/repositories/device_repository.dart';

part 'device_state.dart';

class DeviceCubit extends Cubit<DeviceState> {
  final DeviceRepository repository;

  StreamSubscription? _scanSub;

  DeviceCubit(this.repository) : super(DeviceInitial());

  Future<void> init() async {
    final permissionGranted = await repository.checkPermission();
    if (!permissionGranted) {
      emit(const DeviceError('Izin Bluetooth ditolak'));

      return;
    }

    final bluetoothOn = await repository.isBluetoothOn();
    if (!bluetoothOn) {
      emit(const DeviceError('Bluetooth tidak aktif'));

      return;
    }

    emit(
      const DeviceLoaded(
        pairedDevices: [],
        availableDevices: [],
        connectedDevice: null,
        isBluetoothEnabled: true,
      ),
    );
  }

  void startScan() async {
    emit(DeviceScanning());

    _scanSub?.cancel();
    _scanSub = repository.scanDevices().listen((devices) {
      emit(
        DeviceLoaded(
          pairedDevices: const [], // nanti bisa diisi dari storage
          availableDevices: devices,
          connectedDevice: null,
          isBluetoothEnabled: true,
        ),
      );
    });
  }

  Future<void> stopScan() async {
    await repository.stopScan();
    await _scanSub?.cancel();
  }

  void connect(BleDevice device) {
    if (state is DeviceLoaded) {
      final current = state as DeviceLoaded;
      emit(current.copyWith(connectedDevice: device));
    }
  }

  @override
  Future<void> close() {
    _scanSub?.cancel();
    return super.close();
  }
}

extension on DeviceLoaded {
  DeviceLoaded copyWith({
    List<BleDevice>? pairedDevices,
    List<BleDevice>? availableDevices,
    BleDevice? connectedDevice,
    bool? isBluetoothEnabled,
  }) {
    return DeviceLoaded(
      pairedDevices: pairedDevices ?? this.pairedDevices,
      availableDevices: availableDevices ?? this.availableDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
    );
  }
}
