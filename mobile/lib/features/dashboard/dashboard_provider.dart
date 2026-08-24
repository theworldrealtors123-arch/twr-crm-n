import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../models/dashboard_stats.dart';
import '../../services/dashboard_service.dart';

enum ViewState { idle, loading, ready, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required DashboardService dashboardService})
      : _dashboardService = dashboardService;

  final DashboardService _dashboardService;

  ViewState _state = ViewState.idle;
  DashboardStats _stats = DashboardStats.empty;
  String? _errorMessage;

  ViewState get state => _state;
  DashboardStats get stats => _stats;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _dashboardService.fetchStats();
      _state = ViewState.ready;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _state = ViewState.error;
    } catch (_) {
      _errorMessage = 'Unable to connect. Please try again.';
      _state = ViewState.error;
    }
    notifyListeners();
  }
}
