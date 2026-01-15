import 'package:equatable/equatable.dart';

class BleDevice extends Equatable {
  final String name;
  final String address;
  final int rssi;

  const BleDevice({
    required this.name,
    required this.address,
    required this.rssi,
  });

  @override
  List<Object> get props => [name, address, rssi];
}
