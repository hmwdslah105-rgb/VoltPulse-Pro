import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const PowerMeterApp());
}

class PowerMeterApp extends StatelessWidget {
  const PowerMeterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoltPulse Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFF00FFCC),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  String _deviceName = "Samsung Galaxy A16";

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initBattery();
    _loadDeviceInfo();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateBattery();
    });
  }

  Future<void> _loadDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceName = "${androidInfo.manufacturer.toUpperCase()} ${androidInfo.model}";
      });
    } catch (e) {
      // افتراضي لو اشتغل على ويب أو جهاز تاني
    }
  }

  Future<void> _initBattery() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });

    _battery.onBatteryStateChanged.listen((state) {
      setState(() {
        _batteryState = state;
      });
    });
  }

  Future<void> _updateBattery() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCharging = _batteryState == BatteryState.charging;
    // محاكاة قراءة الوات بناءً على حالة الشحن للواجهة الاحترافية
    double simulatedWattage = isCharging ? 22.5 : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'VoltPulse Pro',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FFCC)),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الجهاز الحالي', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_deviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFCC).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'أقصى دعم: 25W',
                      style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isCharging ? const Color(0xFF00FFCC).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _batteryLevel / 100.0,
                        strokeWidth: 14,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCharging ? const Color(0xFF00FFCC) : Colors.orangeAccent,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCharging ? '${simulatedWattage.toStringAsFixed(1)} W' : '0.0 W',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isCharging ? '⚡ جاري الشحن السريع' : '🔌 غير متصل',
                          style: TextStyle(color: isCharging ? const Color(0xFF00FFCC) : Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_batteryLevel%',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildCard('الجهد', '4.25 V', Icons.flash_on, Colors.amber),
                const SizedBox(width: 12),
                _buildCard('التيار', '2400 mA', Icons.electric_bolt, Colors.lightBlueAccent),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCard('الحرارة', '31.5 °C', Icons.thermostat, Colors.redAccent),
                const SizedBox(width: 12),
                _buildCard('السعة', '5000 mAh', Icons.battery_charging_full, Colors.greenAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
