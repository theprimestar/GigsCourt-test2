import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/imagekit_service.dart';

class ProviderDetailSheet extends StatelessWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onMessage;
  final VoidCallback onViewProfile;
  final ImageKitService imageKitService;

  const ProviderDetailSheet({
    super.key,
    required this.provider,
    required this.onMessage,
    required this.onViewProfile,
    required this.imageKitService,
  });

  String _formatDistance(dynamic meters) {
    if (meters == null) return '';
    final m = meters is double ? meters : meters.toDouble();
    if (m < 1000) return '${m.round()}m away';
    return '${(m / 1000).toStringAsFixed(1)}km away';
  }

  String _formatJoined(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp is DateTime ? timestamp : DateTime.tryParse(timestamp.toString());
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final rating = provider['rating'] ?? 0;
    final reviewCount = provider['review_count'] ?? 0;
    final gigsThisMonth = provider['gigs_this_month'] ?? 0;
    final gigCount = provider['gig_count'] ?? 0;
    final isActive = provider['is_active'] ?? false;
    final profilePicUrl = provider['profile_pic_url'];
    final services = List<String>.from(provider['services'] ?? []);
    final address = provider['workspace_address'] ?? '';
    final distanceMeters = provider['distance_meters'];
    final fullName = provider['full_name'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? const Color(0xFF34C759) : (isDark ? Colors.white24 : const Color(0xFFE5E5EA)),
                    width: 3,
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: profilePicUrl != null
                    ? ClipOval(
                        child: Image.network(
                          imageKitService.getOptimizedUrl(profilePicUrl, width: 300),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, size: 36, color: isDark ? Colors.white38 : Colors.black38),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Name + active dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fullName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Stars + review count
          if (reviewCount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) {
                  final avgRating = rating / reviewCount;
                  return Icon(
                    i < avgRating.round() ? Icons.star : Icons.star_border,
                    size: 14,
                    color: const Color(0xFFFFB800),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  '${(rating / reviewCount).toStringAsFixed(1)} · $reviewCount review${reviewCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73)),
                ),
              ],
            )
          else
            Text(
              'No ratings yet',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
            ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat(gigsThisMonth.toString(), 'This Month', isDark),
              const SizedBox(width: 24),
              _buildStat(gigCount.toString(), 'Total Gigs', isDark),
              const SizedBox(width: 24),
              _buildStat(_formatJoined(provider['created_at']), 'Joined', isDark),
            ],
          ),
          const SizedBox(height: 12),
          // Distance badge
          if (distanceMeters != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F6F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDistance(distanceMeters),
                style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73)),
              ),
            ),
          const SizedBox(height: 12),
          // Address
          if (address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF3B5FE3)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Service chips
          if (services.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: services.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F6F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.replaceAll('-', ' '),
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A)),
                ),
              )).toList(),
            ),
          const SizedBox(height: 16),
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onMessage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5FE3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Message', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onViewProfile();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE5E5EA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('View Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73))),
      ],
    );
  }
}
