import '../../l10n/localization.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/ble_provider.dart';
import '../../services/family_api.dart';
import '../../services/app_update_service.dart';
import 'family_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    this.inviteCode,
    this.onInviteConsumed,
    this.familyApi,
  });

  final String? inviteCode;
  final VoidCallback? onInviteConsumed;
  final FamilyApi? familyApi;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late final _api =
      widget.familyApi ??
      FamilyApi(languageCode: () => context.read<AppProvider>().languageCode);
  StreamSubscription<String?>? _sessionSubscription;
  int _accountGeneration = 0;
  bool _authActionBusy = false;
  bool get _accountBusy => _checkingAccount || _authActionBusy;
  bool _checkingAccount = true;
  bool _signedIn = false;
  String? _accountEmail;
  String? _accountName;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = _api.sessionUserIds.distinct().listen((_) {
      unawaited(_loadAccount());
    });
    _loadAccount();
  }

  @override
  void dispose() {
    unawaited(_sessionSubscription?.cancel());
    if (widget.familyApi == null) _api.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    if (!mounted) return;
    final generation = ++_accountGeneration;
    final app = context.read<AppProvider>();
    setState(() {
      _checkingAccount = true;
      _accountError = null;
    });
    try {
      if (await _api.hasSession) {
        final result = await _api.me();
        if (!mounted || generation != _accountGeneration) return;
        final user = result['user'] as Map;
        final accountName = user['name']?.toString();
        setState(() {
          _signedIn = true;
          _accountName = accountName;
          _accountEmail = user['email']?.toString();
        });
        if (accountName != null &&
            accountName.isNotEmpty &&
            accountName != app.patientName) {
          try {
            await app.updateProfile(
              name: accountName,
              family: app.familyName,
              age: app.patientAge,
              emergencyPhone: app.emergencyPhone,
              emergencyEmail: app.emergencyEmail,
            );
          } catch (_) {
            // Local profile persistence must not hide a valid Firebase session.
          }
        }
      } else if (mounted && generation == _accountGeneration) {
        setState(() {
          _signedIn = false;
          _accountName = null;
          _accountEmail = null;
        });
      }
    } catch (error) {
      if (mounted && generation == _accountGeneration) {
        setState(() => _accountError = error.toString());
      }
    } finally {
      if (mounted && generation == _accountGeneration) {
        setState(() => _checkingAccount = false);
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _authActionBusy = true;
      _accountError = null;
    });
    try {
      await _api.loginWithGoogle();
      await _loadAccount();
    } catch (error) {
      if (mounted) setState(() => _accountError = error.toString());
    } finally {
      if (mounted) setState(() => _authActionBusy = false);
    }
  }

  Future<void> _signOut(AppProvider app) async {
    setState(() {
      _authActionBusy = true;
      _accountError = null;
    });
    try {
      await _api.logout();
      await app.familyAlerts.clearOnLogout();
      if (mounted) {
        setState(() {
          _signedIn = false;
          _accountName = null;
          _accountEmail = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _accountError = error.toString());
    } finally {
      if (mounted) setState(() => _authActionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.l10n.language),
              subtitle: DropdownButton<String>(
                key: const ValueKey('language-selector'),
                isExpanded: true,
                itemHeight: null,
                value: app.languageCode,
                onChanged: (value) async {
                  if (value == null) return;
                  try {
                    await app.setLanguage(value);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.languageSaveFailed)),
                    );
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(
                    value: 'id',
                    child: Text('Bahasa Indonesia'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        child: Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _accountName ?? app.patientName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _signedIn
                                  ? (_accountEmail ??
                                        context.l10n.accountEmailUnavailable)
                                  : context.l10n.notSignedIn,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.completeProfile,
                        onPressed: () => _editProfile(context, app),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_accountError != null)
                    Text(
                      _accountError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (!_signedIn)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _accountBusy ? null : _signIn,
                        icon: const Icon(Icons.login),
                        label: Text(context.l10n.signInWithGoogle),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _accountBusy ? null : () => _signOut(app),
                      child: Text(context.l10n.signOutOfAccount),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text(context.l10n.healthInformation),
                  subtitle: Text(
                    context.l10n.patientInformationAndEmergencyContacts,
                  ),
                ),
                ListTile(
                  title: Text(
                    app.patientAge == null
                        ? context.l10n.ageNotProvided
                        : context.l10n.ageYears((app.patientAge).toString()),
                  ),
                  subtitle: Text(
                    app.emergencyPhone.isEmpty && app.emergencyEmail.isEmpty
                        ? context.l10n.emergencyContactNotProvided
                        : context.l10n.emergencyContactSaved,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editProfile(context, app),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update_outlined),
              title: Text(context.l10n.updateApp),
              subtitle: Text(
                context.l10n.downloadTheLatestMeditraceApkFromGithubReleases,
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                try {
                  await AppUpdateService.downloadLatestApk(
                    languageCode: app.languageCode,
                  );
                } on AppUpdateException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: Text(context.l10n.family),
                  subtitle: Text(
                    _signedIn
                        ? context.l10n.manageGroupsCaregiversAndNotifications
                        : context.l10n.signInToConnectWithFamily,
                  ),
                ),
                FamilyScreen(
                  familyApi: _api,
                  key: const ValueKey('profile-family-section'),
                  embedded: true,
                  initialInviteCode: widget.inviteCode,
                  onInviteConsumed: widget.onInviteConsumed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Consumer<BleProvider>(
              builder: (context, ble, _) => Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.bluetooth_disabled),
                    title: Text(context.l10n.reminderWhenMeditraceIsLeftBehind),
                    subtitle: Text(
                      context
                          .l10n
                          .thePatientIsWarnedSecondsAfterDisconnectionIf,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await ble.reportMedboxLeftBehind();
                          if (!context.mounted) return;
                          final emailSent = result?['emailSent'] as int? ?? 0;
                          final emailFailed =
                              result?['emailFailed'] as int? ?? 0;
                          final error = result?['error']?.toString();
                          final message =
                              error ??
                              (emailFailed > 0
                                  ? context
                                        .l10n
                                        .alertSavedButTheCaregiverEmailCouldNot
                                  : emailSent > 0
                                  ? context.l10n
                                        .alertSentToCaregiverEmailAddresses(
                                          (emailSent).toString(),
                                        )
                                  : context
                                        .l10n
                                        .alertSavedAndBeingProcessedForTheCaregiver);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(message)));
                        },
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: Text(context.l10n.iLeftMeditraceBehind),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AppProvider app) async {
    var name = app.patientName;
    var family = app.familyName;
    var ageText = app.patientAge?.toString() ?? '';
    var emergencyPhone = app.emergencyPhone;
    var emergencyEmail = app.emergencyEmail;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: InputDecoration(
                labelText: context.l10n.userName,
                hintText: context.l10n.exampleBudi,
              ),
              onChanged: (value) => name = value,
            ),
            TextFormField(
              initialValue: family,
              decoration: InputDecoration(
                labelText: context.l10n.familyName,
                hintText: context.l10n.exampleBudiSFamily,
              ),
              onChanged: (value) => family = value,
            ),
            TextFormField(
              initialValue: ageText,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.l10n.age),
              onChanged: (value) => ageText = value,
            ),
            TextFormField(
              initialValue: emergencyPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.l10n.emergencyPhoneNumber,
                hintText: context.l10n.example,
              ),
              onChanged: (value) => emergencyPhone = value,
            ),
            TextFormField(
              initialValue: emergencyEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.emergencyEmail,
                hintText: 'keluarga@email.com',
              ),
              onChanged: (value) => emergencyEmail = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (save == true && context.mounted) {
      await app.updateProfile(
        name: name,
        family: family,
        age: int.tryParse(ageText.trim()),
        emergencyPhone: emergencyPhone,
        emergencyEmail: emergencyEmail,
      );
    }
  }
}
