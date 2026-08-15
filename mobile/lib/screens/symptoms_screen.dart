import 'package:flutter/material.dart';

class SymptomsScreen extends StatelessWidget {
  const SymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SymptomsBody();
  }
}

class _SymptomsBody extends StatefulWidget {
  @override
  State<_SymptomsBody> createState() => _SymptomsBodyState();
}

class _SymptomsBodyState extends State<_SymptomsBody> {
  int _selectedFilter = 0;
  final _filters = ['All', 'Headache', 'Swelling', 'Nausea', 'Fatigue', 'Pain'];

  final List<_SymptomEntry> _symptoms = [
    _SymptomEntry(
      type: _SymptomType.headache,
      severity: 3,
      description: 'Moderate headache behind the eyes since morning. Worsens with bright light.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      flagged: true,
    ),
    _SymptomEntry(
      type: _SymptomType.swelling,
      severity: 2,
      description: 'Mild swelling in both ankles by end of day. Reduces overnight.',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      flagged: false,
    ),
    _SymptomEntry(
      type: _SymptomType.nausea,
      severity: 4,
      description: 'Severe nausea after lunch. Could not keep fluids down for about an hour.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      flagged: true,
    ),
    _SymptomEntry(
      type: _SymptomType.fatigue,
      severity: 2,
      description: 'General tiredness throughout the day. Needed extra nap in the afternoon.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      flagged: false,
    ),
    _SymptomEntry(
      type: _SymptomType.backPain,
      severity: 5,
      description: 'Sharp lower back pain when standing for more than 10 minutes.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      flagged: true,
    ),
    _SymptomEntry(
      type: _SymptomType.headache,
      severity: 1,
      description: 'Very mild headache, resolved on its own within 30 minutes.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      flagged: false,
    ),
    _SymptomEntry(
      type: _SymptomType.mood,
      severity: 3,
      description: 'Feeling anxious and irritable today. Difficulty concentrating.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      flagged: false,
    ),
  ];

  List<_SymptomEntry> get _filteredSymptoms {
    if (_selectedFilter == 0) return _symptoms;
    final filterName = _filters[_selectedFilter].toLowerCase();
    return _symptoms.where((s) => s.type.label.toLowerCase() == filterName).toList();
  }

  void _showLogBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSymptoms;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Symptoms',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14142B),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showLogBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D95),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Log',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFF2D95) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFF2D95)
                              : const Color(0xFFFFD3E7),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF7D6B82),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _SymptomCard(symptom: filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD3E7).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.healing_outlined,
                size: 52,
                color: Color(0xFFFF73B8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No symptoms logged',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the Log button to record how you\'re feeling today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7D6B82),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Symptom Types ──────────────────────────────────────────────────────────

enum _SymptomType {
  headache('Headache', Icons.psychology_outlined),
  swelling('Swelling', Icons.water_drop_outlined),
  nausea('Nausea', Icons.sick_outlined),
  fatigue('Fatigue', Icons.battery_1_bar_outlined),
  backPain('Back Pain', Icons.accessibility_new_outlined),
  mood('Mood', Icons.sentiment_neutral_outlined);

  final String label;
  final IconData icon;
  const _SymptomType(this.label, this.icon);
}

// ─── Symptom Entry Model ────────────────────────────────────────────────────

class _SymptomEntry {
  final _SymptomType type;
  final int severity;
  final String description;
  final DateTime timestamp;
  final bool flagged;

  const _SymptomEntry({
    required this.type,
    required this.severity,
    required this.description,
    required this.timestamp,
    required this.flagged,
  });
}

// ─── Symptom Card ───────────────────────────────────────────────────────────

class _SymptomCard extends StatelessWidget {
  final _SymptomEntry symptom;
  const _SymptomCard({required this.symptom});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD3E7), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D95).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(symptom.type.icon, color: const Color(0xFFFF2D95), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          symptom.type.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF14142B),
                          ),
                        ),
                        if (symptom.flagged) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2D95).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag, color: Color(0xFFFF2D95), size: 12),
                                SizedBox(width: 3),
                                Text(
                                  'AI Flagged',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF2D95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(symptom.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7D6B82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Container(
                width: 24,
                height: 8,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: index < symptom.severity
                      ? const Color(0xFFFF2D95)
                      : const Color(0xFFFFD3E7),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            symptom.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7D6B82),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Bottom Sheet ───────────────────────────────────────────────────────

class _LogBottomSheet extends StatefulWidget {
  const _LogBottomSheet();

  @override
  State<_LogBottomSheet> createState() => _LogBottomSheetState();
}

class _LogBottomSheetState extends State<_LogBottomSheet> {
  _SymptomType? _selectedType;
  double _severity = 3;
  final _descriptionController = TextEditingController();

  final _symptomTypes = const [
    (_SymptomType.headache, 'Headache'),
    (_SymptomType.swelling, 'Swelling'),
    (_SymptomType.nausea, 'Nausea'),
    (_SymptomType.fatigue, 'Fatigue'),
    (_SymptomType.backPain, 'Back Pain'),
    (_SymptomType.mood, 'Mood'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD3E7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Log a Symptom',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tell us how you\'re feeling.',
              style: TextStyle(fontSize: 14, color: Color(0xFF7D6B82)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Symptom Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _symptomTypes.length,
              itemBuilder: (context, index) {
                final (type, label) = _symptomTypes[index];
                final selected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF2D95).withOpacity(0.08)
                          : const Color(0xFFFFF8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFF2D95)
                            : const Color(0xFFFFD3E7),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          size: 28,
                          color: selected
                              ? const Color(0xFFFF2D95)
                              : const Color(0xFF7D6B82),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? const Color(0xFFFF2D95)
                                : const Color(0xFF7D6B82),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Severity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14142B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D95).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _severity.round().toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF2D95),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFFF2D95),
                inactiveTrackColor: const Color(0xFFFFD3E7),
                thumbColor: const Color(0xFFFF2D95),
                overlayColor: const Color(0xFFFF2D95).withOpacity(0.1),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: _severity,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => _severity = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Mild', style: TextStyle(fontSize: 11, color: Color(0xFF7D6B82))),
                Text('Severe', style: TextStyle(fontSize: 11, color: Color(0xFF7D6B82))),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe what you\'re experiencing...',
                hintStyle: const TextStyle(color: Color(0xFF7D6B82), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFFFF8FC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFFD3E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFFD3E7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFF2D95), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedType == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_selectedType!.label} logged successfully',
                            ),
                            backgroundColor: const Color(0xFFFF2D95),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D95),
                  disabledBackgroundColor: const Color(0xFFFFD3E7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Symptom',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
