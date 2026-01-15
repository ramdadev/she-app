// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:she/core/toastification/toastification.dart';
import 'package:she/features/home/presentation/widgets/sensor_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Sensor data
  double temperature = 28.5;
  double humidity = 65.0;
  double gasLevel = 120.0; // PPM
  bool isBuzzerOn = false;
  bool isDeviceConnected = true;
  String connectedDevice = 'ESP32-Living Room';

  // Thresholds
  final double maxSafeGasLevel = 400.0;
  final double warningGasLevel = 300.0;

  final toastificationService = ToastificationService();

  void toggleBuzzer() {
    setState(() {
      isBuzzerOn = !isBuzzerOn;
    });

    toastificationService.showInfo(
      isBuzzerOn ? 'Buzzer Aktif' : 'Buzzer Nonaktif',
      'Pengaturan buzzer telah diperbarui.',
    );
  }

  Color getGasLevelColor() {
    if (gasLevel >= warningGasLevel) return Colors.red;
    if (gasLevel >= warningGasLevel * 0.7) return Colors.orange;
    return Colors.green;
  }

  String getGasLevelStatus() {
    if (gasLevel >= warningGasLevel) return 'Berbahaya';
    if (gasLevel >= warningGasLevel * 0.7) return 'Peringatan';
    return 'Aman';
  }

  IconData getGasLevelIcon() {
    if (gasLevel >= warningGasLevel) return Icons.warning_rounded;
    if (gasLevel >= warningGasLevel * 0.7) return Icons.error_outline;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
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
                    // Greeting and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Home',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Monitoring',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Connection Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDeviceConnected
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDeviceConnected
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDeviceConnected ? Icons.wifi : Icons.wifi_off,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDeviceConnected
                                ? 'Terhubung: $connectedDevice'
                                : 'Tidak Terhubung',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Simulate data refresh
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {
                    // Update sensor data here
                  });
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Sensor Cards Row
                      Row(
                        children: [
                          // Temperature Card
                          Expanded(
                            child: SensorCard(
                              title: 'Suhu',
                              value: temperature.toStringAsFixed(1),
                              unit: '°C',
                              icon: Icons.thermostat_rounded,
                              color: Colors.orange,
                              gradient: [
                                Colors.orange[400]!,
                                Colors.orange[600]!,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Humidity Card
                          Expanded(
                            child: SensorCard(
                              title: 'Kelembapan',
                              value: humidity.toStringAsFixed(1),
                              unit: '%',
                              icon: Icons.water_drop_rounded,
                              color: Colors.blue,
                              gradient: [Colors.blue[400]!, Colors.blue[600]!],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Gas Level Card (Full Width)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: getGasLevelColor().withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.air_rounded,
                                    color: getGasLevelColor(),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Indikator Gas',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            gasLevel.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'PPM',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getGasLevelColor(),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        getGasLevelIcon(),
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        getGasLevelStatus(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Gas Level Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Level Gas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${(gasLevel / maxSafeGasLevel * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: getGasLevelColor(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: gasLevel / maxSafeGasLevel,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      getGasLevelColor(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '0 PPM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    Text(
                                      '${maxSafeGasLevel.toInt()} PPM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Buzzer Control Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isBuzzerOn
                                ? [Colors.green[400]!, Colors.green[600]!]
                                : [Colors.grey[400]!, Colors.grey[600]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isBuzzerOn ? Colors.green : Colors.grey)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: isBuzzerOn
                                        ? Colors.green[600]
                                        : Colors.grey[600],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Buzzer Control',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isBuzzerOn
                                            ? 'Buzzer Aktif'
                                            : 'Buzzer Nonaktif',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 1.3,
                                  child: Switch(
                                    value: isBuzzerOn,
                                    onChanged: (value) => toggleBuzzer(),
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: Colors.green[300],
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),

                            if (isBuzzerOn) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Buzzer akan berbunyi saat gas terdeteksi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
