import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';
import '../services/imagekit_service.dart';
import '../services/firestore_service.dart';
import 'onboarding_steps_12.dart';
import 'onboarding_steps_34.dart';

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
  final ImageKitService _imageKitService = ImageKitService();
  final FirestoreService _firestoreService = FirestoreService();

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestoreService.saveProfile(
        userId: user.uid,
        fullName: _data['fullName'] ?? '',
        services: List<String>.from(_data['services'] ?? []),
        bio: _data['bio'] ?? '',
        phone: _data['phone'] ?? '',
        profilePicUrl: _data['profilePicUrl'],
        workPhotos: _data['workPhotos'] != null
            ? List<String>.from(_data['workPhotos'])
            : null,
      );

      await _supabaseService.saveProfileLocation(
        userId: user.uid,
        lat: _data['workspaceLat'] ?? 0.0,
        lng: _data['workspaceLng'] ?? 0.0,
        address: _data['workspaceAddress'] ?? '',
      );

      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kDebugMode ? e.toString() : 'Something went wrong. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF7F6F4),
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return StepNameServices(
          key: const ValueKey('step1'),
          initialData: _data,
          supabaseService: _supabaseService,
          onNext: _nextStep,
        );
      case 2:
        return StepLocation(
          key: const ValueKey('step2'),
          initialData: _data,
          supabaseService: _supabaseService,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 3:
        return StepPhotoBio(
          key: const ValueKey('step3'),
          initialData: _data,
          imageKitService: _imageKitService,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      case 4:
        return StepWalkthrough(
          key: const ValueKey('step4'),
          initialData: _data,
          onNext: _nextStep,
          onBack: _previousStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
