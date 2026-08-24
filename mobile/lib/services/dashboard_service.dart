import '../core/network/api_client.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  DashboardService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<DashboardStats> fetchStats() async {
    final dynamic data = await _client.get('/dashboard/stats');
    return DashboardStats.fromJson(
        Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
  }
}
