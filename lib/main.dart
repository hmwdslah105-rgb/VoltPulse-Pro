import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const platform = MethodChannel('com.power_meter/battery');
  final Battery _battery = Battery();

  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  
  double _voltage = 0.0;
  double _current = 0.0;
  double _temperature = 0.0;
  String _deviceName = "موبايل أندرويد";

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _initBattery();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchBatteryDetails();
    });
  }

  Future<void> _loadDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _deviceName = "${androidInfo.manufacturer.toUpperCase()} ${androidInfo.model}";
    });
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

  Future<void> _fetchBatteryDetails() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getBatteryDetails');
      final level = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = level;
        _voltage = (result['voltage'] as num).toDouble();
        _current = (result['current'] as num).toDouble();
        _temperature = (result['temperature'] as num).toDouble();
      });
    } on PlatformException catch (e) {
      debugPrint("خطأ في قراءة بيانات البطارية: ${e.message}");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double wattage = (_voltage * (_current / 1000.0));
    bool isCharging = _batteryState == BatteryState.charging;

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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // بطاقة اسم الموبايل ودعم الشحن
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
                      'أقصى قدرة: 25W - 45W',
                      style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // عداد الوات المضيء النيون
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
                            color: isCharging ? const Color(0xFF00FFCC).withOpacity(0.25) : Colors.redAccent.withOpacity(0.1),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      height: 210,
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
                          isCharging ? '${wattage.toStringAsFixed(1)} W' : '0.0 W',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isCharging ? '⚡ جاري الشحن السريع' : '🔌 غير متصل بالشاحن',
                          style: TextStyle(
                            color: isCharging ? const Color(0xFF00FFCC) : Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_batteryLevel%',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // كروت تفاصيل الفولت والأمبير والحرارة والسعة
            Row(
              children: [
                _buildMetricCard('الجهد (Voltage)', '${_voltage.toStringAsFixed(2)} V', Icons.flash_on, Colors.amber),
                const SizedBox(width: 12),
                _buildMetricCard('التيار (Current)', '${_current.toInt()} mA', Icons.electric_bolt, Colors.lightBlueAccent),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricCard('درجة الحرارة', '${_temperature.toStringAsFixed(1)} °C', Icons.thermostat, Colors.redAccent),
                const SizedBox(width: 12),
                _buildMetricCard('سعة البطارية', '5000 mAh', Icons.battery_charging_full, Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color iconColor) {
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
            Icon(icon, color: iconColor, size: 26),
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
