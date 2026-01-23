// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:she/core/permissions/bluetooth_permission.dart';
import 'dart:convert';

// Project imports:
import 'package:she/models/ble_device.dart';
import 'package:she/widgets/device_card.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool isScanning = false;
  bool isBluetoothEnabled = false;
  BluetoothDevice? connectedDevice;

  List<BleDevice> availableDevices = [];
  List<BleDevice> pairedDevices = [];
  final Map<String, BleDevice> _scanMap = {};

  late SharedPreferences prefs;
  static const String pairedDevicesKey = 'paired_devices';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    prefs = await SharedPreferences.getInstance();
    _loadPairedDevices();
    await _checkBluetoothStatus();
    _listenToBluetoothState();
    _listenToConnectionState();
  }

  void _listenToBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          isBluetoothEnabled = state == BluetoothAdapterState.on;
        });
      }
    });
  }

  void _listenToConnectionState() {
    final devices = FlutterBluePlus.connectedDevices;

    for (var device in devices) {
      device.connectionState.listen((state) {
        if (!mounted) return;

        if (state == BluetoothConnectionState.connected) {
          setState(() {
            connectedDevice = device;
          });
        } else if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            if (connectedDevice?.remoteId == device.remoteId) {
              connectedDevice = null;
            }
          });
        }
      });
    }
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (mounted) {
        setState(() {
          isBluetoothEnabled = state == BluetoothAdapterState.on;
        });
      }
    } catch (e) {
      debugPrint('Error checking Bluetooth status: $e');
    }
  }

  void _loadPairedDevices() {
    try {
      final pairedData = prefs.getStringList(pairedDevicesKey) ?? [];
      setState(() {
        pairedDevices = pairedData.map((data) {
          final json = jsonDecode(data);
          return BleDevice(
            name: json['name'] ?? 'Unknown',
            address: json['address'] ?? '',
            rssi: json['rssi'] ?? 0,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading paired devices: $e');
    }
  }

  Future<void> _savePairedDevice(BleDevice device) async {
    try {
      final pairedData = prefs.getStringList(pairedDevicesKey) ?? [];
      final deviceJson = jsonEncode({
        'name': device.name,
        'address': device.address,
        'rssi': device.rssi,
      });

      if (!pairedData.any((d) => jsonDecode(d)['address'] == device.address)) {
        pairedData.add(deviceJson);
        await prefs.setStringList(pairedDevicesKey, pairedData);
        _loadPairedDevices();
      }
    } catch (e) {
      debugPrint('Error saving paired device: $e');
    }
  }

  Future<void> _removePairedDevice(String address) async {
    try {
      final pairedData = prefs.getStringList(pairedDevicesKey) ?? [];
      pairedData.removeWhere((d) => jsonDecode(d)['address'] == address);
      await prefs.setStringList(pairedDevicesKey, pairedData);
      _loadPairedDevices();
      _showSnackBar('Perangkat dihapus', Colors.orange);
    } catch (e) {
      debugPrint('Error removing paired device: $e');
    }
  }

  Future<void> startScanning() async {
    if (!isBluetoothEnabled) {
      _showSnackBar('Bluetooth tidak aktif', Colors.red);
      return;
    }

    await BluetoothPermission.request();

    setState(() {
      isScanning = true;
      availableDevices.clear();
      _scanMap.clear();
    });

    try {
      await FlutterBluePlus.stopScan();

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      final subscription = FlutterBluePlus.scanResults.listen((results) {
        bool needUpdate = false;

        for (final result in results) {
          final device = result.device;

          if (device.platformName.isEmpty) continue;

          final address = device.remoteId.str;

          if (_scanMap.containsKey(address)) {
            // Update RSSI saja
            _scanMap[address] = _scanMap[address]!.copyWith(rssi: result.rssi);
          } else {
            _scanMap[address] = BleDevice(
              name: device.platformName,
              address: address,
              rssi: result.rssi,
            );
          }

          needUpdate = true;
        }

        if (needUpdate && mounted) {
          setState(() {
            availableDevices = _scanMap.values.toList();
          });
        }
      });

      await Future.delayed(const Duration(seconds: 10));
      await subscription.cancel();
      await stopScanning();
    } catch (e) {
      _showSnackBar('Error scanning: $e', Colors.red);
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  Future<void> connectToDevice(BleDevice device) async {
    try {
      final bleDevice = BluetoothDevice(
        remoteId: DeviceIdentifier(device.address),
      );

      await bleDevice.connect(
        timeout: const Duration(seconds: 10),
        license: License.free,
      );

      if (mounted) {
        setState(() {
          connectedDevice = bleDevice;
        });

        _showSnackBar('Terhubung ke ${device.name}', Colors.green);
        await _savePairedDevice(device);

        if (mounted) {
          _showWifiBottomSheet(bleDevice, device);
        }
      }
    } catch (e) {
      _showSnackBar('Gagal terhubung: $e', Colors.red);
      debugPrint('Connection error: $e');
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice == null) return;

    try {
      await connectedDevice!.disconnect();
      if (mounted) {
        setState(() {
          connectedDevice = null;
        });
        _showSnackBar('Perangkat terputus', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
      debugPrint('Disconnect error: $e');
    }
  }

  void _showWifiBottomSheet(BluetoothDevice bleDevice, BleDevice device) {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Koneksi WiFi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan SSID dan Password untuk ${device.name}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  labelText: 'SSID WiFi',
                  hintText: 'Masukkan nama jaringan WiFi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  prefixIcon: const Icon(Icons.wifi),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password WiFi',
                  hintText: 'Masukkan password WiFi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _sendWifiCredentials(
                      bleDevice,
                      ssidController.text,
                      passwordController.text,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Kirim Kredensial WiFi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendWifiCredentials(
    BluetoothDevice device,
    String ssid,
    String password,
  ) async {
    try {
      final services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            final payload = jsonEncode({'ssid': ssid, 'password': password});

            await characteristic.write(
              utf8.encode(payload),
              withoutResponse: characteristic.properties.writeWithoutResponse,
            );

            _showSnackBar('Kredensial WiFi terkirim!', Colors.green);
            return;
          }
        }
      }
      _showSnackBar('Karakteristik write tidak ditemukan', Colors.red);
    } catch (e) {
      _showSnackBar('Error mengirim data: $e', Colors.red);
      debugPrint('Send credentials error: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perangkat',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 19),
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
                              color: isBluetoothEnabled
                                  ? Colors.blue[700]
                                  : Colors.red,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                              connectedDevice!.platformName,
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
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
                      (device) => Dismissible(
                        key: Key(device.address),
                        onDismissed: (_) => _removePairedDevice(device.address),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: DeviceCard(
                          device: device,
                          isPaired: true,
                          isConnected:
                              connectedDevice?.remoteId.str == device.address,
                          onTap: () => connectToDevice(device),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan tombol "Cari Perangkat" untuk memulai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
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
      ),
    );
  }
}
