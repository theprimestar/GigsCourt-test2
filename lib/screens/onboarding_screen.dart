import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1;
  final Map<String, dynamic> _data = {};
  final SupabaseService _supabaseService = SupabaseService();

  void _nextStep(Map<String, dynamic> stepData) {
    setState(() {
      _data.addAll(stepData);
      if (_currentStep < 4) {
        HapticFeedback.mediumImpact();
        _currentStep++;
      } else {
        HapticFeedback.heavyImpact();
        _finishOnboarding();
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishOnboarding() async {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF7F6F4),
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isActive = i + 1 <= _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF3B5FE3)
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            // Step content
            Expanded(
              child: _buildStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _StepNameServices(
          initialData: _data,
          supabaseService: _supabaseService,
          onNext: _nextStep,
          onBack: () {},
          isFirstStep: true,
        );
      case 2:
        return _StepPlaceholder(
          title: 'Workspace Location',
          stepNumber: 2,
          onNext: () => _nextStep({}),
          onBack: _previousStep,
        );
      case 3:
        return _StepPlaceholder(
          title: 'Profile Picture & Bio',
          stepNumber: 3,
          onNext: () => _nextStep({}),
          onBack: _previousStep,
        );
      case 4:
        return _StepPlaceholder(
          title: 'Walkthrough',
          stepNumber: 4,
          onNext: () => _nextStep({}),
          onBack: _previousStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// Placeholder for steps 2-4
class _StepPlaceholder extends StatelessWidget {
  final String title;
  final int stepNumber;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _StepPlaceholder({
    required this.title,
    required this.stepNumber,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step $stepNumber',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5FE3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// STEP 1: Name + Services
// ─────────────────────────────────────
class _StepNameServices extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final SupabaseService supabaseService;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  final bool isFirstStep;

  const _StepNameServices({
    required this.initialData,
    required this.supabaseService,
    required this.onNext,
    required this.onBack,
    required this.isFirstStep,
  });

  @override
  State<_StepNameServices> createState() => _StepNameServicesState();
}

class _StepNameServicesState extends State<_StepNameServices> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _customController = TextEditingController();

  List<Map<String, dynamic>> _allServices = [];
  List<String> _selectedSlugs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialData['fullName'] ?? '';
    _selectedSlugs = List<String>.from(widget.initialData['services'] ?? []);
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services = await widget.supabaseService.getServices();
      if (mounted) {
        setState(() {
          _allServices = services;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = kDebugMode ? e.toString() : 'Failed to load services.';
          _loading = false;
        });
      }
    }
  }

  void _toggleService(String slug) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedSlugs.contains(slug)) {
        _selectedSlugs.remove(slug);
      } else {
        _selectedSlugs.add(slug);
      }
    });
  }

  Future<void> _requestCustomService() async {
    final name = _customController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.mediumImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await widget.supabaseService.requestCustomService(
        userId: user.uid,
        serviceName: name,
      );
      final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      setState(() {
        _selectedSlugs.add(slug);
        _customController.clear();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = kDebugMode ? e.toString() : 'Failed to add service.');
      }
    }
  }

  void _handleContinue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (_selectedSlugs.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Please select at least one service.');
      return;
    }
    widget.onNext({
      'fullName': name,
      'services': _selectedSlugs,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final searchQuery = _searchController.text.toLowerCase();
    final filtered = _allServices
        .where((s) => (s['name'] as String).toLowerCase().contains(searchQuery))
        .toList();

    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in filtered) {
      final cat = s['category'] as String;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(s);
    }

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps clients find you',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73),
                  ),
                ),
                const SizedBox(height: 24),
                // Name input
                Text(
                  'Full Name / Business Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. John Doe or JD Barbing',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                // Services label
                Text(
                  'What services do you offer?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73),
                  ),
                ),
                const SizedBox(height: 8),
                // Selected tags
                if (_selectedSlugs.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedSlugs.map((slug) {
                      return GestureDetector(
                        onTap: () => _toggleService(slug),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B5FE3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slug.replaceAll('-', ' '),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close, size: 14, color: Colors.white70),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (_selectedSlugs.isNotEmpty) const SizedBox(height: 12),
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Services by category
                if (_loading)
                  ...List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(4, (j) => Container(
                            width: j == 0 ? 80 : j == 1 ? 100 : j == 2 ? 70 : 90,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black12,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ))
                else
                  ...grouped.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((s) {
                              final slug = s['slug'] as String;
                              final selected = _selectedSlugs.contains(slug);
                              return GestureDetector(
                                onTap: () => _toggleService(slug),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF3B5FE3)
                                        : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF3B5FE3)
                                          : (isDark ? Colors.white12 : const Color(0xFFE5E5EA)),
                                    ),
                                  ),
                                  child: Text(
                                    s['name'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: selected
                                          ? Colors.white
                                          : (isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                // Custom service
                const SizedBox(height: 8),
                Text(
                  "Can't find your service?",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your service...',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _requestCustomService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5FE3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your request will be reviewed by our team.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Error + Continue button
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5FE3),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF3B5FE3).withAlpha(100),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
