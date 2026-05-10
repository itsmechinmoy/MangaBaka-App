import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class BrowseController extends ChangeNotifier {
  static final _logger = LoggingService.logger;
  final SeriesSearchService _searchService = getIt<SeriesSearchService>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  List<Series> _searchResults = [];
  List<Series> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;

  int _currentPage = 1;
  bool _hasMore = true;

  SearchFilters _currentFilters = SearchFilters();
  SearchFilters get currentFilters => _currentFilters;

  bool _showBackToTop = false;
  bool get showBackToTop => _showBackToTop;

  BrowseController() {
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isNearEnd = scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - AppConstants.scrollThresholdPx;

    if (isNearEnd &&
        _hasMore &&
        !_isLoadingMore &&
        (_currentSearchQuery.isNotEmpty || _currentFilters.toMap().isNotEmpty)) {
      _logger.fine('Near end of scroll, loading more results for query: "$_currentSearchQuery"');
      loadMoreResults();
    }

    final showBackToTop = scrollController.offset > 500;
    if (showBackToTop != _showBackToTop) {
      _showBackToTop = showBackToTop;
      notifyListeners();
    }
  }

  void resetSearchState() {
    _logger.fine('Resetting search state');
    _searchResults = [];
    _error = null;
    _currentSearchQuery = '';
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();
  }

  void updateSearchQuery(String text) {
    _currentSearchQuery = text;
    if (text.isEmpty && _currentFilters.toMap().isEmpty) {
      resetSearchState();
    }
  }

  void updateFilters(SearchFilters filters) {
    _logger.info('Filters updated: ${filters.toMap()}');
    _currentFilters = filters;
    searchSeries();
  }

  Future<void> searchSeries() async {
    if (_currentSearchQuery.trim().isEmpty && _currentFilters.toMap().isEmpty) {
      _logger.fine('Search query and filters are empty, skipping search');
      resetSearchState();
      return;
    }

    _logger.info('Starting new search for query: "$_currentSearchQuery" with filters: ${_currentFilters.toMap()}');
    _isLoading = true;
    _error = null;
    _searchResults = [];
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    await _fetchSearchResults();
  }

  Future<void> loadMoreResults() async {
    if (_isLoadingMore || !_hasMore) return;

    _logger.info('Loading more results for query: "$_currentSearchQuery", page: ${_currentPage + 1}');
    _isLoadingMore = true;
    notifyListeners();
    
    _currentPage++;
    await _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    try {
      String? userId;
      if (SettingsManager().hideLibrarySeriesInBrowse) {
        final auth = getIt<ProfileAuthService>();
        if (auth.isLoggedIn) {
          final profile = auth.cachedProfile;
          if (profile != null) {
            userId = profile.id.replaceAll('-', '');
            _logger.fine('Hiding library series for user: $userId');
          }
        }
      }

      final extraParams = <String, dynamic>{
        'page': _currentPage,
        'limit': AppConstants.defaultPageLimit,
        ..._currentFilters.toMap(),
      };

      if (userId != null && userId.isNotEmpty) {
        extraParams['exclude_user_library'] = userId;
      }

      final newResults = await _searchService.searchSeriesByName(
        _currentSearchQuery,
        extraParams: extraParams,
      );

      _logger.info('Fetched ${newResults.length} results for page $_currentPage');

      _hasMore = newResults.length == AppConstants.defaultPageLimit;
      _isLoading = false;
      _isLoadingMore = false;
      _searchResults.addAll(newResults);
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to fetch search results for query "$_currentSearchQuery" at page $_currentPage: $e');
      _isLoading = false;
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  static double generateRandomSeed() {
    return Random().nextDouble();
  }

  Future<String?> handleBarcodeScan(String isbn) async {
    if (isbn.isEmpty) return null;

    _logger.info('Handling barcode scan for ISBN: $isbn');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final lookupService = BookLookupService();
      final title = await lookupService.lookupTitleByIsbn(isbn);

      if (title != null && title.isNotEmpty) {
        _logger.info('Found title from ISBN: $title');
        searchController.text = title;
        _currentSearchQuery = title;
        await searchSeries();

        if (_searchResults.isNotEmpty) {
          _logger.info('Successfully found series for ISBN title: $title');
          return null;
        } else {
          final cleanedTitle = BrowseHelpers.cleanTitle(title);
          if (cleanedTitle != title && cleanedTitle.isNotEmpty) {
            _logger.info('No results for raw title, trying cleaned title: $cleanedTitle');
            searchController.text = cleanedTitle;
            _currentSearchQuery = cleanedTitle;
            await searchSeries();
            if (_searchResults.isNotEmpty) {
              return null;
            }
          }
          _logger.warning('No series found for title associated with ISBN: $isbn (Title: $title)');
          return 'no_series_found_for';
        }
      } else {
        _logger.warning('No title found for ISBN: $isbn');
        _isLoading = false;
        notifyListeners();
        return 'barcode_not_found';
      }
    } catch (e) {
      _logger.severe('Error handling barcode scan for ISBN $isbn: $e');
      _isLoading = false;
      notifyListeners();
      return 'barcode_lookup_failed';
    }
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: AppConstants.mediumAnimationDuration,
      curve: Curves.easeInOut,
    );
  }
}
