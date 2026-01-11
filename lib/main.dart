// pubspec.yaml dependencies yang dibutuhkan:
// flutter_bluetooth_serial: ^0.4.0
// fl_chart: ^0.65.0
// shared_preferences: ^2.2.2

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  BluetoothConnection? connection;
  BluetoothDevice? connectedDevice;

  double temperature = 0.0;
  double humidity = 0.0;
  double gasLevel = 0.0;
  bool buzzerActive = false;
  bool isConnected = false;
  String wifiStatus = '';

  List<SensorData> temperatureHistory = [];
  List<SensorData> humidityHistory = [];
  List<SensorData> gasHistory = [];

  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    connection?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      buzzerActive = prefs.getBool('buzzer_active') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('buzzer_active', buzzerActive);
  }

  void _updateSensorData(String data) {
    try {
      final json = jsonDecode(data);
      setState(() {
        temperature = json['temp']?.toDouble() ?? temperature;
        humidity = json['hum']?.toDouble() ?? humidity;
        gasLevel = json['gas']?.toDouble() ?? gasLevel;

        final now = DateTime.now();
        temperatureHistory.add(SensorData(now, temperature));
        humidityHistory.add(SensorData(now, humidity));
        gasHistory.add(SensorData(now, gasLevel));

        if (temperatureHistory.length > 50) temperatureHistory.removeAt(0);
        if (humidityHistory.length > 50) humidityHistory.removeAt(0);
        if (gasHistory.length > 50) gasHistory.removeAt(0);
      });
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  Future<void> _sendCommand(String command) async {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(utf8.encode(command + '\n')));
      await connection!.output.allSent;
    }
  }

  Future<void> _toggleBuzzer() async {
    setState(() {
      buzzerActive = !buzzerActive;
    });
    await _sendCommand('BUZZER:${buzzerActive ? '1' : '0'}');
    await _saveSettings();
  }

  void _onDeviceConnected(BluetoothDevice device, BluetoothConnection conn) {
    setState(() {
      connectedDevice = device;
      connection = conn;
      isConnected = true;
    });

    _connectionSubscription = connection!.input!.listen((Uint8List data) {
      String received = utf8.decode(data);

      if (received.contains('WIFI:OK')) {
        setState(() {
          wifiStatus = 'WiFi terhubung!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ WiFi berhasil terhubung!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (received.contains('WIFI:FAIL')) {
        setState(() {
          wifiStatus = 'WiFi gagal terhubung';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ WiFi gagal terhubung!'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        _updateSensorData(received);
      }
    });

    // Gunakan onDone terpisah
    _connectionSubscription!.onDone(() {
      setState(() {
        isConnected = false;
        connectedDevice = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Koneksi terputus')));
    });
  }

  void _onDeviceDisconnected() {
    _connectionSubscription?.cancel();
    connection?.dispose();
    setState(() {
      connection = null;
      connectedDevice = null;
      isConnected = false;
      wifiStatus = '';
    });
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          temperature: temperature,
          humidity: humidity,
          gasLevel: gasLevel,
          buzzerActive: buzzerActive,
          onBuzzerToggle: _toggleBuzzer,
          isConnected: isConnected,
          wifiStatus: wifiStatus,
        );
      case 1:
        return StatisticsScreen(
          temperatureHistory: temperatureHistory,
          humidityHistory: humidityHistory,
          gasHistory: gasHistory,
        );
      case 2:
        return DeviceSettingsScreen(
          connectedDevice: connectedDevice,
          isConnected: isConnected,
          onConnect: _onDeviceConnected,
          onDisconnect: _onDeviceDisconnected,
          onSendWifiCommand: (ssid, password) async {
            await _sendCommand('WIFI:$ssid,$password');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mengirim konfigurasi WiFi...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Device',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final double temperature;
  final double humidity;
  final double gasLevel;
  final bool buzzerActive;
  final VoidCallback onBuzzerToggle;
  final bool isConnected;
  final String wifiStatus;

  const DashboardScreen({
    Key? key,
    required this.temperature,
    required this.humidity,
    required this.gasLevel,
    required this.buzzerActive,
    required this.onBuzzerToggle,
    required this.isConnected,
    required this.wifiStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConnected ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'Terhubung' : 'Terputus',
                    style: TextStyle(
                      color: isConnected ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wifiStatus.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: wifiStatus.contains('terhubung')
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: wifiStatus.contains('terhubung')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: wifiStatus.contains('terhubung')
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      wifiStatus,
                      style: TextStyle(
                        color: wifiStatus.contains('terhubung')
                            ? Colors.green[900]
                            : Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Monitoring Sensor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SensorCard(
              title: 'Suhu',
              value: temperature.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
            ),
            const SizedBox(height: 12),
            SensorCard(
              title: 'Kelembapan',
              value: humidity.toStringAsFixed(1),
              unit: '%',
              icon: Icons.water_drop,
              gradient: const LinearGradient(
                colors: [Color(0xFF4E65FF), Color(0xFF92EFFD)],
              ),
            ),
            const SizedBox(height: 12),
            SensorCard(
              title: 'Gas',
              value: gasLevel.toStringAsFixed(0),
              unit: 'ppm',
              icon: Icons.air,
              gradient: const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kontrol',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: buzzerActive
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                      : [Colors.grey[300]!, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: buzzerActive
                        ? Colors.red.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBuzzerToggle,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            buzzerActive
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buzzer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                buzzerActive ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            buzzerActive ? Icons.toggle_on : Icons.toggle_off,
                            size: 40,
                            color: buzzerActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final LinearGradient gradient;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class StatisticsScreen extends StatelessWidget {
  final List<SensorData> temperatureHistory;
  final List<SensorData> humidityHistory;
  final List<SensorData> gasHistory;

  const StatisticsScreen({
    Key? key,
    required this.temperatureHistory,
    required this.humidityHistory,
    required this.gasHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Statistik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ChartCard(
              title: 'Suhu',
              unit: '°C',
              data: temperatureHistory,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
            ),
            const SizedBox(height: 16),
            ChartCard(
              title: 'Kelembapan',
              unit: '%',
              data: humidityHistory,
              gradient: const LinearGradient(
                colors: [Color(0xFF4E65FF), Color(0xFF92EFFD)],
              ),
            ),
            const SizedBox(height: 16),
            ChartCard(
              title: 'Gas',
              unit: 'ppm',
              data: gasHistory,
              gradient: const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final List<SensorData> data;
  final LinearGradient gradient;

  const ChartCard({
    Key? key,
    required this.title,
    required this.unit,
    required this.data,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasData = data.isNotEmpty;
    final minValue = hasData
        ? data.map((e) => e.value).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxValue = hasData
        ? data.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 100.0;
    final avgValue = hasData
        ? data.map((e) => e.value).reduce((a, b) => a + b) / data.length
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasData) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Min', minValue, unit, Colors.blue),
                  _buildStatItem('Avg', avgValue, unit, Colors.orange),
                  _buildStatItem('Max', maxValue, unit, Colors.red),
                ],
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              height: 200,
              child: !hasData
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada data',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: data
                                .asMap()
                                .entries
                                .map(
                                  (e) =>
                                      FlSpot(e.key.toDouble(), e.value.value),
                                )
                                .toList(),
                            isCurved: true,
                            gradient: gradient,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: gradient.colors
                                    .map((color) => color.withOpacity(0.1))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DeviceSettingsScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final bool isConnected;
  final Function(BluetoothDevice, BluetoothConnection) onConnect;
  final VoidCallback onDisconnect;
  final Function(String, String) onSendWifiCommand;

  const DeviceSettingsScreen({
    Key? key,
    required this.connectedDevice,
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSendWifiCommand,
  }) : super(key: key);

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  bool isConnecting = false;
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  Future<void> _getBondedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial
          .instance
          .getBondedDevices();
      setState(() {
        devices = bondedDevices;
      });
    } catch (e) {
      print('Error getting bonded devices: $e');
    }
  }

  Future<void> _startScan() async {
    setState(() {
      isScanning = true;
    });

    try {
      await _getBondedDevices();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning: $e')));
    }

    setState(() {
      isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(
        device.address,
      );
      widget.onConnect(device, connection);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Berhasil terhubung!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Gagal terhubung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isConnecting = false;
    });
  }

  void _showWifiDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wifi, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Konfigurasi WiFi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  labelText: 'Nama WiFi (SSID)',
                  prefixIcon: const Icon(Icons.wifi),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password WiFi',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (ssidController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SSID tidak boleh kosong!'),
                          ),
                        );
                        return;
                      }
                      widget.onSendWifiCommand(
                        ssidController.text,
                        passwordController.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Device & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.isConnected) ...[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bluetooth_connected,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.connectedDevice?.name ?? 'ESP32',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.connectedDevice?.address ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onDisconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Putuskan Koneksi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showWifiDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.wifi,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konfigurasi WiFi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Setup koneksi WiFi ESP32',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.bluetooth_searching,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Terhubung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan untuk menemukan perangkat Bluetooth',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isScanning ? null : _startScan,
                      icon: Icon(
                        isScanning ? Icons.hourglass_empty : Icons.search,
                      ),
                      label: Text(
                        isScanning ? 'Scanning...' : 'Scan Perangkat',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (devices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Perangkat Tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...devices.map((device) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isConnecting
                          ? null
                          : () => _connectToDevice(device),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.bluetooth,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name ?? 'Unknown Device',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    device.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isConnecting)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Hubungkan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ],
      ),
    );
  }
}

class SensorData {
  final DateTime time;
  final double value;

  SensorData(this.time, this.value);
}
