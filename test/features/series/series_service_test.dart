import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

void main() {
  group('SeriesService', () {
    late SeriesService seriesService;

    setUp(() {
      seriesService = SeriesService();
    });

    test('precacheSeries stores series in cache', () async {
      final series = Series(
        id: '1',
        title: 'Test Series',
        state: '',
        nativeTitle: '',
        romanizedTitle: '',
        secondaryTitles: [],
        coverUrl: '',
        rawCoverUrl: '',
        authors: [],
        artists: [],
        description: '',
        year: '',
        status: '',
        isLicensed: '',
        hasAnime: '',
        contentRating: '',
        type: '',
        rating: '',
        finalVolume: '',
        totalChapters: '',
        links: [],
        publishers: [],
        genres: [],
        tags: [],
        lastUpdated: '',
      );

      seriesService.precacheSeries(series);
      
      // Since fetchSeries checks cache first, it should return the cached series
      // without making a network request. We can verify this by checking if it returns
      // exactly the same instance if the network call would otherwise fail or be different.
      final result = await seriesService.fetchSeries('1');
      expect(result, series);
      expect(result.title, 'Test Series');
    });
  });
}
