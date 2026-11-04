import 'dart:async';

import '../models/anomaly_result_log_entry.dart';
import '../models/risk_decision.dart';
import '../models/risk_tier.dart';
import 'anomaly_evaluator.dart';
import 'behavioral_anomaly_pipeline.dart';
import 'danger_score_fusion_engine.dart';
import 'sustained_danger_tracker.dart';

class RiskDecisionEngine {
  RiskDecisionEngine({
    required Stream<AnomalyResultLogEntry> anomalyStream,
    DangerScoreFusionEngine? fusionEngine,
    SustainedDangerTracker? sustainedDangerTracker,
    DateTime Function()? clock,
    this.textScoreTtl = const Duration(seconds: 60),
    this.voiceScoreTtl = const Duration(seconds: 30),
    this.corroborationMin = 75.0,
  })  : _anomalyStream = anomalyStream,
        _clock = clock ?? DateTime.now,
        _fusionEngine = fusionEngine ?? const DangerScoreFusionEngine(),
        _sustainedTracker = sustainedDangerTracker ?? SustainedDangerTracker(),
        _controller = StreamController<RiskDecision>.broadcast();

  static RiskDecisionEngine? _instance;

  /// Application-level singleton, wired to the real, persistent
  /// BehavioralAnomalyPipeline (rather than any test-only or
  /// dashboard-local stream). Constructed and started lazily on first
  /// access — main.dart accesses this once at startup specifically to
  /// trigger that construction, and every other part of the app
  /// (dashboard, future MessageInterceptor, etc.) should reference
  /// this same instance rather than constructing its own.
  static RiskDecisionEngine get instance {
    if (_instance != null) return _instance!;
    _instance = RiskDecisionEngine(
      anomalyStream: BehavioralAnomalyPipeline.instance.anomalyResults,
    )..start();
    return _instance!;
  }

  final Stream<AnomalyResultLogEntry> _anomalyStream;
  final DangerScoreFusionEngine _fusionEngine;

  /// Implements FR-4.2's sustained-danger boost: tracks whether the
  /// RAW fused score has stayed continuously at/above 60 for 5+
  /// seconds, and if so, adds +20 before classification — see that
  /// class's doc comment for why this lives here rather than inside
  /// DangerScoreFusionEngine itself.
  final SustainedDangerTracker _sustainedTracker;

  final StreamController<RiskDecision> _controller;

  StreamSubscription<AnomalyResultLogEntry>? _subscription;

  bool get isRunning => _subscription != null;

  RiskDecision? _latest;
  RiskDecision? get latest => _latest;

  double? _latestBehaviorScore;
  double? _latestTextScore;
  double? _latestVoiceScore;

  final DateTime Function() _clock;

  /// A typed message or a voice reading only describes "right now".
  /// Without a time limit an old score would keep counting forever and
  /// could combine with a later, unrelated signal into a false alert.
  /// Behavior is NOT expired here: it only updates every 2 minutes and
  /// describes a longer pattern, not a single moment.
  final Duration textScoreTtl;
  final Duration voiceScoreTtl;

  /// Two independent modules both at/above this score (and both still
  /// fresh) count as corroborated danger. A single module alone
  /// (e.g. one fake typed message) can never trigger this.
  final double corroborationMin;

  DateTime? _textScoreAt;
  DateTime? _voiceScoreAt;
  Timer? _textExpiryTimer;
  Timer? _voiceExpiryTimer;

  Stream<RiskDecision> get decisions => _controller.stream;

  /// Latest per-module scores that fed the current decision (null = no
  /// data, or expired). Read-only, for display.
  double? get latestVoiceScore => _latestVoiceScore;
  double? get latestTextScore => _latestTextScore;
  double? get latestBehaviorScore => _latestBehaviorScore;

  void start() {
    if (_subscription != null) return;
    _subscription = _anomalyStream.listen(_handleAnomalyEntry);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _textExpiryTimer?.cancel();
    _voiceExpiryTimer?.cancel();
    // So a later restart's first decision isn't boosted off a
    // sustained period that happened before this stop.
    _sustainedTracker.reset();
  }

  Future<void> dispose() async {
    _textExpiryTimer?.cancel();
    _voiceExpiryTimer?.cancel();
    await _controller.close();
  }

