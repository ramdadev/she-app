class BleDevice {
  final String name;
  final String address;
  final int rssi;

  BleDevice({required this.name, required this.address, required this.rssi});

  BleDevice copyWith({String? name, String? address, int? rssi}) {
    return BleDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
    );
  }
}
