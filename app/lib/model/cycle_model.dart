import 'dart:math' as math;

const cycleModelVersion = 'period-hierarchical-skip-v1';

class PopulationPrior {
  final double meanDays;
  final double betweenSubjectSd;
  final double observationSd;
  final double processSd;
  final double intervalScale;
  final double skipPriorProbability;
  final int minCycleDays;
  final int maxCycleDays;

  const PopulationPrior({
    this.meanDays = 29.0,
    this.betweenSubjectSd = 4.0,
    this.observationSd = 3.5,
    this.processSd = 1.25,
    this.intervalScale = 1.0,
    this.skipPriorProbability = 0.08,
    this.minCycleDays = 15,
    this.maxCycleDays = 120,
  });

  double get individualVariance => betweenSubjectSd * betweenSubjectSd;
  double get observationVariance => observationSd * observationSd;
  double get processVariance => processSd * processSd;
}

class CycleLengthObservation {
  final int cycleIndex;
  final int lengthDays;
  final bool skippedTrackingSuspected;

  const CycleLengthObservation({
    required this.cycleIndex,
    required this.lengthDays,
    this.skippedTrackingSuspected = false,
  });
}

class CycleModelState {
  final int cycleCount;
  final double posteriorMeanDays;
  final double posteriorSdDays;
  final double predictiveSdDays;
  final List<double> adjustedLengths;
  final List<double> skipProbabilities;
  final String algorithmVersion;

  const CycleModelState({
    required this.cycleCount,
    required this.posteriorMeanDays,
    required this.posteriorSdDays,
    required this.predictiveSdDays,
    required this.adjustedLengths,
    required this.skipProbabilities,
    this.algorithmVersion = cycleModelVersion,
  });
}

class CyclePrediction {
  final double expectedLengthDays;
  final double p10LengthDays;
  final double p50LengthDays;
  final double p90LengthDays;
  final double predictiveSdDays;
  final double skippedTrackingProbability;
  final int? elapsedCycleDay;
  final String algorithmVersion;

  const CyclePrediction({
    required this.expectedLengthDays,
    required this.p10LengthDays,
    required this.p50LengthDays,
    required this.p90LengthDays,
    required this.predictiveSdDays,
    required this.skippedTrackingProbability,
    required this.elapsedCycleDay,
    this.algorithmVersion = cycleModelVersion,
  });

  double get p80WindowDays => p90LengthDays - p10LengthDays;
}

CycleModelState fitCycleModel(
  List<CycleLengthObservation> observations, {
  PopulationPrior prior = const PopulationPrior(),
}) {
  if (observations.isEmpty) {
    return CycleModelState(
      cycleCount: 0,
      posteriorMeanDays: prior.meanDays,
      posteriorSdDays: prior.betweenSubjectSd,
      predictiveSdDays:
          prior.intervalScale *
          math.sqrt(
            prior.individualVariance +
                prior.observationVariance +
                prior.processVariance,
          ),
      adjustedLengths: const [],
      skipProbabilities: const [],
    );
  }

  final ordered = [...observations]
    ..sort((a, b) => a.cycleIndex.compareTo(b.cycleIndex));
  final adjusted = <double>[];
  final skips = <double>[];
  var runningMean = prior.meanDays;
  for (final obs in ordered) {
    if (obs.lengthDays < prior.minCycleDays ||
        obs.lengthDays > prior.maxCycleDays) {
      throw ArgumentError('cycle length out of supported range');
    }
    final skipP = _skipProbability(
      obs.lengthDays,
      runningMean,
      prior,
      obs.skippedTrackingSuspected,
    );
    final adjustedLength =
        (1.0 - skipP) * obs.lengthDays + skipP * (obs.lengthDays / 2.0);
    skips.add(skipP);
    adjusted.add(adjustedLength);
    runningMean = adjusted.reduce((a, b) => a + b) / adjusted.length;
  }

  final n = adjusted.length;
  final priorPrecision = 1.0 / prior.individualVariance;
  final dataPrecision = n / prior.observationVariance;
  final posteriorVariance = 1.0 / (priorPrecision + dataPrecision);
  final posteriorMean =
      posteriorVariance *
      (prior.meanDays * priorPrecision +
          adjusted.reduce((a, b) => a + b) / prior.observationVariance);
  final predictiveVariance =
      posteriorVariance + prior.observationVariance + prior.processVariance;

  return CycleModelState(
    cycleCount: n,
    posteriorMeanDays: posteriorMean,
    posteriorSdDays: math.sqrt(posteriorVariance),
    predictiveSdDays: prior.intervalScale * math.sqrt(predictiveVariance),
    adjustedLengths: adjusted,
    skipProbabilities: skips,
  );
}

