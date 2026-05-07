import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/imagekit_service.dart';

// ────────────────────────────────────────
// STEP 3: Profile Picture + Bio + Phone
// ────────────────────────────────────────
class StepPhotoBio extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ImageKitService imageKitService;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const StepPhotoBio({super.key, required this.initialData, required this.imageKitService, required this.onNext, required this.onBack});

  @override
  State<StepPhotoBio> createState() => _StepPhotoBioState();
}

class _StepPhotoBioState extends State<StepPhotoBio> {
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  String? _profilePicUrl;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.initialData['bio'] ?? '';
    _phoneController.text = widget.initialData['phone'] ?? '';
    _profilePicUrl = widget.initialData['profilePicUrl'];
  }

  @override
  void dispose() { _bioController.dispose(); _phoneController.dispose(); super.dispose(); }

  Future<void> _pickAndUploadPhoto() async {
    HapticFeedback.mediumImpact();
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF3B5FE3),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(title: 'Crop Photo', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
        ],
      );
      if (cropped == null) return;

      setState(() => _uploading = true);

      final bytes = await File(cropped.path).readAsBytes();
      final url = await widget.imageKitService.uploadPhoto(
        fileBytes: bytes,
        fileName: 'profile.jpg',
        folder: '/profiles',
      );

      if (mounted) {
        setState(() { _profilePicUrl = url; _uploading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _uploading = false; _error = kDebugMode ? e.toString() : 'Failed to upload photo.'; });
      }
    }
  }

  void _handleContinue() {
    if (_bioController.text.trim().isEmpty) { setState(() => _error = 'Please tell us about yourself.'); return; }
    if (_phoneController.text.trim().isEmpty) { setState(() => _error = 'Please enter your phone number.'); return; }
    widget.onNext({'bio': _bioController.text.trim(), 'phone': _phoneController.text.trim(), 'profilePicUrl': _profilePicUrl});
  }

  void _handleSkip() {
    widget.onNext({'bio': _bioController.text.trim(), 'phone': _phoneController.text.trim(), 'profilePicUrl': null});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          onPressed: () { HapticFeedback.lightImpact(); widget.onBack(); },
          icon: const Icon(Icons.arrow_back_ios, size: 14), label: const Text('Back', style: TextStyle(fontSize: 14)),
          style: TextButton.styleFrom(foregroundColor: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73), padding: EdgeInsets.zero),
        )),
        const SizedBox(height: 16),
        Text('Your profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A), letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('Let clients know who you are', style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73))),
        const SizedBox(height: 28),
        Center(child: GestureDetector(
          onTap: _uploading ? null : _pickAndUploadPhoto,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE8E8ED),
              border: Border.all(color: _profilePicUrl != null ? const Color(0xFF3B5FE3) : (isDark ? Colors.white10 : const Color(0xFFE5E5EA)), width: _profilePicUrl != null ? 3 : 2),
            ),
            child: _uploading
                ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B5FE3))))
                : _profilePicUrl != null
                    ? ClipOval(child: Image.network(_profilePicUrl!, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 28, color: isDark ? Colors.white38 : Colors.black38), const SizedBox(height: 4), Text('Add Photo', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38))]),
          ),
        )),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: _handleSkip, child: Text('Skip for now', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)))),
        const SizedBox(height: 24),
        TextField(
          controller: _bioController, minLines: 3, maxLines: 5,
          style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: 'Describe your experience, skills, and what clients can expect...', hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
            filled: true, fillColor: isDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E5EA))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E5EA))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B5FE3), width: 1.5)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController, keyboardType: TextInputType.phone,
          style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: '+234 800 000 0000', hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
            filled: true, fillColor: isDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E5EA))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E5EA))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B5FE3), width: 1.5)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
      ]))),
      if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFF3B30).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error_outline, color: Color(0xFFFF3B30), size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13)))]))),
      const SizedBox(height: 12),
      Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 20), child: Row(children: [
        Expanded(child: OutlinedButton(onPressed: () { HapticFeedback.lightImpact(); widget.onBack(); }, style: OutlinedButton.styleFrom(foregroundColor: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFE5E5EA)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: _handleContinue, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B5FE3), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
    ]);
  }
}

// ────────────────────────────────────────
// STEP 4: Walkthrough
// ────────────────────────────────────────
class StepWalkthrough extends StatelessWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const StepWalkthrough({super.key, required this.initialData, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final cards = [
      {'icon': Icons.location_on_outlined, 'title': 'Find Services Nearby', 'description': 'Browse providers by distance. See their ratings, completed gigs, and active status before you reach out.'},
      {'icon': Icons.chat_bubble_outline, 'title': 'Chat and Connect', 'description': 'Message providers directly. Discuss your needs, ask questions, and agree on details before booking.'},
      {'icon': Icons.check_circle_outline, 'title': 'Register Gigs, Build Trust', 'description': 'After working with someone, register your gig. It builds your reputation and helps others find trusted providers.'},
      {'icon': Icons.star_outline, 'title': 'Your Reputation Grows', 'description': 'Every completed gig earns you a review. Reviews help you rank higher in search results.'},
    ];

    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          onPressed: () { HapticFeedback.lightImpact(); onBack(); },
          icon: const Icon(Icons.arrow_back_ios, size: 14), label: const Text('Back', style: TextStyle(fontSize: 14)),
          style: TextButton.styleFrom(foregroundColor: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73), padding: EdgeInsets.zero),
        )),
        const SizedBox(height: 24),
        Text('Welcome to GigsCourt', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A), letterSpacing: -0.5), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Your local service marketplace', style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73)), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ...cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF0F0F0))),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF3B5FE3).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(card['icon'] as IconData, color: const Color(0xFF3B5FE3), size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card['title'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A))),
              const SizedBox(height: 4),
              Text(card['description'] as String, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73), height: 1.4)),
            ])),
          ]),
        ))),
        const SizedBox(height: 8),
        Text('You can update your profile anytime from Settings', style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.black26), textAlign: TextAlign.center),
        const SizedBox(height: 24),
      ]))),
      Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 20), child: Row(children: [
        Expanded(child: OutlinedButton(onPressed: () { HapticFeedback.lightImpact(); onBack(); }, style: OutlinedButton.styleFrom(foregroundColor: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFE5E5EA)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(onPressed: () => onNext({}), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B5FE3), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
    ]);
  }
}
