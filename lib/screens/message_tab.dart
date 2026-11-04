import 'package:flutter/material.dart';

import '../models/risk_tier.dart';
import '../theme/ns_theme.dart';
import '../widgets/ns_widgets.dart';
import 'live_state.dart';

/// Message check: type a message, run the text model, see the class, the
/// TextScore, all four probabilities and the fused score it feeds.
class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  State<MessageTab> createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  final _live = LiveState.instance;
  final _controller = TextEditingController();
  bool _isAnalyzing = false;

  static const _classNames = ['Normal', 'Distress', 'Violence', 'Help'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isAnalyzing = true);
    try {
      await _live.analyzeText(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Color _classColor(NsColors c, int i) {
    switch (i) {
      case 0:
        return c.ok;
      case 1:
        return c.warn;
      case 2:
        return c.crit;
      default:
        return c.acc;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _live,
      builder: (context, _) {
        final c = context.ns;
        final result = _live.lastText;
        final decision = _live.decision;
        final tier = decision?.riskTier ?? RiskTier.normal;
        final probs = result?.probabilities;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const NsLabel('Message check'),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 3,
              style: NsText.body(15, color: c.ink),
              decoration: const InputDecoration(
                hintText: 'Type or paste a message',
              ),
            ),
            const SizedBox(height: 12),
            NsButton(
              _isAnalyzing ? 'Analyzing' : 'Analyze text',
              onPressed: _isAnalyzing ? null : _analyze,
              loading: _isAnalyzing,
            ),
            const SizedBox(height: 20),
            if (result == null)
              NsCard(
                child: Text(
                  'Results appear here. The score is also sent to the fusion '
                  'engine, so it moves the fused danger score.',
                  style: NsText.body(12.5, color: c.mute, height: 1.5),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NsLabel('Predicted class'),
                      const SizedBox(height: 4),
                      Text(result.predictedClass,
                          style: NsText.head(22, w: 600, color: c.ink)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const NsLabel('TextScore'),
                      const SizedBox(height: 4),
                      Text(
                        result.score.toStringAsFixed(2),
                        style: NsText.num(26,
                            color: _textScoreColor(c, result.score)),
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
                    for (var i = 0; i < _classNames.length; i++) ...[
                      NsProbRow(
                        label: _classNames[i],
                        value: (probs != null && i < probs.length)
                            ? probs[i]
                            : null,
                        color: _classColor(c, i),
                      ),
                      if (i < _classNames.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _FusedCard(
              score: decision?.boostedScore,
              tier: tier,
              hasData: decision != null,
            ),
          ],
        );
      },
    );
  }

  Color _textScoreColor(NsColors c, double s) {
    if (s >= 75) return c.crit;
    if (s >= 45) return c.warn;
    return c.ok;
  }
}

class _FusedCard extends StatelessWidget {
  const _FusedCard({
    required this.score,
    required this.tier,
    required this.hasData,
  });
  final double? score;
  final RiskTier tier;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return NsCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NsLabel('Fused danger score'),
              const SizedBox(height: 4),
              Text(
                score == null ? '—' : score!.toStringAsFixed(2),
                style: NsText.num(22, color: c.ink),
              ),
            ],
          ),
          NsChip(
            hasData ? nsTierLabel(tier) : 'No data',
            color: hasData ? nsTierColor(context, tier) : null,
          ),
        ],
      ),
    );
  }
}
