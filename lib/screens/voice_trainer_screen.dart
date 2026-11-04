import 'package:flutter/material.dart';

import '../services/voice_data_recorder.dart';
import '../theme/ns_theme.dart';
import '../widgets/ns_widgets.dart';

/// Voice data recorder (development tool). Records labeled 10-second clips
/// through the same microphone path the live model uses, for retraining.
class VoiceTrainerScreen extends StatefulWidget {
  const VoiceTrainerScreen({super.key});

  @override
  State<VoiceTrainerScreen> createState() => _VoiceTrainerScreenState();
}

class _VoiceTrainerScreenState extends State<VoiceTrainerScreen> {
  VoiceClipLabel _label = VoiceClipLabel.normal;
  bool _isRecording = false;
  String _status = '';
  Map<VoiceClipLabel, int> _counts = const {};
  String _dirPath = '';

  static const _labels = [
    VoiceClipLabel.normal,
    VoiceClipLabel.elevated,
    VoiceClipLabel.danger,
  ];

  @override
  void initState() {
    super.initState();
    _refreshInfo();
  }

  Future<void> _refreshInfo() async {
    final counts = await VoiceDataRecorder.instance.clipCounts();
    final dir = await VoiceDataRecorder.instance.outputDirectory();
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _dirPath = dir.path;
    });
  }

  Future<void> _record() async {
    setState(() {
      _isRecording = true;
      _status = '';
    });
    try {
      await VoiceDataRecorder.instance.recordClip(
        label: _label,
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
    } on StateError catch (e) {
      if (mounted) setState(() => _status = e.message);
    } catch (e) {
      if (mounted) setState(() => _status = 'Recording failed: $e');
    } finally {
      if (mounted) setState(() => _isRecording = false);
      await _refreshInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Voice trainer', style: NsText.head(17, color: c.ink)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: NsChip('Dev tool')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Records 10-second labeled clips with the same microphone path '
              'the live model uses. Turn Active Safety Monitoring off first.',
              style: NsText.body(12.5, color: c.mute, height: 1.5),
            ),
            const SizedBox(height: 14),
            NsSegmented(
              labels: [for (final l in _labels) l.name],
              selected: _labels.indexOf(_label),
              enabled: !_isRecording,
              onChanged: (i) => setState(() => _label = _labels[i]),
            ),
            const SizedBox(height: 12),
            NsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hint(c, 'normal', 'talking, TV, room noise, silence'),
                  const SizedBox(height: 8),
                  _hint(c, 'elevated', 'raised or angry voice, crying'),
                  const SizedBox(height: 8),
                  _hint(c, 'danger', 'screaming, shouting for help, loud bangs'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_isRecording || _status.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _isRecording ? c.crit : c.line),
                ),
                child: Row(
                  children: [
                    if (_isRecording)
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(right: 12),
                        decoration:
                            BoxDecoration(color: c.crit, shape: BoxShape.circle),
                      ),
                    Expanded(
                      child: Text(
                        _status.isEmpty ? 'Recording' : _status,
                        style: NsText.body(13, w: 600, color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            NsButton(
              _isRecording
                  ? 'Recording'
                  : 'Record 10 s clip (${_label.name})',
              onPressed: _isRecording ? null : _record,
              loading: false,
            ),
            const SizedBox(height: 14),
            NsCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final l in _labels)
                    Column(
                      children: [
                        Text('${_counts[l] ?? 0}',
                            style: NsText.num(24, color: c.ink)),
                        const SizedBox(height: 2),
                        NsLabel(l.name),
                      ],
                    ),
                ],
              ),
            ),
            if (_dirPath.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Folder on phone: $_dirPath',
                  style: NsText.body(10.5, color: c.mute)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hint(NsColors c, String name, String text) {
    return RichText(
      text: TextSpan(
        style: NsText.body(12.5, color: c.mute, height: 1.4),
        children: [
          TextSpan(
            text: '$name  ',
            style: NsText.body(12.5, w: 700, color: c.ink),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}
