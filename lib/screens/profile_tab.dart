import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/emergency_contact_repository.dart';
import '../services/secret_code_service.dart';
import '../services/user_profile_repository.dart';
import '../theme/ns_theme.dart';
import '../widgets/ns_widgets.dart';
import 'live_state.dart';
import 'setup_screen.dart';
import 'voice_trainer_screen.dart';

/// You: profile, emergency contact and app settings.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _profileRepo = UserProfileRepository();
  final _contactRepo = EmergencyContactRepository();

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _openSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
    LiveState.instance.touch();
    if (mounted) setState(() {});
  }

  void _openTrainer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VoiceTrainerScreen()),
    );
  }

  Future<void> _openCodes() async {
    final c = context.ns;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CodesSheet(),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Codes saved.')));
    }
  }

  Future<void> _setTestMode(bool value) async {
    if (!value) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final c = ctx.ns;
          return AlertDialog(
            backgroundColor: c.panel,
            title: Text('Turn off test mode?',
                style: NsText.head(17, color: c.ink)),
            content: Text(
              'After you restart the app, a real danger alert will send a '
              'real SMS with your location to your emergency contact. Only '
              'do this with a contact you control, for testing.',
              style: NsText.body(13, color: c.mute, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Keep test mode',
                    style: NsText.body(13, w: 700, color: c.acc)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Turn off',
                    style: NsText.body(13, w: 700, color: c.crit)),
              ),
            ],
          );
        },
      );
      if (confirm != true) return;
    }
    await AppSettings.setTestMode(value);
    if (mounted) setState(() {});
  }

  Future<void> _toggleTheme() async {
    final next = AppSettings.themeMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await AppSettings.setTheme(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    final profile = _profileRepo.load();
    final contact = _contactRepo.loadPrimary();
    final name = profile?.name ?? '';
    final langLabel = profile?.preferredLanguage == 'ur' ? 'Urdu' : 'English';
    final restartNeeded = AppSettings.testMode != AppSettings.appliedTestMode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        NsCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.acc,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  name.isEmpty ? '?' : _initials(name),
                  style: NsText.head(18, w: 600, color: c.accInk),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'Not set up yet' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NsText.head(18, w: 600, color: c.ink)),
                    const SizedBox(height: 3),
                    Text('Language · $langLabel',
                        style: NsText.body(12, color: c.mute)),
                  ],
                ),
              ),
              NsChip(name.isEmpty ? 'Set up' : 'Edit', onTap: _openSetup),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NsLabel('Emergency contact'),
        const SizedBox(height: 10),
        NsCard(
          child: Row(
            children: [
              _IconBox(icon: Icons.call_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: contact == null
                    ? Text('No contact yet',
                        style: NsText.body(13.5, color: c.mute))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.name,
                              style: NsText.body(14, w: 700, color: c.ink)),
                          const SizedBox(height: 2),
                          Text(contact.phoneNumber,
                              style: NsText.num(12, color: c.mute)),
                        ],
                      ),
              ),
              if (contact != null) const NsChip('Primary'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NsLabel('Settings'),
        const SizedBox(height: 10),
        NsCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.lock_outline_rounded,
                title: 'Secret & decoy codes',
                subtitle: 'Change both codes',
                isNew: true,
                trailing: Icon(Icons.chevron_right_rounded, color: c.mute),
                onTap: _openCodes,
              ),
              _divider(c),
              _SettingRow(
                icon: Icons.notifications_none_rounded,
                title: 'Test mode',
                subtitle: restartNeeded
                    ? 'Restart the app to apply'
                    : AppSettings.testMode
                        ? 'No real SMS is sent'
                        : 'Real SMS is sent',
                isNew: true,
                trailing: NsSwitch(
                  value: AppSettings.testMode,
                  onChanged: _setTestMode,
                ),
              ),
              _divider(c),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppSettings.themeMode,
                builder: (context, mode, _) => _SettingRow(
                  icon: Icons.contrast_rounded,
                  title: 'Appearance',
                  subtitle: 'Dark or light',
                  isNew: true,
                  trailing: NsChip(
                    mode == ThemeMode.light ? 'Light' : 'Dark',
                    onTap: _toggleTheme,
                  ),
                  onTap: _toggleTheme,
                ),
              ),
              _divider(c),
              _SettingRow(
                icon: Icons.mic_none_rounded,
                title: 'Voice recorder',
                subtitle: 'Development tool',
                trailing: Icon(Icons.chevron_right_rounded, color: c.mute),
                onTap: _openTrainer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'All processing stays on this phone.',
            style: NsText.body(11.5, color: c.mute),
          ),
        ),
      ],
    );
  }

  Widget _divider(NsColors c) => Divider(height: 1, color: c.line);
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 19, color: c.acc),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.isNew = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: NsText.body(14, w: 700, color: c.ink)),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.acc,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('NEW',
                              style: NsText.body(8, w: 800, spacing: 0.6,
                                  color: c.accInk)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: NsText.body(11.5, color: c.mute)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to change the secret code (opens the app) and the decoy
/// code (silent alert). Codes are stored with a trailing "=", because the
/// calculator checks the full text including the equals key.
class _CodesSheet extends StatefulWidget {
  const _CodesSheet();

  @override
  State<_CodesSheet> createState() => _CodesSheetState();
}

class _CodesSheetState extends State<_CodesSheet> {
  final _service = SecretCodeService();
  late final TextEditingController _secret;
  late final TextEditingController _decoy;
  String? _error;
  bool _saving = false;

  static String _strip(String? code) =>
      (code ?? '').replaceAll('=', '').trim();

  @override
  void initState() {
    super.initState();
    _secret = TextEditingController(text: _strip(_service.currentDashboardCode()));
    _decoy = TextEditingController(text: _strip(_service.currentDecoyCode()));
  }

  @override
  void dispose() {
    _secret.dispose();
    _decoy.dispose();
    super.dispose();
  }

  String? _validate(String secret, String decoy) {
    final ok = RegExp(r'^\d{4,8}$');
    if (!ok.hasMatch(secret) || !ok.hasMatch(decoy)) {
      return 'Each code must be 4 to 8 digits.';
    }
    if (secret == decoy) {
      return 'The two codes must be different.';
    }
    return null;
  }

  Future<void> _save() async {
    final secret = _secret.text.trim();
    final decoy = _decoy.text.trim();
    final error = _validate(secret, decoy);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await _service.setDashboardCode('$secret=');
      await _service.setDecoyCode('$decoy=');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not save: $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ns;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Secret & decoy codes',
              style: NsText.head(20, w: 600, color: c.ink)),
          const SizedBox(height: 6),
          Text(
            'Type the code on the calculator, then press =. The secret code '
            'opens the app. The decoy code looks like nothing happened and '
            'sends a silent alert.',
            style: NsText.body(12.5, color: c.mute, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secret,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 8,
            style: NsText.num(16, color: c.ink),
            decoration: const InputDecoration(
              labelText: 'Secret code (opens the app)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _decoy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 8,
            style: NsText.num(16, color: c.ink),
            decoration: const InputDecoration(
              labelText: 'Decoy code (silent alert)',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: NsText.body(12.5, w: 600, color: c.crit)),
          ],
          const SizedBox(height: 18),
          NsButton('Save codes', onPressed: _saving ? null : _save,
              loading: _saving),
        ],
      ),
    );
  }
}
