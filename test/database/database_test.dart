import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:get_it/get_it.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    if (!GetIt.I.isRegistered<LoggingService>()) {
      GetIt.I.registerSingleton<LoggingService>(LoggingService());
    }
    
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('initializes with correct schema version', () async {
      expect(db.schemaVersion, 3);
    });

    test('can insert and retrieve a series via custom query', () async {
      // Using custom query to avoid complex api.Series object for basic DAO test
      await db.into(db.seriesTable).insert(
        SeriesTableCompanion.insert(
          id: '1',
          title: 'Test Manga',
          state: const Value('reading'),
          coverUrl: 'https://example.com/cover.jpg',
          description: 'A test description',
          lastUpdated: Value(DateTime.now().toIso8601String()),
        ),
      );

      final retrieved = await (db.select(db.seriesTable)..where((t) => t.id.equals('1'))).getSingleOrNull();
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Manga');
    });

    test('can insert and retrieve a library entry', () async {
      await db.into(db.seriesTable).insert(
        SeriesTableCompanion.insert(
          id: '1',
          title: 'Test Manga',
          state: const Value('reading'),
          coverUrl: 'https://example.com/cover.jpg',
          description: 'A test description',
          lastUpdated: Value(DateTime.now().toIso8601String()),
        ),
      );

      await db.into(db.libraryEntriesTable).insert(
        LibraryEntriesTableCompanion.insert(
          id: 'entry_1',
          seriesId: '1',
          state: 'plan_to_read',
          progressChapter: const Value(1),
          progressVolume: const Value(0),
        ),
      );

      final retrieved = await (db.select(db.libraryEntriesTable)..where((t) => t.seriesId.equals('1'))).getSingleOrNull();
      expect(retrieved, isNotNull);
      expect(retrieved!.state, 'plan_to_read');
    });

    test('self-healing migration ensures tables exist', () async {
      final tableNames = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table'").get();
      final names = tableNames.map((row) => row.read<String>('name')).toList();
      
      expect(names, contains('series_table'));
      expect(names, contains('library_entries_table'));
    });
  });
}
