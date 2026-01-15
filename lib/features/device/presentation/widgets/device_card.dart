// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:she/features/device/domain/entities/ble_device.dart';

class DeviceCard extends StatelessWidget {
  final BleDevice device;
  final bool isPaired;
  final bool isConnected;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isPaired,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isConnected ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnected ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Device Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sensors,
                    color: isConnected ? Colors.green[700] : Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Signal Strength
                Column(
                  children: [
                    Icon(
                      _getSignalIcon(device.rssi),
                      color: _getSignalColor(device.rssi),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.rssi} dBm',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // Status/Action
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Terhubung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi > -50) return Icons.signal_wifi_4_bar;
    if (rssi > -60) return Icons.signal_wifi_4_bar;
    if (rssi > -70) return Icons.signal_wifi_0_bar;
    return Icons.signal_wifi_off;
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -50) return Colors.green;
    if (rssi > -60) return Colors.lightGreen;
    if (rssi > -70) return Colors.orange;
    return Colors.red;
  }
}
