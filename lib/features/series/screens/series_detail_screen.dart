import 'dart:ui';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/detail/series_detail_app_bar.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_mobile_layout.dart';
import 'package:mangabaka_app/features/series/widgets/layouts/series_detail_wide_layout.dart';
import 'package:mangabaka_app/features/series/widgets/detail/series_detail_error_banner.dart';
import 'package:mangabaka_app/features/series/widgets/detail/series_detail_fab.dart';
import 'package:mangabaka_app/features/series/widgets/detail/series_detail_tab_content.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_actions_mixin.dart';
import 'package:mangabaka_app/features/series/mixins/series_detail_data_mixin.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen>
    with SeriesDetailActionsMixin, SeriesDetailDataMixin {
  static final _logger = LoggingService.logger;
  late final LibraryService _libraryService;
  late final SeriesService _seriesService;
  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;
  bool _ready = false;
  String _selectedTab = 'Information';

  // Prefers the fully-fetched series; falls back to the shallow widget arg.
  Series get _activeSeries => fullSeries ?? widget.series;

  @override
  LibraryService get libraryService => _libraryService;

  @override
  Series get series => widget.series;

  @override
  bool get isAdding => _isAdding;

  @override
  set isAdding(bool value) => _isAdding = value;

  @override
  SeriesService get seriesService => _seriesService;

  @override
  String get selectedTab => _selectedTab;

  @override
  void initState() {
    super.initState();
    _logger.info(
      'Series detail screen initialized for series: ${widget.series.title} (${widget.series.id})',
    );
    _libraryService = getIt<LibraryService>();
    _seriesService = getIt<SeriesService>();
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
    fullSeries = widget.series;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });

    _logger.fine('Starting full data fetch for series: ${widget.series.id}');
    fetchFullData()
        .then((_) => _logger.info('Full data fetch complete for series: ${widget.series.id}'))
        .catchError((e) => _logger.severe('Full data fetch failed for series: ${widget.series.id}. Error: $e'));
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _navigateToAuthorSeries(String authorName) {
    _logger.info('Navigating to series by author: $authorName');
    Navigator.push(
      context,
      AppTransitions.slideRight(BrowseResultsScreen(
        sortType: authorName,
        sortBy: 'popularity_desc',
        staff: authorName,
      )),
    );
  }

  void _navigateToPublisherSeries(String publisherName) {
    _logger.info('Navigating to series by publisher: $publisherName');
    Navigator.push(
      context,
      AppTransitions.slideRight(BrowseResultsScreen(
        sortType: publisherName,
        sortBy: 'popularity_desc',
        publisher: publisherName,
      )),
    );
  }

  // -------------------------------------------------------------------------
  // Build helpers
  // -------------------------------------------------------------------------

  /// Resets the error/loading state and re-triggers the full data fetch.
  void _retryFetch() {
    setState(() {
      isDataLoaded = false;
      fetchError = false;
    });
    fetchFullData();
  }

  /// Builds the tab content widget shared by both the wide and mobile layouts.
  SeriesDetailTabContent _buildTabContent(
    LibraryEntry? entry,
    LocalizationService l10n,
    double hPadding, {
    bool isWide = false,
    bool wideRightPaddingOnly = false,
  }) {
    return SeriesDetailTabContent(
      series: _activeSeries,
      entry: entry,
      l10n: l10n,
      selectedTab: _selectedTab,
      covers: covers,
      related: related,
      news: news,
      collections: collections,
      works: works,
      enrichedLinks: enrichedLinks,
      isWide: isWide,
      hPadding: hPadding,
      wideRightPaddingOnly: wideRightPaddingOnly,
      onAuthorTap: _navigateToAuthorSeries,
      onPublisherTap: _navigateToPublisherSeries,
      onAddToLibrary: addSeriesToLibrary,
      onStateChanged: (s) => _libraryService.updateLibraryEntryState(_activeSeries.id, s),
      onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(_activeSeries.id, r),
      onUpdateChapter: () => entry != null ? showUpdateProgressDialog(entry, isChapter: true) : null,
      onUpdateVolume: () => entry != null ? showUpdateProgressDialog(entry, isChapter: false) : null,
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 20, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: AppConstants.primaryBackground,
        body: const SizedBox.expand(),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    final heroHeight = (isWide || isTablet) ? 500.0 : 380.0;
    const contentOverlap = 24.0;
    final contentStart = heroHeight - contentOverlap;

    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        ThemeManager(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: Actions(
            actions: <Type, Action<Intent>>{
              RefreshIntent: CallbackAction<RefreshIntent>(
                onInvoke: (_) { _retryFetch(); return null; },
              ),
            },
            child: StreamBuilder<LibraryEntry?>(
              stream: _entryStream,
              builder: (context, snapshot) {
                final entry = snapshot.data;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: RepaintBoundary(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background: hero cover (fixed height)
                          Positioned(
                            top: 0, left: 0, right: 0,
                            height: heroHeight,
                            child: SeriesDetailAppBar(
                              series: _activeSeries,
                              isWide: isWide || isTablet,
                              isLoaded: isDataLoaded,
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                          // Solid background fills the area below the hero
                          Positioned.fill(
                            top: heroHeight,
                            child: Container(color: AppConstants.primaryBackground),
                          ),
                          // Floating action buttons (share / delete)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _iconBtn(Icons.share, shareLink),
                                if (entry != null) const SizedBox(width: 4),
                                if (entry != null)
                                  _iconBtn(Icons.delete_outline, showDeleteConfirmationDialog),
                              ],
                            ),
                          ),
                          // Scrollable content overlapping the hero
                          Positioned(
                            top: contentStart,
                            left: 0, right: 0, bottom: 0,
                            child: CustomScrollView(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              slivers: [
                                if (fetchError)
                                  SeriesDetailErrorBanner(onRetry: _retryFetch),
                                SliverToBoxAdapter(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(AppConstants.largeRadius),
                                        topRight: Radius.circular(AppConstants.largeRadius),
                                      ),
                                    ),
                                    child: isWide
                                        ? SeriesDetailWideLayout(
                                            series: _activeSeries,
                                            entry: entry,
                                            l10n: l10n,
                                            isDataLoaded: isDataLoaded,
                                            selectedTab: _selectedTab,
                                            onTabChanged: (tab) {
                                              _logger.info('Series detail tab switched to: $tab');
                                              setState(() => _selectedTab = tab);
                                              fetchTabData(tab);
                                            },
                                            onStateChanged: (s) => _libraryService.updateLibraryEntryState(_activeSeries.id, s),
                                            onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(_activeSeries.id, r),
                                            onUpdateChapter: () => entry != null ? showUpdateProgressDialog(entry, isChapter: true) : null,
                                            onUpdateVolume: () => entry != null ? showUpdateProgressDialog(entry, isChapter: false) : null,
                                            onUpdateRating: () => entry != null ? showUpdateRatingDialog(entry) : null,
                                            buildTabContent: (hPadding, {isWide = false, wideRightPaddingOnly = false}) =>
                                                _buildTabContent(entry, l10n, hPadding, isWide: isWide, wideRightPaddingOnly: wideRightPaddingOnly),
                                          )
                                        : SeriesDetailMobileLayout(
                                            series: _activeSeries,
                                            entry: entry,
                                            l10n: l10n,
                                            isDataLoaded: isDataLoaded,
                                            selectedTab: _selectedTab,
                                            onTabChanged: (tab) {
                                              _logger.info('Series detail tab switched to: $tab');
                                              setState(() => _selectedTab = tab);
                                              fetchTabData(tab);
                                            },
                                            onStateChanged: (s) => _libraryService.updateLibraryEntryState(_activeSeries.id, s),
                                            onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(_activeSeries.id, r),
                                            onUpdateChapter: () => entry != null ? showUpdateProgressDialog(entry, isChapter: true) : null,
                                            onUpdateVolume: () => entry != null ? showUpdateProgressDialog(entry, isChapter: false) : null,
                                            onUpdateRating: () => entry != null ? showUpdateRatingDialog(entry) : null,
                                            buildTabContent: (hPadding) =>
                                                _buildTabContent(entry, l10n, hPadding),
                                          ),
                                  ),
                                ),
                                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: SeriesDetailFAB(
            entryStream: _entryStream,
            isAdding: _isAdding,
            onAdd: addSeriesToLibrary,
          ),
        );
      },
    );
  }
}
