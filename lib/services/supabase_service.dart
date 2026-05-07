import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getServices() async {
    final response = await _client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('category')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> requestCustomService({
    required String userId,
    required String serviceName,
  }) async {
    await _client.from('service_requests').insert({
      'user_id': userId,
      'requested_name': serviceName.trim(),
      'status': 'pending',
    });
  }

  Future<void> saveProfileLocation({
    required String userId,
    required double lat,
    required double lng,
    required String address,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'workspace_lat': lat,
      'workspace_lng': lng,
      'workspace_address': address,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
