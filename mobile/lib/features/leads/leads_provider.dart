import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/api_exception.dart';
import '../../models/lead.dart';
import '../../models/paginated.dart';
import '../../models/user.dart';
import '../../services/lead_service.dart';
import '../dashboard/dashboard_provider.dart' show ViewState;

class LeadsProvider extends ChangeNotifier {
  LeadsProvider({required LeadService leadService}) : _leadService = leadService;

  final LeadService _leadService;

  final List<Lead> _leads = <Lead>[];
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  String _search = '';
  LeadFilters _filters = const LeadFilters();
  int _page = 1;
  int _total = 0;
  bool _hasNextPage = false;
  bool _loadingMore = false;
  Timer? _debounce;

  List<Lead> get leads => List<Lead>.unmodifiable(_leads);
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  LeadFilters get filters => _filters;
  int get total => _total;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _loadingMore;
  bool get isEmpty => _leads.isEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Debounced so typing does not fire a request per keystroke.
  void onSearchChanged(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(AppConfig.searchDebounce, () {
      refresh();
    });
  }

  void applyFilters(LeadFilters filters) {
    _filters = filters;
    refresh();
  }

  void clearFilters() {
    _filters = const LeadFilters();
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final Paginated<Lead> result = await _leadService.fetchLeads(
        page: _page,
        limit: AppConfig.leadsPageSize,
        search: _search,
        filters: _filters,
      );
      _leads
        ..clear()
        ..addAll(result.items);
      _total = result.total;
      _hasNextPage = result.hasNextPage;
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

  Future<void> loadMore() async {
    if (!_hasNextPage || _loadingMore || _state == ViewState.loading) {
      return;
    }
    _loadingMore = true;
    notifyListeners();

    try {
      final Paginated<Lead> result = await _leadService.fetchLeads(
        page: _page + 1,
        limit: AppConfig.leadsPageSize,
        search: _search,
        filters: _filters,
      );
      _page += 1;
      _leads.addAll(result.items);
      _total = result.total;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to connect. Please try again.';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Keeps the list consistent after an edit made on the details screen.
  void replaceLead(Lead lead) {
    final int index = _leads.indexWhere((Lead item) => item.id == lead.id);
    if (index >= 0) {
      _leads[index] = lead;
      notifyListeners();
    }
  }

  void removeLead(String id) {
    _leads.removeWhere((Lead item) => item.id == id);
    _total = _total > 0 ? _total - 1 : 0;
    notifyListeners();
  }

  Future<List<AppUser>> agents() => _leadService.fetchAgents();
}
