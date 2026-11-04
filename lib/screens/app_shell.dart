import 'package:flutter/material.dart';

import '../theme/ns_theme.dart';
import 'live_state.dart';
import 'message_tab.dart';
import 'profile_tab.dart';
import 'status_tab.dart';
import 'voice_tab.dart';

/// The app behind the calculator: four tabs with a bottom navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    LiveState.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            StatusTab(),
            MessageTab(),
            VoiceTab(),
            ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.shield_outlined, 'Status'),
    (Icons.chat_bubble_outline_rounded, 'Message'),
    (Icons.mic_none_rounded, 'Voice'),
    (Icons.person_outline_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onChanged(i),
                    radius: 36,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 52,
                          height: 30,
                          decoration: BoxDecoration(
                            color: i == index
                                ? c.acc.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            _items[i].$1,
                            size: 22,
                            color: i == index ? c.acc : c.mute,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].$2,
                          style: NsText.body(
                            10.5,
                            w: i == index ? 700 : 600,
                            color: i == index ? c.ink : c.mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
