import 'dart:math';
import 'package:flutter/material.dart';

class VitalsScreen extends StatelessWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vital History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD3E7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Color(0xFFFF2D95)),
                      SizedBox(width: 6),
                      Text('Last 24h', style: TextStyle(fontSize: 12, color: Color(0xFF7D6B82))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _vitalChart('Heart Rate', '82', 'bpm', const Color(0xFFEF4444), Icons.favorite,
                const Color(0xFFEF4444), 72, 95, true),
            const SizedBox(height: 16),
            _vitalChart('SpO2', '97', '%', const Color(0xFF3B82F6), Icons.water_drop,
                const Color(0xFF3B82F6), 94, 99, true),
            const SizedBox(height: 16),
            _bpChart(),
            const SizedBox(height: 16),
            _vitalChart('Temperature', '36.8', '°C', const Color(0xFFF59E0B), Icons.thermostat,
                const Color(0xFFF59E0B), 36.2, 37.1, false),
          ],
        ),
      ),
    );
  }

  Widget _vitalChart(String title, String current, String unit, Color color, IconData icon,
      Color iconColor, double minVal, double maxVal, bool isInt) {
    final data = List.generate(12, (i) {
      final rand = Random(i + title.hashCode);
      return minVal + rand.nextDouble() * (maxVal - minVal);
    });
    data[0] = isInt ? int.parse(current).toDouble() : double.parse(current);
    final trend = data[0] > data[1] ? '↑' : '↓';
    final trendUp = data[0] > data[1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  Text('$current$unit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trendUp ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(trend,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: trendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: LineChartPainter(data, color, minVal, maxVal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bpChart() {
    final sysData = List.generate(12, (i) => 110.0 + Random(i + 1).nextDouble() * 25);
    final diaData = List.generate(12, (i) => 70.0 + Random(i + 2).nextDouble() * 18);
    sysData[0] = 120;
    diaData[0] = 80;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monitor_heart, color: Color(0xFF8B5CF6), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Blood Pressure', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(text: '120', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF8B5CF6))),
                      TextSpan(text: '/', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF7D6B82))),
                      TextSpan(text: '80', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF8B5CF6))),
                    ]),
                  ),
                  const SizedBox(width: 6),
                  const Text('mmHg', style: TextStyle(fontSize: 11, color: Color(0xFF7D6B82))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(const Color(0xFF8B5CF6), 'Systolic'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFC084FC), 'Diastolic'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: DualLineChartPainter(sysData, diaData, const Color(0xFF8B5CF6), const Color(0xFFC084FC)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7D6B82))),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minVal;
  final double maxVal;

  LineChartPainter(this.data, this.color, this.minVal, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final range = maxVal - minVal;
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range) * size.height * 0.85;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - ((data[i - 1] - minVal) / range) * size.height * 0.85;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    final firstY = size.height - ((data[0] - minVal) / range) * size.height * 0.85;
    canvas.drawCircle(Offset(0, firstY), 4, dotPaint);
    canvas.drawCircle(Offset(0, firstY), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DualLineChartPainter extends CustomPainter {
  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;

  DualLineChartPainter(this.data1, this.data2, this.color1, this.color2);

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, size, data1, color1);
    _drawLine(canvas, size, data2, color2);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - 60) / 100) * size.height * 0.85;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - ((data[i - 1] - 60) / 100) * size.height * 0.85;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    final firstY = size.height - ((data[0] - 60) / 100) * size.height * 0.85;
    canvas.drawCircle(Offset(0, firstY), 4, dotPaint);
    canvas.drawCircle(Offset(0, firstY), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
