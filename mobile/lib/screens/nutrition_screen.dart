import 'dart:math';
import 'package:flutter/material.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nutrition', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14142B))),
            const SizedBox(height: 4),
            const Text('Today\'s intake', style: TextStyle(fontSize: 13, color: Color(0xFF7D6B82))),
            const SizedBox(height: 20),

            _calorieSummary(),
            const SizedBox(height: 20),
            _nutrientProgress(),
            const SizedBox(height: 20),
            _waterTracker(),
            const SizedBox(height: 20),
            _mealSection('Breakfast', '8:00 AM', [
              _mealItem('Oatmeal with banana', 280),
              _mealItem('Milk (250ml)', 140),
            ]),
            _mealSection('Lunch', '12:30 PM', [
              _mealItem('Rice', 200),
              _mealItem('Dal', 120),
              _mealItem('Vegetables', 80),
              _mealItem('Curd', 180),
            ]),
            _mealSection('Snack', '4:00 PM', [
              _mealItem('Almonds (10)', 70),
              _mealItem('Apple', 140),
            ]),
            _mealSection('Dinner', '7:30 PM', [
              _mealItem('Roti (2)', 180),
              _mealItem('Paneer', 200),
              _mealItem('Salad', 110),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _calorieSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2D95), Color(0xFFFF73B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _calorieCircle('Consumed', 1700, 2200, Colors.white),
          _calorieCircle('Remaining', 500, 2200, Colors.white70),
          _calorieCircle('Burned', 320, 1000, Colors.white70),
        ],
      ),
    );
  }

  Widget _calorieCircle(String label, int current, int goal, Color textColor) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Text('$current', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: textColor, fontSize: 11)),
      ],
    );
  }

  Widget _nutrientProgress() {
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
          const Text('Nutrients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _nutrientBar('Protein', 45, 60, 'g', const Color(0xFFEF4444)),
          _nutrientBar('Iron', 18, 27, 'mg', const Color(0xFFF59E0B)),
          _nutrientBar('Calcium', 800, 1200, 'mg', const Color(0xFF3B82F6)),
          _nutrientBar('Folate', 400, 600, 'mcg', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _nutrientBar(String name, int current, int goal, String unit, Color color) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text('$current/$goal$unit', style: const TextStyle(fontSize: 11, color: Color(0xFF7D6B82)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _waterTracker() {
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
              const Text('Water Intake', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('6/8 glasses', style: TextStyle(color: const Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(8, (i) {
              final filled = i < 6;
              return Icon(
                Icons.local_drink,
                size: 32,
                color: filled ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _mealSection(String meal, String time, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Text(meal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF7D6B82))),
            ],
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _mealItem(String name, int cal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFF2D95), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text('$cal cal', style: const TextStyle(fontSize: 12, color: Color(0xFF7D6B82), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
