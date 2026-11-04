import 'package:flutter/material.dart';

import '../models/risk_tier.dart';
import '../services/onboarding_repository.dart';
import '../theme/ns_theme.dart';
import '../widgets/ns_widgets.dart';
import 'live_state.dart';
import 'setup_screen.dart';

/// Status: the monitoring switch, the fused danger score with its risk
/// tier, and the three models behind it.
class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  final _live = LiveState.instance;
  final _onboardingRepo = OnboardingRepository();

  Future<void> _toggle() async {
    final error = await _live.toggleMonitoring();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
    _live.touch();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _live,
      builder: (context, _) {
        final c = context.ns;
        final setupComplete = _onboardingRepo.load().isComplete;
        final decision = _live.decision;
        final tier = decision?.riskTier ?? RiskTier.normal;
        final tierColor = nsTierColor(context, tier);
        final score = decision?.boostedScore ?? 0.0;
        final boosted = decision != null &&
            decision.boostedScore > decision.fusionResult.finalScore + 0.01;
        final engine = _live.engine;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            NsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Safety Monitoring',
                                style: NsText.head(15, w: 600, color: c.ink)),
                            const SizedBox(height: 4),
                            Text(
                              _live.isMonitoring
                                  ? 'ON · listening to voice and phone activity'
                                  : setupComplete
                                      ? 'OFF · nothing runs in the background'
                                      : 'Finish setup to turn this on',
                              style: NsText.body(12,
                                  color: _live.isMonitoring ? c.ok : c.mute),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _live.isToggling
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: c.acc),
                            )
                          : NsSwitch(
                              value: _live.isMonitoring,
                              onChanged: setupComplete ? (_) => _toggle() : null,
                            ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _live.isMonitoring
                        ? 'Android keeps a notification, "NeuralSafe — Active '
                            'Safety Monitoring", visible the whole time.'
                        : 'Nothing runs in the background until you switch '
                            'this on yourself.',
                    style: NsText.body(11.5, color: c.mute, height: 1.5),
                  ),
                  if (!setupComplete) ...[
                    const SizedBox(height: 12),
                    NsButton('Start setup', onPressed: _openSetup),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: NsGauge(
                score: score,
                color: tierColor,
                tierLabel: nsTierLabel(tier),
              ),
            ),
            const SizedBox(height: 2),
            Center(child: const NsLabel('Fused danger score')),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NORMAL <45',
                    style: NsText.body(9, w: 700, spacing: 0.6, color: c.mute)),
                Text('MEDIUM 45–109',
                    style: NsText.body(9, w: 700, spacing: 0.6, color: c.mute)),
                Text('HIGH 110+',
                    style: NsText.body(9, w: 700, spacing: 0.6, color: c.mute)),
              ],
            ),
            if (boosted) ...[
              const SizedBox(height: 10),
              Center(
                child: NsChip('Sustained boost +20 active', color: c.warn),
              ),
            ],
            const SizedBox(height: 16),
            NsCard(
              child: Column(
                children: [
                  NsScoreRow(
                    label: 'Voice',
                    score: engine.latestVoiceScore,
                    color: _scoreColor(c, engine.latestVoiceScore),
                  ),
                  const SizedBox(height: 12),
                  NsScoreRow(
                    label: 'Text',
                    score: engine.latestTextScore,
                    color: _scoreColor(c, engine.latestTextScore),
                  ),
                  const SizedBox(height: 12),
                  NsScoreRow(
                    label: 'Behavior',
                    score: engine.latestBehaviorScore,
                    color: _scoreColor(c, engine.latestBehaviorScore),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Weights 45 · 35 · 20. A dash means no data yet. '
                      'Behavior learns in the background.',
                      style: NsText.body(11, color: c.mute, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _scoreColor(NsColors c, double? s) {
    if (s == null) return c.panel2;
    if (s >= 75) return c.crit;
    if (s >= 45) return c.warn;
    return c.ok;
  }
}
