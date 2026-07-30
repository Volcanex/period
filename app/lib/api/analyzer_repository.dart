import 'package:flutter/foundation.dart';

import 'contracts/analyzer_results.dart';

/// Holds the condition-analyzer results (PMDD, PCOS, perimenopause).
///
/// These analyzers currently exist only as the Python reference implementation
/// in `core/analyzers/`. The client is offline-only — it will not call a server
/// to run them — so until they are ported to Dart there is nothing to evaluate
/// on device and [evaluate] resolves to [AnalyzerLoadState.unported].
///
/// The parsers and result contracts in `contracts/analyzer_results.dart` are
/// kept intact: the port fills in [evaluate], and everything downstream of it
/// already knows how to render real results.
class AnalyzerRepository extends ChangeNotifier {
  AnalyzerResults _results = const AnalyzerResults.idle();

  AnalyzerResults get results => _results;

  bool get isLoading => _results.state == AnalyzerLoadState.loading;
  bool get hasResults => _results.state == AnalyzerLoadState.done;

  Future<void> evaluate(
    List<Map<String, dynamic>> observations,
    String subjectId,
  ) async {
    _results = const AnalyzerResults.unported();
    notifyListeners();
  }
}
