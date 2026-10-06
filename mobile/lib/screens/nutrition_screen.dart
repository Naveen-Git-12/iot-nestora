import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  Map<String, dynamic>? _guide;
  final Set<String> _chosen = {};

  int _calTarget = 2200;
  int _calConsumed = 1700;
  int _water = 6;
  int _waterTarget = 8;
  final List<Map<String, dynamic>> _meals = [
    {
      'name': 'Breakfast',
      'time': '8:00 AM',
      'items': [
        {'name': 'Oatmeal with banana', 'cal': 280},
        {'name': 'Milk (250ml)', 'cal': 140},
      ]
    },
    {
      'name': 'Lunch',
      'time': '12:30 PM',
      'items': [
        {'name': 'Rice', 'cal': 200},
        {'name': 'Dal', 'cal': 120},
        {'name': 'Vegetables', 'cal': 80},
        {'name': 'Curd', 'cal': 180},
      ]
    },
    {
      'name': 'Snack',
      'time': '4:00 PM',
      'items': [
        {'name': 'Almonds (10)', 'cal': 70},
        {'name': 'Apple', 'cal': 140},
      ]
    },
    {
      'name': 'Dinner',
      'time': '7:30 PM',
      'items': [
        {'name': 'Roti (2)', 'cal': 180},
        {'name': 'Paneer', 'cal': 200},
        {'name': 'Salad', 'cal': 110},
      ]
    },
  ];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await SessionService.loadProfile();
    final data = await ApiService.getNutrition(
        (profile['patientId'] as String?) ?? 'P001');
    if (!mounted) return;
    setState(() {
      final dc = data['daily_calories'] as Map<String, dynamic>?;
      if (dc != null) {
        _calTarget = (dc['target'] as num?)?.toInt() ?? 2200;
        _calConsumed = (dc['consumed'] as num?)?.toInt() ?? 1700;
      }
      _water = (data['water_glasses'] as num?)?.toInt() ?? 6;
      _waterTarget = (data['water_target'] as num?)?.toInt() ?? 8;
      _loading = false;
    });
    final guide = await ApiService.getNutritionGuide(
        (profile['patientId'] as String?) ?? 'P001');
    if (!mounted) return;
    setState(() => _guide = guide);
  }

  void _toggleWater(int index) {
    setState(() {
      // tapping glass i: fill up to i+1, or unfills if already exactly there
      _water = (_water == index + 1) ? index : index + 1;
    });
  }

  void _showAddFood(int mealIndex) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to ${_meals[mealIndex]['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Food name')),
            TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Calories (cal)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final cal = int.tryParse(calCtrl.text.trim()) ?? 0;
              if (name.isEmpty) return;
              setState(() {
                (_meals[mealIndex]['items'] as List)
                    .add({'name': name, 'cal': cal});
                _calConsumed += cal;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D95),
                foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nutrition',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14142B))),
                      Text("Today's intake",
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF7D6B82))),
                    ],
                  ),
                  if (_loading)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              if (_guide != null) ...[
                _recommendations(),
                const SizedBox(height: 24),
              ],
              _calorieSummary(),
              const SizedBox(height: 20),
              _nutrientProgress(),
              const SizedBox(height: 20),
              _waterTracker(),
              const SizedBox(height: 20),
              ..._meals.asMap().entries.map((e) => _mealSection(
                  e.value['name'] as String,
                  e.value['time'] as String,
                  (e.value['items'] as List)
                      .map((m) => _mealItem(
                          m['name'] as String, m['cal'] as int, () {
                            setState(() {
                              (e.value['items'] as List).remove(m);
                              _calConsumed -= (m['cal'] as int);
                            });
                          }))
                      .toList(),
                  () => _showAddFood(e.key))),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }


  Widget _recommendations() {
    final g = _guide!;
    final week = g['gestational_week'];
    final trimester = (g['trimester'] as String?) ?? '';
    final focus = ((g['focus'] as List?)?.cast<String>()) ?? [];
    final meals = ((g['meals'] as List?) ?? [])
        .whereType<Map>()
        .toList();
    final hydration = (g['hydration'] as String?) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested for Week $week',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(trimester,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (focus.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...focus.map((f) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.35)),
                        ),
                      ],
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pick what suits you — these are suggestions, not a fixed diet.',
          style: TextStyle(fontSize: 11, color: Color(0xFF7D6B82)),
        ),
        const SizedBox(height: 14),
        ...meals.map((meal) {
          final name = (meal['meal'] as String?) ?? '';
          final options = ((meal['options'] as List?) ?? [])
              .whereType<Map>()
              .toList();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                ...options.map((o) {
                  final key = '$name|${o['name']}';
                  final picked = _chosen.contains(key);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (picked) {
                        _chosen.remove(key);
                      } else {
                        _chosen.add(key);
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: picked
                            ? const Color(0xFF7B1FA2).withValues(alpha: 0.07)
                            : const Color(0xFFFFF8FC),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: picked
                              ? const Color(0xFF7B1FA2)
                              : const Color(0xFFFFD3E7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            picked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 17,
                            color: picked
                                ? const Color(0xFF7B1FA2)
                                : const Color(0xFF7D6B82),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${o['name']}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text('${o['benefit']}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7D6B82))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        if (hydration.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.water_drop,
                    size: 18, color: Color(0xFF3B82F6)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(hydration,
                      style: const TextStyle(fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        if (_chosen.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
              'Selected ${_chosen.length} option${_chosen.length == 1 ? '' : 's'} for today',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B1FA2))),
        ],
      ],
    );
  }

  Widget _calorieSummary() {
    final remaining = (_calTarget - _calConsumed).clamp(0, 99999);
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
          _calorieCircle('Consumed', _calConsumed, _calTarget, Colors.white),
          _calorieCircle('Remaining', remaining, _calTarget, Colors.white70),
          _calorieCircle('Burned', 320, 1000, Colors.white70),
        ],
      ),
    );
  }

  Widget _calorieCircle(String label, int current, int goal, Color textColor) {
    final progress = goal == 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);
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
              Text('$current',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrients',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _nutrientBar('Protein', 45, 60, 'g', const Color(0xFFEF4444)),
          _nutrientBar('Iron', 18, 27, 'mg', const Color(0xFFF59E0B)),
          _nutrientBar('Calcium', 800, 1200, 'mg', const Color(0xFF3B82F6)),
          _nutrientBar('Folate', 400, 600, 'mcg', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _nutrientBar(
      String name, int current, int goal, String unit, Color color) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
              width: 70,
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500))),
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
          SizedBox(
              width: 70,
              child: Text('$current/$goal$unit',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF7D6B82)),
                  textAlign: TextAlign.right)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Water Intake',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$_water/$_waterTarget glasses',
                  style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Tap a glass to update',
              style: TextStyle(fontSize: 11, color: Color(0xFF7D6B82))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_waterTarget, (i) {
              final filled = i < _water;
              return GestureDetector(
                onTap: () => _toggleWater(i),
                child: Icon(
                  Icons.local_drink,
                  size: 32,
                  color: filled
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE5E7EB),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _mealSection(
      String meal, String time, List<Widget> items, VoidCallback onAdd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meal,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Text(time,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7D6B82))),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D95)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          size: 18, color: Color(0xFFFF2D95)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _mealItem(String name, int cal, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF2D95), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Row(
            children: [
              Text('$cal cal',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7D6B82),
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
