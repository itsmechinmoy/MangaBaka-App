import 'dart:convert';
import 'dart:io';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart' as exc;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/series/models/series.dart' as api;

import 'tables/series_table.dart';
import 'tables/library_entries_table.dart';

part 'database.g.dart';
part 'daos/series_dao.dart';
part 'daos/library_entries_dao.dart';

// Class to hold the result of our join query
class LibraryEntryWithSeries {
  final LibraryEntriesTableData libraryEntry;
  final SeriesTableData series;

  LibraryEntryWithSeries({required this.libraryEntry, required this.series});
}

@DriftDatabase(
  tables: [SeriesTable, LibraryEntriesTable],
  daos: [SeriesDao, LibraryEntriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Add missing columns to SeriesTable
          await m.addColumn(seriesTable, seriesTable.mergedWith);
          await m.addColumn(seriesTable, seriesTable.contentRating);
          await m.addColumn(seriesTable, seriesTable.type);
          await m.addColumn(seriesTable, seriesTable.rating);
          await m.addColumn(seriesTable, seriesTable.finalVolume);
          await m.addColumn(seriesTable, seriesTable.totalChapters);
          await m.addColumn(seriesTable, seriesTable.lastUpdated);
          await m.addColumn(seriesTable, seriesTable.relationships);
          await m.addColumn(seriesTable, seriesTable.source);
          
          // Add missing columns to LibraryEntriesTable
          await m.addColumn(libraryEntriesTable, libraryEntriesTable.rating);
        }
      },
    );
  }

  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() => _instance;

  static LazyDatabase _openConnection() {
    final logger = LoggingService.logger;
    return LazyDatabase(() async {
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'manga_db.sqlite'));
        return NativeDatabase.createInBackground(file);
      } catch (e) {
        logger.severe('Failed to open database connection: $e');
        throw exc.DatabaseException(message: 'Failed to open database connection', originalError: e);
      }
    });
  }
}
