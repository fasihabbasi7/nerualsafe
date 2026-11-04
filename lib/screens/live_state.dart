import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/risk_decision.dart';
import '../services/risk_decision_engine.dart';
import '../services/safety_monitoring_controller.dart';
import '../services/text_analysis_service.dart';
import '../services/voice_analysis_service.dart';

/// One place that holds what the screens show live: whether monitoring is
/// on, the latest voice and text results, and the latest fused decision.
/// It owns no logic of its own: monitoring start/stop is still
/// SafetyMonitoringController, scores still flow through
/// RiskDecisionEngine, exactly as before the redesign.
class LiveState extends ChangeNotifier {
  LiveState._();
  static final LiveState instance = LiveState._();

  bool _inited = false;
  bool isMonitoring = false;
  bool isToggling = false;
  VoiceAnalysisResult? lastVoice;
  TextAnalysisResult? lastText;

  StreamSubscription<VoiceAnalysisResult>? _voiceSub;
  StreamSubscription<RiskDecision>? _decisionSub;

  RiskDecisionEngine get engine => RiskDecisionEngine.instance;
  RiskDecision? get decision => engine.latest;

  void init() {
    if (_inited) return;
    _inited = true;
    isMonitoring = SafetyMonitoringController.instance.isActive;
    lastVoice = VoiceAnalysisService.instance.latest;
    _voiceSub = VoiceAnalysisService.instance.scores.listen((r) {
      lastVoice = r;
      notifyListeners();
    });
    _decisionSub = engine.decisions.listen((_) => notifyListeners());
  }

  /// Tell listening screens something outside this class changed
  /// (for example setup was saved).
  void touch() => notifyListeners();

  /// Returns null on success, or a short message to show the user.
  Future<String?> toggleMonitoring() async {
    isToggling = true;
    notifyListeners();
    try {
      if (isMonitoring) {
        await SafetyMonitoringController.instance.stop();
        isMonitoring = false;
        return null;
      }
      final started = await SafetyMonitoringController.instance.start();
      if (!started) {
        return 'Could not start monitoring. Microphone permission is required.';
      }
      isMonitoring = true;
      return null;
    } finally {
      isToggling = false;
      notifyListeners();
    }
  }

  /// Runs the text model and feeds its score into the fusion engine.
  /// Throws if the analysis fails; the caller shows the error.
  Future<void> analyzeText(String text) async {
    final result = await TextAnalysisService.instance.analyze(text);
    engine.submitTextScore(result.score);
    lastText = result;
    notifyListeners();
  }
}
