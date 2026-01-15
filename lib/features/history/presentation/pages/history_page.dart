// Flutter imports:
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Dummy data untuk history
  final List<HistoryData> allHistory = [
    HistoryData(
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      temperature: 28.5,
      humidity: 65.0,
      gasLevel: 120.0,
      buzzerStatus: false,
      alertType: null,
    ),
    HistoryData(
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      temperature: 29.2,
      humidity: 68.0,
      gasLevel: 310.0,
      buzzerStatus: true,
      alertType: 'warning',
    ),
    HistoryData(
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      temperature: 27.8,
      humidity: 62.0,
      gasLevel: 95.0,
      buzzerStatus: false,
      alertType: null,
    ),
    HistoryData(
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      temperature: 30.5,
      humidity: 70.0,
      gasLevel: 350.0,
      buzzerStatus: true,
      alertType: 'danger',
    ),
    HistoryData(
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      temperature: 28.0,
      humidity: 64.0,
      gasLevel: 110.0,
      buzzerStatus: false,
      alertType: null,
    ),
    HistoryData(
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      temperature: 27.5,
      humidity: 61.0,
      gasLevel: 105.0,
      buzzerStatus: false,
      alertType: null,
    ),
  ];

  List<HistoryData> get normalHistory =>
      allHistory.where((h) => h.alertType == null).toList();
  List<HistoryData> get warningHistory =>
      allHistory.where((h) => h.alertType == 'warning').toList();
  List<HistoryData> get dangerHistory =>
      allHistory.where((h) => h.alertType == 'danger').toList();

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat',
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
                            Icons.history_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Record',
                            allHistory.length.toString(),
                            Icons.list_alt_rounded,
                            Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Alert',
                            (warningHistory.length + dangerHistory.length)
                                .toString(),
                            Icons.warning_rounded,
                            Colors.orange[300]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Semua'),
                  Tab(text: 'Peringatan'),
                  Tab(text: 'Bahaya'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // History List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryList(allHistory, 'Semua'),
                  _buildHistoryList(warningHistory, 'Peringatan'),
                  _buildHistoryList(dangerHistory, 'Bahaya'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryData> historyList, String type) {
    if (historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data $type',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final data = historyList[index];
        return HistoryCard(data: data);
      },
    );
  }
}

class HistoryCard extends StatelessWidget {
  final HistoryData data;

  const HistoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    Color alertColor = _getAlertColor();
    IconData alertIcon = _getAlertIcon();
    String alertText = _getAlertText();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: data.alertType != null
            ? Border.all(color: alertColor, width: 2)
            : null,
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
          onTap: () {
            _showDetailBottomSheet(context);
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with time and alert
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data.alertType != null
                            ? alertColor.withValues(alpha: 0.1)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        data.alertType != null
                            ? alertIcon
                            : Icons.schedule_rounded,
                        color: data.alertType != null
                            ? alertColor
                            : Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(data.timestamp),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTime(data.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data.alertType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: alertColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(alertIcon, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              alertText,
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

                const SizedBox(height: 16),

                // Sensor Data
                Row(
                  children: [
                    Expanded(
                      child: _buildDataItem(
                        Icons.thermostat_rounded,
                        '${data.temperature.toStringAsFixed(1)}°C',
                        'Suhu',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildDataItem(
                        Icons.water_drop_rounded,
                        '${data.humidity.toStringAsFixed(1)}%',
                        'Kelembapan',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildDataItem(
                        Icons.air_rounded,
                        '${data.gasLevel.toStringAsFixed(0)} PPM',
                        'Gas',
                        _getGasColor(data.gasLevel),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Buzzer Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: data.buzzerStatus
                        ? Colors.green[50]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_rounded,
                        size: 16,
                        color: data.buzzerStatus
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.buzzerStatus ? 'Buzzer Aktif' : 'Buzzer Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: data.buzzerStatus
                              ? Colors.green[700]
                              : Colors.grey[600],
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
      ),
    );
  }

  Widget _buildDataItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Color _getAlertColor() {
    if (data.alertType == 'danger') return Colors.red;
    if (data.alertType == 'warning') return Colors.orange;
    return Colors.green;
  }

  IconData _getAlertIcon() {
    if (data.alertType == 'danger') return Icons.error_rounded;
    if (data.alertType == 'warning') return Icons.warning_rounded;
    return Icons.check_circle_rounded;
  }

  String _getAlertText() {
    if (data.alertType == 'danger') return 'Bahaya';
    if (data.alertType == 'warning') return 'Peringatan';
    return 'Normal';
  }

  Color _getGasColor(double gasLevel) {
    if (gasLevel >= 300) return Colors.red;
    if (gasLevel >= 210) return Colors.orange;
    return Colors.green;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // biar radius keliatan
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // title
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Detail Riwayat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildDetailRow('Waktu', _formatDateTime(data.timestamp)),
              _buildDetailRow('Jam', _formatTime(data.timestamp)),

              const Divider(height: 24),

              _buildDetailRow(
                'Suhu',
                '${data.temperature.toStringAsFixed(1)}°C',
              ),
              _buildDetailRow(
                'Kelembapan',
                '${data.humidity.toStringAsFixed(1)}%',
              ),
              _buildDetailRow(
                'Level Gas',
                '${data.gasLevel.toStringAsFixed(0)} PPM',
              ),

              const Divider(height: 24),

              _buildDetailRow(
                'Status Buzzer',
                data.buzzerStatus ? 'Aktif' : 'Nonaktif',
              ),
              if (data.alertType != null)
                _buildDetailRow('Tipe Alert', _getAlertText()),

              const SizedBox(height: 24),

              // close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class HistoryData {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double gasLevel;
  final bool buzzerStatus;
  final String? alertType;

  HistoryData({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.gasLevel,
    required this.buzzerStatus,
    this.alertType,
  });
}