CyclePrediction predictNextCycle(
  CycleModelState state, {
  int? elapsedCycleDay,
}) {
  final (mean, sd) = _conditionOnElapsed(
    state.posteriorMeanDays,
    state.predictiveSdDays,
    elapsedCycleDay,
  );
  final recentSkips = state.skipProbabilities.length > 3
      ? state.skipProbabilities.sublist(state.skipProbabilities.length - 3)
      : state.skipProbabilities;
  final skipProbability = recentSkips.isEmpty
      ? 0.0
      : _clipProbability(
          recentSkips.reduce((a, b) => a + b) / recentSkips.length,
        );
  return CyclePrediction(
    expectedLengthDays: mean,
    p10LengthDays: math.max(1.0, _normalInvCdf(0.10, mean, sd)),
    p50LengthDays: math.max(1.0, _normalInvCdf(0.50, mean, sd)),
    p90LengthDays: math.max(1.0, _normalInvCdf(0.90, mean, sd)),
    predictiveSdDays: sd,
    skippedTrackingProbability: skipProbability,
    elapsedCycleDay: elapsedCycleDay,
    algorithmVersion: state.algorithmVersion,
  );
}

String confidenceLabelForPrediction(
  CyclePrediction prediction, {
  required int cycleStartCount,
}) {
  if (cycleStartCount < 2) return 'starter';

  final window = prediction.p80WindowDays;
  if (window <= 8 && cycleStartCount >= 5) return 'high';
  if (window <= 12 && cycleStartCount >= 3) return 'medium';
  return 'low';
}

double _normalPdf(double value, double mean, double sd) {
  final z = (value - mean) / sd;
  return math.exp(-0.5 * z * z) / (sd * math.sqrt(2 * math.pi));
}

double _skipProbability(
  int lengthDays,
  double meanDays,
  PopulationPrior prior,
  bool flagged,
) {
  if (flagged) return 1.0;
  if (lengthDays < math.max(42, (meanDays * 1.55).toInt())) return 0.0;
  final physiological =
      (1.0 - prior.skipPriorProbability) *
      _normalPdf(lengthDays.toDouble(), meanDays, prior.observationSd * 1.8);
  final skipped =
      prior.skipPriorProbability *
      _normalPdf(lengthDays / 2.0, meanDays, prior.observationSd);
  final denom = physiological + skipped;
  if (denom <= 0 || !denom.isFinite) return 0.0;
  return _clipProbability(skipped / denom);
}

double _clipProbability(double value) => value.clamp(0.0, 1.0).toDouble();

(double, double) _conditionOnElapsed(double mean, double sd, int? elapsed) {
  if (elapsed == null || elapsed <= 0) return (mean, sd);
  final lower = (elapsed + 1).toDouble();
  if (lower <= mean - 4 * sd) return (mean, sd);

  final alpha = (lower - mean) / sd;
  final tail = 1.0 - _standardNormalCdf(alpha);
  if (tail < 1e-6) return (lower, math.max(1.0, sd * 0.35));
  final phi = _normalPdf(alpha, 0.0, 1.0);
  final lambda = phi / tail;
  final conditionedMean = mean + sd * lambda;
  final conditionedVariance =
      sd * sd * (1.0 + alpha * lambda - lambda * lambda);
  return (conditionedMean, math.sqrt(math.max(conditionedVariance, 1.0)));
}

double _standardNormalCdf(double x) => 0.5 * (1.0 + _erf(x / math.sqrt(2.0)));

double _erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  const p = 0.3275911;
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  final t = 1.0 / (1.0 + p * ax);
  final y =
      1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

double _normalInvCdf(double p, double mean, double sd) {
  return mean + sd * _standardNormalInvCdf(p);
}

double _standardNormalInvCdf(double p) {
  if (p <= 0 || p >= 1) {
    throw ArgumentError('p must be in (0, 1)');
  }

  const a = [
    -3.969683028665376e+01,
    2.209460984245205e+02,
    -2.759285104469687e+02,
    1.383577518672690e+02,
    -3.066479806614716e+01,
    2.506628277459239e+00,
  ];
  const b = [
    -5.447609879822406e+01,
    1.615858368580409e+02,
    -1.556989798598866e+02,
    6.680131188771972e+01,
    -1.328068155288572e+01,
  ];
  const c = [
    -7.784894002430293e-03,
    -3.223964580411365e-01,
    -2.400758277161838e+00,
    -2.549732539343734e+00,
    4.374664141464968e+00,
    2.938163982698783e+00,
  ];
  const d = [
    7.784695709041462e-03,
    3.224671290700398e-01,
    2.445134137142996e+00,
    3.754408661907416e+00,
  ];

  const plow = 0.02425;
  const phigh = 1 - plow;
  if (p < plow) {
    final q = math.sqrt(-2 * math.log(p));
    return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
            c[5]) /
        ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  }
  if (p > phigh) {
    final q = math.sqrt(-2 * math.log(1 - p));
    return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
            c[5]) /
        ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  }
  final q = p - 0.5;
  final r = q * q;
  return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) *
      q /
      (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
}
