import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/screens/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/screens/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/widgets/library_grid_list.dart';
import 'package:mangabaka_app/features/profile/widgets/mb_login_prompt.dart';
import 'package:mangabaka_app/features/series/widgets/series_list_skeleton.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';

class LibraryBody extends StatelessWidget {
  final bool loggedIn;
  final Stream<List<LibraryEntry>>? entriesStream;
  final String query;
  final SearchFilters filters;
  final TabController tabController;
  final Map<String, ScrollController> scrollControllers;
  final RefreshCallback onRefresh;
  final VoidCallback onLogin;
  final Function(api.Series) onItemTap;

  const LibraryBody({
    super.key,
    required this.loggedIn,
    required this.entriesStream,
    required this.query,
    required this.filters,
    required this.tabController,
    required this.scrollControllers,
    required this.onRefresh,
    required this.onLogin,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (!loggedIn) {
      return MBLoginPrompt(
        onLogin: onLogin,
        message: l10n.translate('login_prompt_library'),
      );
    }
    
    if (entriesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<LibraryEntry>>(
      stream: entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          final settings = SettingsManager();
          final isGrid = settings.separateListStyles
              ? settings.libraryListStyle.isGrid
              : settings.currentListStyle.isGrid;
          return SeriesListSkeleton(isGrid: isGrid);
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${l10n.translate('failed_to_load')}: ${snapshot.error}',
              style: TextStyle(color: LibraryScreenConstants.errorColor),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(child: Text(l10n.translate('empty_library'))),
                ),
              ],
            ),
          );
        }

        return ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final filterHelper = LibraryFilterHelper(
              allEntries: snapshot.data!,
              query: query,
              filters: filters,
              contentPreferences: SettingsManager().contentPreferences,
            );

            return TabBarView(
              controller: tabController,
              children: LibraryScreenConstants.tabs.map((tab) {
                final items = filterHelper.getByTab(tab.key);
                return LibraryGridList(
                  items: items,
                  tabKey: tab.key,
                  scrollController: scrollControllers[tab.key]!,
                  onRefresh: onRefresh,
                  onItemTap: onItemTap,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
