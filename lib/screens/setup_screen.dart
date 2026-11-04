import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../models/user_profile.dart';
import '../services/emergency_contact_repository.dart';
import '../services/onboarding_repository.dart';
import '../services/user_profile_repository.dart';
import '../theme/ns_theme.dart';
import '../widgets/ns_widgets.dart';
import 'live_state.dart';

/// Setup form: user name, preferred language, and one emergency contact
/// (always saved as primary). Same data and validation as before the
/// redesign; only the look changed.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _preferredLanguage = 'en';

  final _profileRepo = UserProfileRepository();
  final _contactRepo = EmergencyContactRepository();
  final _onboardingRepo = OnboardingRepository();

  UserProfile? _existingProfile;
  EmergencyContact? _existingPrimaryContact;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Fire-and-forget, with its own error handling so a failure here
    // can't throw an unhandled exception during widget init.
    _markOnboardingStarted();

    _existingProfile = _profileRepo.load();
    if (_existingProfile != null) {
      _nameController.text = _existingProfile!.name;
      _preferredLanguage = _existingProfile!.preferredLanguage;
    }

    _existingPrimaryContact = _contactRepo.loadPrimary();
    if (_existingPrimaryContact != null) {
      _contactNameController.text = _existingPrimaryContact!.name;
      _contactPhoneController.text = _existingPrimaryContact!.phoneNumber;
    }
  }

  Future<void> _markOnboardingStarted() async {
    try {
      await _onboardingRepo.markStarted();
    } catch (e) {
      debugPrint('[NeuralSafe] Failed to mark onboarding started: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Preserve the original createdAt when editing an existing
      // profile; only stamp DateTime.now() for a brand-new profile.
      final profile = _existingProfile != null
          ? _existingProfile!.copyWith(
              name: _nameController.text.trim(),
              preferredLanguage: _preferredLanguage,
            )
          : UserProfile(
              name: _nameController.text.trim(),
              preferredLanguage: _preferredLanguage,
              createdAt: DateTime.now(),
            );
      await _profileRepo.save(profile);

      final contact = _existingPrimaryContact != null
          ? _existingPrimaryContact!.copyWith(
              name: _contactNameController.text.trim(),
              phoneNumber: _contactPhoneController.text.trim(),
              isPrimary: true,
            )
          : EmergencyContact.create(
              name: _contactNameController.text.trim(),
              phoneNumber: _contactPhoneController.text.trim(),
              isPrimary: true,
            );
      await _contactRepo.save(contact);

      await _onboardingRepo.markComplete();
      LiveState.instance.touch();

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const NsLabel('Setup'),
              const SizedBox(height: 6),
              Text('Tell us who you are',
                  style: NsText.head(26, w: 600, color: c.ink, height: 1.15)),
              const SizedBox(height: 22),
              const NsLabel('Your info'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: NsText.body(15, w: 600, color: c.ink),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Your name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              NsSegmented(
                labels: const ['English', 'اردو'],
                urduIndex: 1,
                selected: _preferredLanguage == 'ur' ? 1 : 0,
                onChanged: (i) =>
                    setState(() => _preferredLanguage = i == 1 ? 'ur' : 'en'),
              ),
              const SizedBox(height: 24),
              const NsLabel('Emergency contact'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactNameController,
                style: NsText.body(15, w: 600, color: c.ink),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Contact name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Contact name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactPhoneController,
                style: NsText.body(15, w: 600, color: c.ink),
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Contact phone number'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Contact phone number is required'
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                'This contact is automatically set as primary. They get your '
                'location by SMS in an emergency.',
                style: NsText.body(12, color: c.mute, height: 1.5),
              ),
              const SizedBox(height: 28),
              NsButton('Save', onPressed: _isSaving ? null : _handleSave,
                  loading: _isSaving),
            ],
          ),
        ),
      ),
    );
  }
}
