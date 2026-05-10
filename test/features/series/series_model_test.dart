import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';

void main() {
  group('Series Model', () {
    final mockJson = {
      'id': '123',
      'title': 'Test Manga',
      'native_title': 'テスト漫画',
      'romanized_title': 'Test Manga Romanized',
      'secondary_titles': {
        'en': 'Secondary Title',
      },
      'authors': ['Author 1'],
      'artists': ['Artist 1'],
      'description': 'Description with <br> and <b>HTML</b>',
      'year': 2021,
      'status': 'ongoing',
      'type': 'manga',
      'rating': 4.5,
      'total_chapters': 100,
      'genres': ['Action', 'Adventure'],
      'tags': ['Tag 1'],
      'last_updated_at': '2021-01-01',
    };

    test('Series.fromJson parses correctly', () {
      final series = Series.fromJson(mockJson);

      expect(series.id, '123');
      expect(series.title, 'Test Manga');
      expect(series.nativeTitle, 'テスト漫画');
      expect(series.description, 'Description with \n and HTML');
      expect(series.genres, contains('Action'));
      expect(series.authors, contains('Author 1'));
    });

    test('getDisplayTitle returns correct title based on language', () {
      final series = Series.fromJson(mockJson);

      expect(series.getDisplayTitle(TitleLanguage.defaultLang), 'Test Manga');
      expect(series.getDisplayTitle(TitleLanguage.native), 'テスト漫画');
      expect(series.getDisplayTitle(TitleLanguage.romanized), 'Test Manga Romanized');
    });
  });
}
