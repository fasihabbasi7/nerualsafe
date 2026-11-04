import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/calculator_engine.dart';
import '../services/secret_code_service.dart';
import '../theme/ns_theme.dart';
import 'app_shell.dart';

/// The cover screen: a working calculator. The hidden codes work exactly
/// as before: the secret code plus "=" opens the app, the decoy code plus
/// "=" resets the display and sends a silent alert. Nothing on screen
/// reveals either.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

enum _KeyKind { number, fn, op, equals }

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _engine = CalculatorEngine();
  final _secretCodes = SecretCodeService();

  String _input = '';
  String _display = '0';
  String _lastExpression = '';

  static const _rows = [
    ['C', '⌫', '%', '/'],
    ['7', '8', '9', '*'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['0', '.', '='],
  ];

  void _onPressed(String label) {
    switch (label) {
      case 'C':
        setState(() {
          _input = '';
          _display = '0';
          _lastExpression = '';
        });
        return;
      case '⌫':
        setState(() {
          if (_input.isNotEmpty) {
            _input = _input.substring(0, _input.length - 1);
          }
          _display = _input.isEmpty ? '0' : _input;
        });
        return;
      case '=':
        _handleEquals();
        return;
      default:
        setState(() {
          _input += label;
          _display = _input;
          _lastExpression = '';
        });
    }
  }

  void _handleEquals() {
    final fullInput = '$_input=';

    // Check silently, before doing anything visible, whether this
    // "calculation" is actually a hidden command. Nothing about the
    // UI reveals that this check is happening.
    final action = _secretCodes.evaluate(fullInput);

    switch (action) {
      case CodeAction.openDashboard:
        setState(() {
          _input = '';
          _display = '0';
          _lastExpression = '';
        });
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
        return;
      case CodeAction.silentDecoyAlarm:
        // Resets the display like nothing happened, while a real
        // (dry-run unless Test mode is off; see main.dart) alert dispatch
        // runs in the background through the same dispatcher and cooldown
        // a genuine highDanger transition would use. Never awaited, so
        // there is no delay and the screen never visibly hangs.
        setState(() {
          _input = '';
          _display = '0';
          _lastExpression = '';
        });
        unawaited(
          emergencyOrchestrator.triggerManualAlert().then((result) {
            debugPrint(
              '[NeuralSafe] Decoy PIN triggered manual alert dispatch: '
              '${result.outcome}',
            );
          }),
        );
        return;
      case CodeAction.none:
        break;
    }

    // Not a hidden command: behave like a normal calculator.
    try {
      final expression = _input;
      final result = _engine.evaluate(_input);
      setState(() {
        _lastExpression = expression;
        _display = _formatResult(result);
        _input = _display;
      });
    } catch (_) {
      setState(() {
        _display = 'Error';
        _input = '';
        _lastExpression = '';
      });
    }
  }

  String _formatResult(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  _KeyKind _kindFor(String label) {
    if (label == '=') return _KeyKind.equals;
    if ('+-*/'.contains(label)) return _KeyKind.op;
    if (label == 'C' || label == '⌫' || label == '%') return _KeyKind.fn;
    return _KeyKind.number;
  }

  String _shown(String label) {
    switch (label) {
      case '/':
        return '÷';
      case '*':
        return '×';
      case '-':
        return '−';
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_lastExpression.isNotEmpty)
                          Text(
                            _lastExpression
                                .replaceAll('*', '×')
                                .replaceAll('/', '÷')
                                .replaceAll('-', '−'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NsText.num(16, w: 400, color: c.mute),
                          ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _display
                                .replaceAll('*', '×')
                                .replaceAll('/', '÷'),
                            maxLines: 1,
                            style: NsText.num(56, w: 400, color: c.ink,
                                spacing: -2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.52,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: [
                        for (var r = 0; r < _rows.length; r++) ...[
                          Expanded(
                            child: Row(
                              children: [
                                for (var i = 0; i < _rows[r].length; i++) ...[
                                  Expanded(
                                    flex: (_rows[r][i] == '0') ? 2 : 1,
                                    child: _CalcKey(
                                      label: _shown(_rows[r][i]),
                                      kind: _kindFor(_rows[r][i]),
                                      alignStart: _rows[r][i] == '0',
                                      onTap: () => _onPressed(_rows[r][i]),
                                    ),
                                  ),
                                  if (i < _rows[r].length - 1)
                                    const SizedBox(width: 10),
                                ],
                              ],
                            ),
                          ),
                          if (r < _rows.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({
    required this.label,
    required this.kind,
    required this.onTap,
    this.alignStart = false,
  });
  final String label;
  final _KeyKind kind;
  final VoidCallback onTap;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    final Color bg;
    final Color fg;
    final Color border;
    switch (kind) {
      case _KeyKind.equals:
        bg = c.acc;
        fg = c.accInk;
        border = c.acc;
        break;
      case _KeyKind.op:
        bg = c.panel;
        fg = c.acc;
        border = c.acc;
        break;
      case _KeyKind.fn:
        bg = c.panel2;
        fg = c.mute;
        border = c.panel2;
        break;
      case _KeyKind.number:
        bg = c.panel;
        fg = c.ink;
        border = c.line;
        break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          alignment: alignStart ? Alignment.centerLeft : Alignment.center,
          padding: EdgeInsets.only(left: alignStart ? 28 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Text(label, style: NsText.num(24, w: 500, color: fg)),
        ),
      ),
    );
  }
}
