part of 'device_cubit.dart';

sealed class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

final class DeviceInitial extends DeviceState {}

final class DeviceScanning extends DeviceState {}

final class DeviceLoaded extends DeviceState {
  final List<BleDevice> pairedDevices;
  final List<BleDevice> availableDevices;
  final BleDevice? connectedDevice;
  final bool isBluetoothEnabled;

  const DeviceLoaded({
    required this.pairedDevices,
    required this.availableDevices,
    required this.connectedDevice,
    required this.isBluetoothEnabled,
  });

  @override
  List<Object?> get props => [
    pairedDevices,
    availableDevices,
    connectedDevice,
    isBluetoothEnabled,
  ];
}

final class DeviceError extends DeviceState {
  final String message;

  const DeviceError(this.message);

  @override
  List<Object> get props => [message];
}
