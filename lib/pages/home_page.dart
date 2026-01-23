import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Project imports:
import 'package:she/core/toastification/toastification.dart';
import 'package:she/widgets/sensor_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MqttServerClient client;
  bool isDeviceConnected = false;
  String connectedDevice = '';

  double temperature = 0.0;
  double humidity = 0.0;
  double gasLevel = 0.0; // PPM
  bool isBuzzerOn = false;
  bool isDataLoaded = false;

  bool _wasConnected = false;
  bool _isRetrying = false;
  bool _isConnecting = false;

  double maxSafeGasLevel = 400.0;
  double warningGasLevel = 300.0;

  static const String mqttBroker =
      'f38e4be24dc34b5ca97d975d7595c8d2.s1.eu.hivemq.cloud';
  static const int mqttPort = 8883;
  static const String buzzerTopic = 'home/buzzer/set';
  static const String buzzerStatusTopic = 'home/buzzer/status';
  static const String temperatureTopic = 'home/sensor/temperature';
  static const String humidityTopic = 'home/sensor/humidity';
  static const String gasLevelTopic = 'home/sensor/gas';
  static const String deviceNameTopic = 'home/device/name';
  static const String gasSettingTopic = 'home/gas/setting';

  final toastificationService = ToastificationService();

  @override
  void initState() {
    super.initState();
    _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    if (_isConnecting) {
      debugPrint('⏳ Already connecting, skip');
      return;
    }

    _isConnecting = true;

    try {
      client.disconnect();
    } catch (_) {}

    final clientId = 'FlutterClient_${DateTime.now().millisecondsSinceEpoch}';

    client = MqttServerClient.withPort(mqttBroker, clientId, mqttPort);

    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 10000;
    client.autoReconnect = false;

    client.secure = true;
    client.onBadCertificate = (dynamic cert) {
      debugPrint('⚠️ Accepting certificate');
      return true;
    };
    client.setProtocolV311();

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .authenticateAs('client', 'ClientESP32')
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMess;

    client.onConnected = _onMqttConnected;
    client.onDisconnected = _onMqttDisconnected;
    client.onSubscribed = _onSubscribedTopic;

    try {
      debugPrint('🔌 Connecting to MQTT...');

      final status = await client.connect('client', 'ClientESP32');

      if (status?.state != MqttConnectionState.connected) {
        debugPrint('❌ Connect failed: ${status?.returnCode}');
        _handleConnectionFailure();
        return;
      }

      debugPrint('✅ MQTT Connected');

      client.updates?.listen((messages) {
        for (var message in messages) {
          final recMessage = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message,
          );
          _handleMqttMessage(message.topic, payload);
        }
      }, onError: (e) => debugPrint('❌ Stream error: $e'));
    } catch (e) {
      debugPrint('❌ MQTT error: $e');
      _handleConnectionFailure();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleConnectionFailure() {
    debugPrint('⚠️ Connection attempt failed');

    if (mounted) {
      setState(() {
        isDeviceConnected = false;
      });
    }

    _retryConnection();
  }

  void _onMqttConnected() {
    if (!_wasConnected) {
      toastificationService.showSuccess(
        'Koneksi Berhasil',
        'Terhubung ke server MQTT',
      );
    }

    _wasConnected = true;
    _isRetrying = false;

    if (mounted) {
      setState(() {
        isDeviceConnected = true;
      });
    }

    client.subscribe(deviceNameTopic, MqttQos.atLeastOnce);
    client.subscribe(temperatureTopic, MqttQos.atLeastOnce);
    client.subscribe(humidityTopic, MqttQos.atLeastOnce);
    client.subscribe(gasLevelTopic, MqttQos.atLeastOnce);
    client.subscribe(buzzerStatusTopic, MqttQos.atLeastOnce);
    client.subscribe(gasSettingTopic, MqttQos.atLeastOnce);
  }

  void _onMqttDisconnected() {
    debugPrint('❌ MQTT Disconnected');

    if (_wasConnected) {
      toastificationService.showError(
        'Koneksi Terputus',
        'Mencoba koneksi ulang...',
      );
    }

    _wasConnected = false;

    if (mounted) {
      setState(() {
        isDeviceConnected = false;
        isDataLoaded = false;
      });
    }

    _retryConnection();
  }

  void _onSubscribedTopic(String topic) {
    debugPrint('✅ Subscribed to: $topic');
  }

  void _handleMqttMessage(String topic, String payload) {
    debugPrint('📨 $topic => $payload');

    if (!mounted) return;

    setState(() {
      isDataLoaded = true;

      switch (topic) {
        case deviceNameTopic:
          connectedDevice = payload.trim();
          break;

        case temperatureTopic:
          final temp = double.tryParse(payload);
          if (temp != null && temp >= -50 && temp <= 150) {
            temperature = temp;
          }
          break;

        case humidityTopic:
          final hum = double.tryParse(payload);
          if (hum != null && hum >= 0 && hum <= 100) {
            humidity = hum;
          }
          break;

        case gasLevelTopic:
          final gas = double.tryParse(payload);
          if (gas != null && gas >= 0) {
            gasLevel = gas;
          }
          break;

        case buzzerStatusTopic:
          final status = payload.trim().toLowerCase();
          isBuzzerOn = (status == 'on' || status == '1' || status == 'true');
          break;

        case gasSettingTopic:
          final gasSettings = jsonDecode(payload);

          maxSafeGasLevel = (gasSettings['maxSafeLevel'] as num).toDouble();
          warningGasLevel = (gasSettings['warningLevel'] as num).toDouble();

          debugPrint('Gas Settings: $gasSettings');
          break;

        default:
          debugPrint('⚠️ Unknown topic: $topic');
      }
    });
  }

  void _retryConnection() {
    if (_isRetrying) return;

    _isRetrying = true;

    Future.delayed(const Duration(seconds: 5), () async {
      if (_wasConnected) {
        _isRetrying = false;
        return;
      }

      debugPrint('🔁 Retrying MQTT...');
      await _initializeMqtt();

      // kalau masih gagal → ulangi lagi
      if (!_wasConnected) {
        _isRetrying = false;
        _retryConnection();
      }
    });
  }

  void toggleBuzzer() {
    final newState = !isBuzzerOn;
    final payload = newState ? 'on' : 'off';

    setState(() {
      isBuzzerOn = newState;
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    try {
      client.publishMessage(
        buzzerTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );

      toastificationService.showInfo(
        newState ? 'Buzzer Aktif' : 'Buzzer Nonaktif',
        'Pengaturan buzzer telah diperbarui.',
      );
    } catch (e) {
      debugPrint('Error publishing buzzer command: $e');
      toastificationService.showError(
        'Error',
        'Gagal mengirim perintah buzzer',
      );
      setState(() {
        isBuzzerOn = !newState;
      });
    }
  }

  Color getGasLevelColor(double value) {
    if (!isDeviceConnected || value == 0) return Colors.grey;

    if (value >= maxSafeGasLevel) return Colors.red;
    if (value >= warningGasLevel) return Colors.orange;

    return Colors.green;
  }

  String getGasLevelStatus(double value) {
    if (!isDeviceConnected) return 'Tidak Terhubung';
    if (value == 0) return 'Menunggu Data';

    if (value >= maxSafeGasLevel) return 'Berbahaya';
    if (value >= warningGasLevel) return 'Peringatan';

    return 'Aman';
  }

  IconData getGasLevelIcon(double value) {
    if (!isDeviceConnected || value == 0) return Icons.sensor_occupied;

    if (value >= maxSafeGasLevel) return Icons.warning_rounded;
    if (value >= warningGasLevel) return Icons.error_outline;

    return Icons.check_circle_outline;
  }

  Future<void> _refreshData() async {
    if (isDeviceConnected) {
      // Request fresh data by subscribing again
      client.subscribe(temperatureTopic, MqttQos.atLeastOnce);
      client.subscribe(humidityTopic, MqttQos.atLeastOnce);
      client.subscribe(gasLevelTopic, MqttQos.atLeastOnce);

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void publishGasLevelSettings(double maxLevel, double warningLevel) {
    final payload = {'maxSafeLevel': maxLevel, 'warningLevel': warningLevel};

    final jsonPayload = jsonEncode(payload);

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonPayload);

    client.publishMessage(
      gasSettingTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Home Environment',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDeviceConnected
                            ? const Color(0xFF4CAF50) // soft green
                            : const Color(0xFFF44336), // soft red
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDeviceConnected
                              ? const Color(0xFF81C784) // green light
                              : const Color(0xFFE57373), // red light
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDeviceConnected
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDeviceConnected
                                ? connectedDevice.isNotEmpty
                                      ? 'Terhubung: $connectedDevice'
                                      : 'Terhubung ke MQTT'
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (!isDeviceConnected)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.red[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perangkat Tidak Terhubung',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Data real-time tidak tersedia. Kontrol dinonaktifkan. Pastikan perangkat ESP32 aktif dan terhubung.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Column(
                        children: [
                          Row(
                            children: [
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
                              Expanded(
                                child: SensorCard(
                                  title: 'Kelembapan',
                                  value: humidity.toStringAsFixed(1),
                                  unit: '%',
                                  icon: Icons.water_drop_rounded,
                                  color: Colors.blue,
                                  gradient: [
                                    Colors.blue[400]!,
                                    Colors.blue[600]!,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: getGasLevelColor(
                                          gasLevel,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.air_rounded,
                                        color: getGasLevelColor(gasLevel),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Text(
                                                  isDeviceConnected
                                                      ? gasLevel
                                                            .toStringAsFixed(0)
                                                      : '-',
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDeviceConnected
                                                        ? Colors.black
                                                        : Colors.grey[400],
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
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              showGasLevelSettings(context),
                                          icon: const Icon(Icons.settings),
                                          color: Colors.grey[600],
                                          tooltip: 'Pengaturan',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 20,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getGasLevelColor(gasLevel),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                getGasLevelIcon(gasLevel),
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                getGasLevelStatus(gasLevel),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
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
                                          isDeviceConnected && gasLevel > 0
                                              ? '${(gasLevel / maxSafeGasLevel * 100).clamp(0, 100).toStringAsFixed(0)}%'
                                              : '0%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: getGasLevelColor(gasLevel),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: isDeviceConnected && gasLevel > 0
                                            ? (gasLevel / maxSafeGasLevel)
                                                  .clamp(0.0, 1.0)
                                            : 0.0,
                                        minHeight: 10,
                                        backgroundColor: Colors.grey[200],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              getGasLevelColor(gasLevel),
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
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.blue[700],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Peringatan: ${warningGasLevel.toInt()} PPM | Max Aman: ${maxSafeGasLevel.toInt()} PPM',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue[700],
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                  color:
                                      (isBuzzerOn ? Colors.green : Colors.grey)
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
                                        value: isDeviceConnected
                                            ? isBuzzerOn
                                            : false,
                                        onChanged: isDeviceConnected
                                            ? (value) => toggleBuzzer()
                                            : null,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
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

  void showGasLevelSettings(BuildContext context) {
    final maxController = TextEditingController(
      text: maxSafeGasLevel.toInt().toString(),
    );
    final warningController = TextEditingController(
      text: warningGasLevel.toInt().toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pengaturan Level Gas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Safe Level (PPM)',
                  hintText: 'Masukkan nilai maksimal aman',
                  prefixIcon: const Icon(Icons.security),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: warningController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Warning Level (PPM)',
                  hintText: 'Masukkan nilai peringatan',
                  prefixIcon: const Icon(Icons.warning_amber),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newMax = double.tryParse(maxController.text);
                    final newWarning = double.tryParse(warningController.text);

                    if (newMax != null && newWarning != null) {
                      if (newWarning >= newMax) {
                        toastificationService.showError(
                          'Error',
                          'Warning level harus lebih kecil dari max safe level',
                        );

                        return;
                      }

                      setState(() {
                        maxSafeGasLevel = newMax;
                        warningGasLevel = newWarning;
                      });

                      // Publish ke MQTT
                      publishGasLevelSettings(newMax, newWarning);

                      Navigator.pop(context);

                      toastificationService.showSuccess(
                        'Pengaturan Berhasil',
                        'Pengaturan level gas berhasil disimpan',
                      );
                    } else {
                      toastificationService.showError(
                        'Error',
                        'Nilai max safe level dan warning level harus berupa angka',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Simpan Pengaturan',
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
}
