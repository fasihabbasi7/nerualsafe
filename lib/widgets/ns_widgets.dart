import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/risk_tier.dart';
import '../theme/ns_theme.dart';

Color nsTierColor(BuildContext context, RiskTier tier) {
  final c = context.ns;
  switch (tier) {
    case RiskTier.normal:
      return c.ok;
    case RiskTier.mediumRisk:
      return c.warn;
    case RiskTier.highDanger:
      return c.crit;
  }
}

String nsTierLabel(RiskTier tier) {
  switch (tier) {
    case RiskTier.normal:
      return 'Normal';
    case RiskTier.mediumRisk:
      return 'Medium risk';
    case RiskTier.highDanger:
      return 'High danger';
  }
}

/// Small uppercase caption used above groups and fields.
class NsLabel extends StatelessWidget {
  const NsLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: NsText.body(10, w: 700, spacing: 1.2, color: color ?? context.ns.mute),
    );
  }
}

class NsCard extends StatelessWidget {
  const NsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: child,
    );
  }
}

class NsChip extends StatelessWidget {
  const NsChip(this.text, {super.key, this.color, this.dot, this.onTap});
  final String text;
  final Color? color;
  final Color? dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    final fg = color ?? c.mute;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color ?? c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: NsText.body(9.5, w: 700, spacing: 0.8, color: fg),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: chip,
    );
  }
}

class NsButton extends StatelessWidget {
  const NsButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.ghost = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final textStyle = NsText.head(13, w: 600, spacing: 0.4);
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ghost ? c.ink : c.accInk,
            ),
          )
        : Text(label.toUpperCase());
    final padding = const EdgeInsets.symmetric(vertical: 16);
    return SizedBox(
      width: double.infinity,
      child: ghost
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.ink,
                disabledForegroundColor: c.mute,
                side: BorderSide(color: c.line),
                padding: padding,
                shape: shape,
                textStyle: textStyle,
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: c.acc,
                foregroundColor: c.accInk,
                disabledBackgroundColor: c.panel2,
                disabledForegroundColor: c.mute,
                padding: padding,
                shape: shape,
                textStyle: textStyle,
              ),
              child: child,
            ),
    );
  }
}

class NsSwitch extends StatelessWidget {
  const NsSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accInk : c.mute,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.acc : c.panel2,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

/// Pill-style segmented control. [urduIndex] marks a label that should be
/// drawn in the Urdu font.
class NsSegmented extends StatelessWidget {
  const NsSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.urduIndex,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final int? urduIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? () => onChanged(i) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? c.acc : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    style: (i == urduIndex
                            ? NsText.urdu(16)
                            : NsText.body(12, w: 600))
                        .copyWith(
                      color: i == selected ? c.accInk : c.mute,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One probability row: label, bar, value.
class NsProbRow extends StatelessWidget {
  const NsProbRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    final v = (value ?? 0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: NsText.body(12.5, color: c.ink)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: c.panel2),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            value == null ? '—' : value!.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: NsText.num(12, color: c.ink),
          ),
        ),
      ],
    );
  }
}

/// A module score row on the status screen (0-100 scale).
class NsScoreRow extends StatelessWidget {
  const NsScoreRow({
    super.key,
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final double? score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    final v = ((score ?? 0) / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: NsText.body(12.5, color: c.ink)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: c.panel2),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            score == null ? '—' : score!.round().toString(),
            textAlign: TextAlign.right,
            style: NsText.num(12.5, color: c.ink),
          ),
        ),
      ],
    );
  }
}

/// Fused danger score as a half-circle gauge on a 0-120 scale, with tick
/// marks at the Medium (45) and High (110) thresholds.
class NsGauge extends StatelessWidget {
  const NsGauge({
    super.key,
    required this.score,
    required this.color,
    required this.tierLabel,
  });
  final double score;
  final Color color;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return SizedBox(
      width: 260,
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GaugePainter(
                score: score,
                color: color,
                track: c.panel2,
                tick: c.mute,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: NsText.num(52, w: 500, color: c.ink, spacing: -2),
                ),
                const SizedBox(height: 2),
                Text(
                  tierLabel.toUpperCase(),
                  style: NsText.body(10, w: 700, spacing: 1.2, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.score,
    required this.color,
    required this.track,
    required this.tick,
  });
  final double score;
  final Color color;
  final Color track;
  final Color tick;

  static const double _max = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 26);
    final radius = size.width / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    final frac = (score / _max).clamp(0.0, 1.0);
    if (frac > 0) {
      final valuePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, math.pi, math.pi * frac, false, valuePaint);
    }

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = tick;
    for (final v in [45.0, 110.0]) {
      final a = math.pi + math.pi * (v / _max);
      final inner = Offset(
        center.dx + (radius - 14) * math.cos(a),
        center.dy + (radius - 14) * math.sin(a),
      );
      final outer = Offset(
        center.dx + (radius - 7) * math.cos(a),
        center.dy + (radius - 7) * math.sin(a),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.score != score ||
      old.color != color ||
      old.track != track ||
      old.tick != tick;
}

/// Decorative live waveform for the voice screen. Bar heights follow the
/// latest voice score so the picture reacts to what the model hears.
class NsWave extends StatelessWidget {
  const NsWave({super.key, required this.level, required this.active});
  final double level; // 0-100
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _WavePainter(
            level: active ? level : 0,
            color: c.acc.withValues(alpha: active ? 0.7 : 0.25),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.level, required this.color});
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barW = 3.0;
    const gap = 5.0;
    final n = (size.width / (barW + gap)).floor();
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barW;
    final amp = 0.18 + 0.8 * (level / 100).clamp(0.0, 1.0);
    for (var i = 0; i < n; i++) {
      final x = i * (barW + gap) + barW;
      final shape =
          (math.sin(i * 0.55) * 0.5 + math.sin(i * 1.7 + 1) * 0.3).abs() + 0.2;
      final h = (size.height * 0.8 * amp * shape).clamp(4.0, size.height - 8);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.level != level || old.color != color;
}
