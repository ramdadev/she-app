// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:she/features/device/domain/entities/bluetooth_device.dart';
import 'package:she/features/device/presentation/widgets/device_card.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool isScanning = false;
  bool isBluetoothEnabled = true;
  String? connectedDevice;

  // Dummy data untuk perangkat yang ditemukan
  List<BluetoothDevice> availableDevices = [];
  List<BluetoothDevice> pairedDevices = [
    BluetoothDevice(name: 'ESP32-IOT', address: '30:AE:A4:07:0D:64', rssi: -45),
  ];

  void startScanning() {
    setState(() {
      isScanning = true;
      availableDevices.clear();
    });

    // Simulasi pencarian perangkat
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          availableDevices = [
            BluetoothDevice(
              name: 'ESP32-Kitchen',
              address: '30:AE:A4:07:0D:66',
              rssi: -55,
            ),
            BluetoothDevice(
              name: 'ESP32-Garage',
              address: '30:AE:A4:07:0D:67',
              rssi: -72,
            ),
            BluetoothDevice(
              name: 'ESP32-Garden',
              address: '30:AE:A4:07:0D:68',
              rssi: -80,
            ),
          ];
          isScanning = false;
        });
      }
    });
  }

  void connectToDevice(BluetoothDevice device) {
    setState(() {
      connectedDevice = device.name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terhubung ke ${device.name}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void disconnectDevice() {
    setState(() {
      connectedDevice = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perangkat terputus'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        title: const Text(
          'Perangkat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header dengan status Bluetooth
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  // Status Bluetooth
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: Colors.blue[700],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Bluetooth',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBluetoothEnabled ? 'Aktif' : 'Nonaktif',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isBluetoothEnabled,
                          onChanged: (value) {
                            setState(() {
                              isBluetoothEnabled = value;
                            });
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Connected Device Card
          if (connectedDevice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terhubung',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            connectedDevice!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: disconnectDevice,
                    ),
                  ],
                ),
              ),
            ),

          if (connectedDevice != null) const SizedBox(height: 20),

          // Scan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBluetoothEnabled && !isScanning
                    ? startScanning
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                icon: Icon(isScanning ? Icons.refresh : Icons.search),
                label: Text(
                  isScanning ? 'Mencari Perangkat...' : 'Cari Perangkat',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Device List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Paired Devices
                if (pairedDevices.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.link, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Perangkat Tersimpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...pairedDevices.map(
                    (device) => DeviceCard(
                      device: device,
                      isPaired: true,
                      isConnected: connectedDevice == device.name,
                      onTap: () => connectToDevice(device),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Available Devices
                if (availableDevices.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.devices, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Perangkat Tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...availableDevices.map(
                    (device) => DeviceCard(
                      device: device,
                      isPaired: false,
                      isConnected: false,
                      onTap: () => connectToDevice(device),
                    ),
                  ),
                ],

                // Empty State
                if (availableDevices.isEmpty && !isScanning)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada perangkat ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tekan tombol "Cari Perangkat" untuk memulai',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
