import 'package:flutter/foundation.dart';

/// Minimal Dart mirror of the backend analyzer response shapes.
/// Only the fields the UI renders are decoded; the full JSON is not stored.

@immutable
class AnalyzerEval {
  final String status;
  final String confidence;
  final String summary;
  final List<String> suppressors;
  final List<String> recommendedActions;
  final List<({String label, String value, String sub})> stats;

  const AnalyzerEval({
    required this.status,
    required this.confidence,
    required this.summary,
    required this.suppressors,
    required this.recommendedActions,
    required this.stats,
  });

  bool get hasPattern =>
      status == 'features_present' ||
      status == 'features_partial' ||
      status == 'activation' ||
      status == 'pattern';

  bool get isSuppressed => status == 'suppressed';
  bool get isInsufficient => status == 'insufficient_data';
}

/// `unported` is the offline-only interim state: the condition analyzers still
/// live in the Python reference implementation and have not been ported to
/// Dart yet, so there is nothing to run on device. It is deliberately distinct
/// from `error` — nothing has failed.
enum AnalyzerLoadState { idle, loading, done, error, unported }

@immutable
class AnalyzerResults {
  final AnalyzerEval? pcos;
  final AnalyzerEval? pmdd;
  final AnalyzerEval? perimenopause;
  final AnalyzerLoadState state;
  final String? error;

  const AnalyzerResults({
    this.pcos,
    this.pmdd,
    this.perimenopause,
    this.state = AnalyzerLoadState.idle,
    this.error,
  });

  const AnalyzerResults.idle()
      : pcos = null,
        pmdd = null,
        perimenopause = null,
        state = AnalyzerLoadState.idle,
        error = null;

  const AnalyzerResults.loading()
      : pcos = null,
        pmdd = null,
        perimenopause = null,
        state = AnalyzerLoadState.loading,
        error = null;

  const AnalyzerResults.unported()
      : pcos = null,
        pmdd = null,
        perimenopause = null,
        state = AnalyzerLoadState.unported,
        error = null;
}

// ---- parsers ----

AnalyzerEval parsePcos(Map<String, dynamic> j) {
  final cycleSignal = (j['cycle_irregularity'] as Map?)?.cast<String, dynamic>();
  final haSignal = (j['hyperandrogenism'] as Map?)?.cast<String, dynamic>();
  final cycleClassification = cycleSignal?['classification'] as String? ?? '—';
  final cycleCnt = cycleSignal?['observed_cycle_count'] as int? ?? 0;
  final haFeatures =
      ((haSignal?['qualifying_features'] as List?) ?? []).cast<String>();
  return AnalyzerEval(
    status: j['status'] as String? ?? 'insufficient_data',
    confidence: j['confidence'] as String? ?? 'none',
    summary: j['summary'] as String? ?? '',
    suppressors: ((j['suppressors'] as List?) ?? []).cast<String>(),
    recommendedActions:
        ((j['recommended_actions'] as List?) ?? []).cast<String>(),
    stats: [
      (
        label: 'cycle pattern',
        value: cycleClassification.replaceAll('_', ' '),
        sub: '$cycleCnt cycles observed',
      ),
      (
        label: 'hyperandrogenism',
        value: haFeatures.isEmpty ? 'none logged' : haFeatures.first,
        sub: haFeatures.length > 1 ? '+${haFeatures.length - 1} more' : '',
      ),
      (
        label: 'confidence',
        value: j['confidence'] as String? ?? 'none',
        sub: j['diagnostic_framework'] as String? ?? '',
      ),
    ],
  );
}

AnalyzerEval parsePmdd(Map<String, dynamic> j) {
  final posCycles = j['positive_cycle_count'] as int? ?? 0;
  final evalCycles = j['evaluable_cycle_count'] as int? ?? 0;
  final score = (j['activation_score'] as num?)?.toStringAsFixed(2) ?? '—';
  return AnalyzerEval(
    status: j['status'] as String? ?? 'insufficient_data',
    confidence: j['confidence'] as String? ?? 'none',
    summary: j['summary'] as String? ?? '',
    suppressors: ((j['suppressors'] as List?) ?? []).cast<String>(),
    recommendedActions:
        ((j['recommended_actions'] as List?) ?? []).cast<String>(),
    stats: [
      (
        label: 'positive cycles',
        value: '$posCycles / $evalCycles',
        sub: 'of evaluable cycles',
      ),
      (
        label: 'activation score',
        value: score,
        sub: 'range-of-scale method',
      ),
      (
        label: 'confidence',
        value: j['confidence'] as String? ?? 'none',
        sub: j['diagnostic_framework'] as String? ?? '',
      ),
    ],
  );
}

AnalyzerEval parsePerimenopause(Map<String, dynamic> j) {
  final stage = (j['straw_stage'] as String? ?? 'indeterminate')
      .replaceAll('_', ' ');
  final months = j['months_since_last_bleed'] as num?;
  final monthsStr = months != null ? '${months.toStringAsFixed(1)} mo ago' : '—';
  return AnalyzerEval(
    status: j['status'] as String? ?? 'insufficient_data',
    confidence: j['confidence'] as String? ?? 'none',
    summary: j['summary'] as String? ?? '',
    suppressors: ((j['suppressors'] as List?) ?? []).cast<String>(),
    recommendedActions:
        ((j['recommended_actions'] as List?) ?? []).cast<String>(),
    stats: [
      (
        label: 'STRAW+10 stage',
        value: stage,
        sub: 'Harlow et al. 2012',
      ),
      (
        label: 'last bleed',
        value: monthsStr,
        sub: '',
      ),
      (
        label: 'confidence',
        value: j['confidence'] as String? ?? 'none',
        sub: j['diagnostic_framework'] as String? ?? '',
      ),
    ],
  );
}
