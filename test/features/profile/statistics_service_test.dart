import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

void main() {
  late AppDatabase db;
  late StatisticsService service;

  setUp(() {
    resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    db = AppDatabase();
    service = StatisticsService(db);
  });

  group('StatisticsService', () {
    test('getTotalSeries returns 0 initially', () async {
      final total = await service.getTotalSeries();
      expect(total, 0);
    });

    test('getChaptersRead returns 0 initially', () async {
      final chapters = await service.getChaptersRead();
      expect(chapters, 0);
    });
  });
}
