import 'package:flutter/material.dart';
import 'dart:async';
import 'vitals_screen.dart';
import 'symptoms_screen.dart';
import 'reminders_screen.dart';
import 'nutrition_screen.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/ble_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          VitalsScreen(),
          SymptomsScreen(),
          RemindersScreen(),
          NutritionScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Vitals'),
          NavigationDestination(icon: Icon(Icons.sick_outlined), selectedIcon: Icon(Icons.sick), label: 'Symptoms'),
          NavigationDestination(icon: Icon(Icons.alarm_outlined), selectedIcon: Icon(Icons.alarm), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Nutrition'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String _name = '...';
  int _week = 28;
  String _due = 'Sep 15, 2026';
  Map<String, dynamic> _vitals = Map.from(ApiService.fallbackVitals);
  Map<String, dynamic> _risk = Map.from(ApiService.fallbackRisk);
  bool _loading = true;

  // BLE wearable gateway (phone -> backend). Null-safe: everything
  // keeps working from mock fallback when the ESP32 is off.
  final BleGateway _ble = BleGateway();
  StreamSubscription<WearableVitals>? _bleSub;
  StreamSubscription<BleConnState>? _bleStateSub;
  WearableVitals? _live;
  BleConnState _bleState = BleConnState.idle;
  bool _bleBusy = false;
  DateTime? _lastPush;

  @override
  void initState() {
    super.initState();
    _bleSub = _ble.stream.listen(_onLive);
    _bleStateSub = _ble.stateStream.listen((s) {
      if (mounted) {
        setState(() {
          _bleState = s;
          _bleBusy = s == BleConnState.scanning ||
              s == BleConnState.connecting;
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _bleStateSub?.cancel();
    _ble.dispose();
    super.dispose();
  }

  /// Live BLE reading: show instantly + forward to backend (throttled).
  Future<void> _onLive(WearableVitals w) async {
    if (!mounted) return;
    setState(() => _live = w);
    final now = DateTime.now();
    if (_lastPush != null &&
        now.difference(_lastPush!).inSeconds < 5) return;
    _lastPush = now;
    final profile = await SessionService.loadProfile();
    await ApiService.postLiveVitals(
        w.toLivePost((profile['patientId'] as String?) ?? 'P001'));
  }

  Future<void> _toggleBle() async {
    if (_bleBusy) return;
    if (_bleState == BleConnState.connected) {
      await _ble.disconnect();
    } else {
      final ok = await _ble.connect();
      if (!mounted) return;
      if (!ok && _bleState == BleConnState.notFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Nestora-V1 not found. Check the wearable is powered.')),
        );
      }
    }
  }

  bool get _hasLive =>
      _live != null &&
      DateTime.now().difference(_live!.receivedAt).inSeconds < 5;

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await SessionService.loadProfile();
    final pid = (profile['patientId'] as String?) ?? 'P001';
    final results = await Future.wait([
      ApiService.getLatestVital(pid),
      ApiService.getRisk(pid),
    ]);
    if (!mounted) return;
    final name = (profile['name'] as String?) ?? '';
    setState(() {
      _name = name.isEmpty ? 'Priya' : name;
      _week = profile['week'] as int? ?? 28;
      _due = profile['due'] as String? ?? 'Sep 15, 2026';
      _vitals = results[0] as Map<String, dynamic>;
      _risk = results[1] as Map<String, dynamic>;
      _loading = false;
    });
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel =
        (_risk['risk_level'] as String? ?? 'low').toLowerCase();
    final riskColor = _riskColor(riskLevel);
    // Prefer fresh BLE wearable values; fall back to API/mock.
    final hr = (_hasLive && _live!.heartRate != null)
        ? _live!.heartRate.toString()
        : _vitals['heart_rate']?.toString() ?? '--';
    final spo2 = _vitals['spo2']?.toString() ?? '--';
    final temp = _vitals['temperature']?.toString() ?? '--';
    final sys = _vitals['systolic_bp']?.toString() ?? '--';
    final dia = _vitals['diastolic_bp']?.toString() ?? '--';
    final progress = (_week / 40).clamp(0.0, 1.0);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
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
                        'Hello, ${_name.split(' ').first}!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('Week $_week of pregnancy',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/profile');
                      if (mounted) _load();
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          const Color(0xFFE91E63).withAlpha(25),
                      child: Text(
                        _name.isEmpty ? '?' : _name[0].toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                            fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFFE91E63),
                    Color(0xFF9C27B0)
                  ]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pregnancy Progress',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Week $_week of 40',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withAlpha(77),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${(progress * 100).round()}% complete  •  Due: $_due',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Vitals',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      if (_loading)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                      if (_loading) const SizedBox(width: 8),
                      _bleChip(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _vitalCard('Heart Rate', '$hr bpm', Icons.favorite,
                      Colors.red,
                      live: _hasLive && _live!.heartRate != null),
                  _vitalCard(
                      'SpO2', '$spo2%', Icons.water_drop, Colors.blue),
                  _vitalCard('Temperature', '$temp°C',
                      Icons.thermostat, Colors.orange),
                  _vitalCard('Blood Pressure', '$sys/$dia',
                      Icons.monitor_heart, Colors.purple),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: riskColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.warning_amber,
                          color: riskColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${riskLevel[0].toUpperCase()}${riskLevel.substring(1)} Risk',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: riskColor)),
                          Text(
                              (_risk['recommendation'] as String?) ??
                                  'AI risk assessment.',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Quick Actions',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _actionButton(
                      context,
                      'Log\nSymptom',
                      Icons.add_circle_outline,
                      const Color(0xFFE91E63),
                      const SymptomsScreen()),
                  const SizedBox(width: 12),
                  _actionButton(
                      context,
                      'Vitals\nHistory',
                      Icons.monitor_heart_outlined,
                      const Color(0xFF7B1FA2),
                      const VitalsScreen()),
                  const SizedBox(width: 12),
                  _actionButton(
                      context,
                      'Nutrition\nTracker',
                      Icons.restaurant_outlined,
                      Colors.blue,
                      const NutritionScreen()),
                  const SizedBox(width: 12),
                  _actionButton(
                      context,
                      'Reminders',
                      Icons.alarm_outlined,
                      Colors.teal,
                      const RemindersScreen()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bleChip() {
    final connected = _bleState == BleConnState.connected;
    final label = _bleBusy
        ? 'Scanning…'
        : connected
            ? (_hasLive ? 'LIVE' : 'Connected')
            : 'Connect band';
    final color = connected && _hasLive
        ? Colors.green
        : connected
            ? Colors.blue
            : Colors.grey;
    return GestureDetector(
      onTap: _toggleBle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bleBusy)
              SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color))
            else
              Icon(Icons.bluetooth, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  static Widget _vitalCard(
      String title, String value, IconData icon, Color color,
      {bool live = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Row(
            children: [
              Text(title,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
              if (live) ...[
                const SizedBox(width: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _actionButton(BuildContext context, String label,
      IconData icon, Color color, Widget screen) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
