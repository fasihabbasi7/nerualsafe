import 'package:flutter/material.dart';

import '../models/risk_tier.dart';
import '../theme/ns_theme.dart';
import '../widgets/ns_widgets.dart';
import 'live_state.dart';
import 'voice_trainer_screen.dart';

/// Voice live: classification, VoiceScore, the three probabilities, and
/// the fused score. Updates about every 500 ms while monitoring is on.
class VoiceTab extends StatefulWidget {
  const VoiceTab({super.key});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab> {
  final _live = LiveState.instance;

  Color _scoreColor(NsColors c, double s) {
    if (s >= 75) return c.crit;
    if (s >= 45) return c.warn;
    return c.ok;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _live,
      builder: (context, _) {
        final c = context.ns;
        final voice = _live.lastVoice;
        final decision = _live.decision;
        final tier = decision?.riskTier ?? RiskTier.normal;
        final active = _live.isMonitoring;
        final probs = voice?.probabilities;

        double? p(int i) => (probs != null && i < probs.length) ? probs[i] : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const NsLabel('Voice analysis · live'),
                NsChip('500 ms', dot: active ? c.ok : c.mute),
              ],
            ),
            const SizedBox(height: 12),
            NsWave(level: voice?.score ?? 0, active: active),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NsLabel('Classification'),
                    const SizedBox(height: 4),
                    Text(voice?.classification ?? '—',
                        style: NsText.head(22, w: 600, color: c.ink)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const NsLabel('VoiceScore'),
                    const SizedBox(height: 4),
                    Text(
                      voice == null ? '—' : voice.score.toStringAsFixed(2),
                      style: NsText.num(26,
                          color: voice == null ? c.mute : _scoreColor(c, voice.score)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            NsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NsLabel('Probabilities'),
                  const SizedBox(height: 12),
                  NsProbRow(label: 'Normal', value: p(0), color: c.ok),
                  const SizedBox(height: 10),
                  NsProbRow(label: 'Elevated', value: p(1), color: c.warn),
                  const SizedBox(height: 10),
                  NsProbRow(label: 'Danger', value: p(2), color: c.crit),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NsCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NsLabel('Fused danger score'),
                      const SizedBox(height: 4),
                      Text(
                        decision == null
                            ? '—'
                            : decision.boostedScore.toStringAsFixed(2),
                        style: NsText.num(22, color: c.ink),
                      ),
                    ],
                  ),
                  NsChip(
                    decision == null ? 'No data' : nsTierLabel(tier),
                    color: decision == null ? null : nsTierColor(context, tier),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              active
                  ? 'Listening. Results update about every 500 ms.'
                  : 'Turn on Active Safety Monitoring on the Status tab to see live results.',
              style: NsText.body(12, color: c.mute, height: 1.5),
            ),
            const SizedBox(height: 14),
            NsButton(
              'Open voice trainer',
              ghost: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceTrainerScreen()),
              ),
            ),
          ],
        );
      },
    );
  }
}
