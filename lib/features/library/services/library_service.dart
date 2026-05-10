import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/database/database.dart' as db;
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/services/library_constants.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';

// ─── Prefs keys ───────────────────────────────────────────────────────────
const String _lastSyncKey = AppConstants.lastSyncKey;
const String _isIncompleteKey =
    '${AppConstants.prefixStorageKey}library_is_incomplete';

class LibraryService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;
  bool _hasPerformedInitialSync = false;

  // ─── Sync state notifier ──────────────────────────────────────────────────
  final ValueNotifier<LibrarySyncStatus> syncStatus =
      ValueNotifier(LibrarySyncStatus());

  bool _isSyncCancelled = false;
  Future<void>? _initialSyncTask;

  void cancelSync() {
    _isSyncCancelled = true;
    _initialSyncTask = null;
    syncStatus.value = syncStatus.value
        .copyWith(isSyncing: false, clearError: true, clearInfo: true);
  }

  LibraryService({required ProfileAuthService auth, db.AppDatabase? database})
      : _auth = auth,
        _db = database ?? getIt<db.AppDatabase>();

  // ─── DB streams ───────────────────────────────────────────────────────────

  /// Watches a single library entry by series ID.
  Stream<api.LibraryEntry?> watchEntryFromDb(String seriesId) {
    return _db.libraryEntriesDao
        .watchEntryWithSeries(seriesId)
        .map(
          (dbEntry) => dbEntry != null
              ? DbToApiMapper.libraryEntryFromDb(dbEntry)
              : null,
        )
        .handleError((error, stackTrace) {
          _logger.severe('Error watching entry from db: $error\n$stackTrace');
          return null;
        }, test: (error) => true);
  }

  Stream<List<api.LibraryEntry>> watchEntriesFromDb() {
    return _db.libraryEntriesDao
        .watchAllEntriesWithSeries()
        .map(
          (dbEntries) =>
              dbEntries.map(DbToApiMapper.libraryEntryFromDb).toList(),
        )
        .handleError((error, stackTrace) {
          _logger.severe('Error watching entries from db: $error\n$stackTrace');
          return <api.LibraryEntry>[];
        }, test: (error) => true);
  }

  // ─── CRUD operations ──────────────────────────────────────────────────────

  Future<void> updateLibraryEntryState(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Update state request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      await _db.libraryEntriesDao.updateEntryState(seriesId, state);
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry state: $e\n$st');
      throw AppError(
          message: 'Failed to update entry state', originalError: e, stackTrace: st);
    }
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'rating': rating}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Update rating request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await _db.libraryEntriesDao.updateEntryRating(seriesId, rating);
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry rating: $e\n$st');
      throw AppError(
          message: 'Failed to update entry rating', originalError: e, stackTrace: st);
    }
  }

  Future<void> createLibraryEntry(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Create entry request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 201) {
        await syncLibrary();
      } else {
        _logger.severe(
            'Failed to create library entry. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to create library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'CREATE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error creating entry: $e\n$st');
      throw AppError(
          message: 'Failed to create library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .delete(url, headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': LibraryConstants.userAgent,
          })
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Delete entry request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 200 || response.statusCode == 404) {
        await _db.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        _logger
            .severe('Failed to delete entry. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to delete library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'DELETE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error deleting entry: $e\n$st');
      throw AppError(
          message: 'Failed to delete library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> clearLibrary() async {
    try {
      cancelSync();
      await _db.libraryEntriesDao.deleteAllEntries();
      _hasPerformedInitialSync = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_isIncompleteKey);
    } catch (e, st) {
      _logger.severe('Failed to clear library: $e\n$st');
    }
  }

  // ─── Sync operations ──────────────────────────────────────────────────────

  Future<bool> isLibraryIncomplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isIncompleteKey) ?? false;
  }

  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    if (_initialSyncTask != null) return _initialSyncTask;

    _initialSyncTask = _doInitialSync();
    return _initialSyncTask;
  }

  Future<void> _doInitialSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      if (lastSync != null) {
        _logger.info('Library already imported. Performing incremental catch-up.');
        _hasPerformedInitialSync = true;
        unawaited(syncLibrary());
        return;
      }

      _logger.info('No previous sync found. Performing full initial import...');
      await importFullLibrary();
      if (!_isSyncCancelled) {
        _hasPerformedInitialSync = true;
      }
    } on NetworkException catch (e) {
      _logger.warning('Initial import failed: $e');
      _initialSyncTask = null;
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to perform initial import: $e\n$st');
      _initialSyncTask = null;
      rethrow;
    }
  }

  Future<void> importFullLibrary() async {
    if (syncStatus.value.isSyncing) return;

    _isSyncCancelled = false;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      final token = await _auth.getValidAccessToken();
      var totalFetched = 0;
      final fetchedIds = <String>[];
      final result = await _importSlice(
        token,
        onProgress: (n, ids) {
          totalFetched += n;
          fetchedIds.addAll(ids);
          syncStatus.value = syncStatus.value.copyWith(
            currentEntries: totalFetched, error: null);
        },
      );

      if (!result.hitCap && !_isSyncCancelled && fetchedIds.isNotEmpty) {
        await _db.libraryEntriesDao.deleteEntriesNotIn(fetchedIds);
      }

      if (!_isSyncCancelled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isIncompleteKey, result.hitCap);
        final watermark = result.newestWatermark ?? DateTime.now().toUtc().toIso8601String();
        await prefs.setString(_lastSyncKey, watermark);
      }

      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e) {
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.toString());
      rethrow;
    }
  }

  Future<({bool hitCap, List<String> fetchedIds, String? newestWatermark})> _importSlice(
    String token, {
    required void Function(int fetched, List<String> fetchedIds) onProgress,
  }) async {
    var page = 1;
    final int apiPageCap = AppConstants.libraryMaxPages;
    final allFetchedIds = <String>[];
    String? newestWatermark;

    while (page <= apiPageCap) {
      if (_isSyncCancelled) return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);

      final result = await _fetchPage(token, page, sortBy: 'updated_at_desc');
      final entries = result.entries;

      if (result.isError) return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);

      if (page == 1 && entries.isNotEmpty) {
        final e = entries.first;
        newestWatermark = e.updatedAt ?? e.createdAt ?? '${e.id}|${e.state}|${e.progressChapter ?? 0}';
      }

      await _saveEntries(entries);
      final ids = entries.map((e) => e.id).toList();
      allFetchedIds.addAll(ids);
      onProgress(entries.length, ids);

      if (entries.isEmpty || entries.length < LibraryConstants.pageLimit) {
        return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
      }
      page++;
    }
    return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
  }

  Future<void> syncLibrary({String? state}) async {
    if (syncStatus.value.isSyncing) return;

    _isSyncCancelled = false;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      final token = await _auth.getValidAccessToken();
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      final lastSync = lastSyncStr != null ? _parseAsUtc(lastSyncStr) : null;
      String? newestEntryTimestamp;

      var page = 1;
      var totalFetched = 0;
      const maxSyncPages = 10;

      while (page <= maxSyncPages) {
        if (_isSyncCancelled) break;

        final result = await _fetchPage(token, page, sortBy: 'updated_at_desc', state: state);
        final entries = result.entries;

        if (entries.isEmpty) break;

        bool reachedKnown = false;
        final newEntries = <api.LibraryEntry>[];

        for (final e in entries) {
          final dateStr = e.updatedAt ?? e.createdAt;
          if (newestEntryTimestamp == null) {
            newestEntryTimestamp = dateStr ?? '${e.id}|${e.state}|${e.progressChapter ?? 0}';
          }

          bool isNew = true;
          if (dateStr != null) {
            final entryDate = _parseAsUtc(dateStr);
            if (lastSync != null && entryDate != null && !entryDate.isAfter(lastSync)) isNew = false;
          } else if (lastSyncStr != null) {
            if ('${e.id}|${e.state}|${e.progressChapter ?? 0}' == lastSyncStr) isNew = false;
          }

          if (!isNew) {
            reachedKnown = true;
            break;
          }
          newEntries.add(e);
        }

        await _saveEntries(newEntries);
        totalFetched += newEntries.length;
        syncStatus.value = syncStatus.value.copyWith(currentEntries: totalFetched, error: null);

        if (reachedKnown || entries.length < LibraryConstants.pageLimit) break;
        page++;
      }

      if (!_isSyncCancelled) {
        await prefs.setString(_lastSyncKey, newestEntryTimestamp ?? DateTime.now().toUtc().toIso8601String());
      }
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e) {
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.toString());
      rethrow;
    }
  }

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  Future<_FetchPageResult> _fetchPage(
    String token,
    int page, {
    String? state,
    String? type,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': LibraryConstants.pageLimit.toString(),
    };
    if (state != null) queryParams['state'] = state;
    if (type != null) queryParams['type'] = type;
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    final uri = Uri.parse(LibraryConstants.baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': LibraryConstants.userAgent,
      }).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 429) {
        await Future.delayed(Duration(seconds: AppConstants.rateLimitRetryDelaySeconds));
        return _fetchPage(token, page, state: state, sortBy: sortBy);
      }

      if (response.statusCode == 401) throw AuthException(message: 'Auth failed', code: 'AUTH_FAILED');
      if (response.statusCode == 400) return _FetchPageResult(entries: [], totalEntries: 0, isError: true);
      if (response.statusCode != 200) throw ApiException(message: 'Fetch failed', statusCode: response.statusCode);

      final result = await compute(_parseLibraryPage, response.body);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
    await _db.libraryEntriesDao.upsertLibraryEntries(entries);
  }

  DateTime? _parseAsUtc(String dateStr) {
    if (dateStr.isEmpty) return null;
    final numValue = int.tryParse(dateStr);
    if (numValue != null) {
      if (dateStr.length == 10) return DateTime.fromMillisecondsSinceEpoch(numValue * 1000, isUtc: true);
      if (dateStr.length == 13) return DateTime.fromMillisecondsSinceEpoch(numValue, isUtc: true);
    }
    return DateTime.tryParse(dateStr)?.toUtc();
  }
}

class _FetchPageResult {
  final List<api.LibraryEntry> entries;
  final int totalEntries;
  final bool isError;
  _FetchPageResult({required this.entries, required this.totalEntries, this.isError = false});
}

_FetchPageResult _parseLibraryPage(String responseBody) {
  final body = jsonDecode(responseBody) as Map<String, dynamic>;
  final data = (body['data'] as List<dynamic>? ?? const []);
  final entries = data.map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>)).toList();
  return _FetchPageResult(entries: entries, totalEntries: 0);
}
