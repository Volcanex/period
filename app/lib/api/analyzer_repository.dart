import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'contracts/analyzer_results.dart';

/// Runs all three condition analyzers against the local observation history.
///
/// Call [evaluate] when the user opens the insights tab. Results are cached
/// for the session — no automatic background refresh. Falls back gracefully
/// if any individual analyzer fails (the others still surface).
class AnalyzerRepository extends ChangeNotifier {
  final ApiClient _client;
  AnalyzerResults _results = const AnalyzerResults.idle();

  AnalyzerRepository({ApiClient? client}) : _client = client ?? ApiClient();

  AnalyzerResults get results => _results;

  bool get isLoading => _results.state == AnalyzerLoadState.loading;
  bool get hasResults => _results.state == AnalyzerLoadState.done;

  Future<void> evaluate(
    List<Map<String, dynamic>> observations,
    String subjectId,
  ) async {
    if (isLoading) return;
    _results = const AnalyzerResults.loading();
    notifyListeners();

    final body = {'subject_id': subjectId, 'observations': observations};

    // Run all three in parallel. Each is individually guarded so one failure
    // doesn't block the other two.
    final futures = await Future.wait([
      _safePost('/api/v1/analyzers/pcos/evaluate', body),
      _safePost('/api/v1/analyzers/pmdd/evaluate', body),
      _safePost('/api/v1/analyzers/perimenopause/evaluate', body),
    ]);

    final pcosJson = futures[0];
    final pmddJson = futures[1];
    final periJson = futures[2];

    _results = AnalyzerResults(
      pcos: pcosJson != null ? parsePcos(pcosJson) : null,
      pmdd: pmddJson != null ? parsePmdd(pmddJson) : null,
      perimenopause: periJson != null ? parsePerimenopause(periJson) : null,
      state: AnalyzerLoadState.done,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _safePost(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await _client.postJson(path, body);
      return (result as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint('AnalyzerRepository: $path failed: $e');
      return null;
    }
  }
}