  void submitTextScore(
    double score, {
    DateTime? evaluatedAt,
    String windowKey = 'text-event',
  }) {
    _latestTextScore = score;
    _textScoreAt = _clock();
    _textExpiryTimer?.cancel();
    _textExpiryTimer = Timer(textScoreTtl + const Duration(milliseconds: 100),
        () => _emitDecision(evaluatedAt: _clock(), windowKey: 'text-expired'));
    _emitDecision(
      evaluatedAt: evaluatedAt ?? DateTime.now(),
      windowKey: windowKey,
    );
  }

  void submitVoiceScore(
    double score, {
    DateTime? evaluatedAt,
    String windowKey = 'voice-event',
  }) {
    _latestVoiceScore = score;
    _voiceScoreAt = _clock();
    _voiceExpiryTimer?.cancel();
    _voiceExpiryTimer = Timer(voiceScoreTtl + const Duration(milliseconds: 100),
        () => _emitDecision(evaluatedAt: _clock(), windowKey: 'voice-expired'));
    _emitDecision(
      evaluatedAt: evaluatedAt ?? DateTime.now(),
      windowKey: windowKey,
    );
  }

  void _handleAnomalyEntry(AnomalyResultLogEntry entry) {
    // Prefer the Random Forest + linear SVM ensemble's continuous
    // BehaviorScore (NeuralSafe proposal Section 6.3's classification
    // layer) whenever the classifier produced one for this entry.
    // Falls back to AnomalyEvaluator's own aggregateScore — the
    // pre-classifier z-score signal — when classification is
    // unavailable (classifier asset missing/corrupt) but the z-score
    // evaluation itself is still evaluated rather than coldStart, so a
    // classifier failure degrades the signal rather than losing it.
    _latestBehaviorScore = entry.classification?.behaviorScore ??
        (entry.result.status == AnomalyStatus.evaluated
            ? entry.result.aggregateScore
            : null);

    _emitDecision(
      evaluatedAt: entry.evaluatedAt,
      windowKey: entry.windowKey,
    );
  }

  void _emitDecision(
      {required DateTime evaluatedAt, required String windowKey}) {
    final now = _clock();
    if (_textScoreAt != null && now.difference(_textScoreAt!) > textScoreTtl) {
      _latestTextScore = null;
      _textScoreAt = null;
    }
    if (_voiceScoreAt != null &&
        now.difference(_voiceScoreAt!) > voiceScoreTtl) {
      _latestVoiceScore = null;
      _voiceScoreAt = null;
    }

    final fusionResult = _fusionEngine.fuse({
      'voice': _latestVoiceScore,
      'text': _latestTextScore,
      'behavior': _latestBehaviorScore,
    });

    // FR-4.2: apply the sustained-danger boost to the RAW fused score,
    // then classify THAT (not fusionResult's own pre-boost riskTier)
    // against thresholds that assume the post-boost 0-120 scale. See
    // SustainedDangerTracker's and RiskThresholds' doc comments.
    var boostedScore = _sustainedTracker.apply(
      fusionResult.finalScore,
      now: evaluatedAt,
    );

    // Corroboration: the weighted average alone can never reach High
    // Danger when one module is calm (e.g. voice 100 + text 100 +
    // behavior 0 = 80, +20 boost = 100 < 110). If two independent
    // modules are BOTH clearly dangerous at the same time, that is
    // strong evidence by itself, so lift the score to the High Danger
    // line. One module alone never does this.
    final highModules = [
      _latestVoiceScore,
      _latestTextScore,
      _latestBehaviorScore,
    ].where((v) => v != null && v >= corroborationMin).length;
    if (highModules >= 2 &&
        boostedScore < _fusionEngine.thresholds.highDangerMin) {
      boostedScore = _fusionEngine.thresholds.highDangerMin;
    }
    final riskTier = classify(boostedScore, thresholds: _fusionEngine.thresholds);

    final decision = RiskDecision(
      riskTier: riskTier,
      fusionResult: fusionResult,
      boostedScore: boostedScore,
      evaluatedAt: evaluatedAt,
      windowKey: windowKey,
    );

    _latest = decision;
    if (!_controller.isClosed) {
      _controller.add(decision);
    }
  }
}
