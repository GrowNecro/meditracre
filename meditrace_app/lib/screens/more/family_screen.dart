import '../../l10n/localization.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/family_api.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    this.embedded = false,
    this.initialInviteCode,
    this.onInviteConsumed,
  });

  final bool embedded;
  final String? initialInviteCode;
  final VoidCallback? onInviteConsumed;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final _api = FamilyApi(
    languageCode: () => context.read<AppProvider>().languageCode,
  );
  bool _busy = true;
  bool _signedIn = false;
  String? _error;
  String _name = '';
  String? _userId;
  List<dynamic> _families = [];
  int? _activeGroupId;
  String? _pendingInviteCode;
  bool _joiningInvite = false;

  @override
  void initState() {
    super.initState();
    _pendingInviteCode = widget.initialInviteCode;
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _refresh();
    await _consumePendingInvite();
  }

  Future<void> _consumePendingInvite() async {
    final code = _pendingInviteCode;
    if (!mounted ||
        code == null ||
        !_signedIn ||
        !_api.backendConfigured ||
        _joiningInvite) {
      return;
    }
    _joiningInvite = true;
    _pendingInviteCode = null;
    try {
      await _run(() => _api.joinFamily(code));
      if (_error == null) {
        widget.onInviteConsumed?.call();
      } else {
        _pendingInviteCode = code;
      }
    } finally {
      _joiningInvite = false;
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool showLoading = true}) async {
    final relay = context.read<AppProvider>().familyAlerts;
    setState(() {
      if (showLoading) _busy = true;
      _error = null;
    });
    try {
      if (!await _api.hasSession) {
        if (mounted) setState(() => _signedIn = false);
        return;
      }
      if (mounted) setState(() => _signedIn = true);
      final me = await _api.me();
      if (!_api.backendConfigured) {
        if (mounted) {
          setState(() {
            _name = (me['user'] as Map)['name'].toString();
            _userId = (me['user'] as Map)['id'] as String;
            _families = [];
          });
        }
        return;
      }
      await _api.refreshPushRegistration();
      final families = await _api.families();
      final ownerId = (me['user'] as Map)['id'] as String;
      final ownedGroups = (families['groups'] as List? ?? [])
          .where((item) => (item as Map)['owner_id'] == ownerId)
          .toList();
      if (relay.groupId == null &&
          (families['groups'] as List? ?? []).isNotEmpty) {
        final groups = families['groups'] as List;
        await relay.selectGroup(
          _groupId(ownedGroups.isNotEmpty ? ownedGroups.first : groups.first),
        );
      }
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _name = (me['user'] as Map)['name'].toString();
        _userId = ownerId;
        _families = families['groups'] as List? ?? [];
        _activeGroupId = relay.groupId;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted && showLoading) setState(() => _busy = false);
    }
  }

  Future<void> _textAction(
    String title,
    String label,
    Future<Map<String, dynamic>> Function(String) action,
  ) async {
    var input = '';
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => input = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (submit == true && mounted) {
      await _run(() => action(input.trim()));
    }
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh(showLoading: false);
      await _consumePendingInvite();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(int groupId, String groupName) async {
    await _run(() async {
      final result = await _api.invite(groupId, 'caregiver');
      if (!mounted) return;
      final code = result['code']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.caregiverInvitationCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(context.l10n.validForDaysAndCanOnlyBeUsed),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(dialogContext.l10n.codeCopied)),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(context.l10n.copyCode),
              ),
              FilledButton.icon(
                onPressed: () => _emailInvitation(groupId, groupName, code),
                icon: const Icon(Icons.email_outlined),
                label: Text(context.l10n.sendViaEmail),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _emailInvitation(
    int groupId,
    String groupName,
    String code,
  ) async {
    var email = '';
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.sendInvitationViaEmail),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.l10n.recipientEmail,
            hintText: 'keluarga@email.com',
          ),
          onChanged: (value) => email = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.sendEmail),
          ),
        ],
      ),
    );
    if (submit != true || !mounted) return;
    final recipient = email.trim();
    if (!recipient.contains('@') || recipient.contains(' ')) {
      setState(() => _error = context.l10n.enterAValidEmailAddress);
      return;
    }
    await _run(
      () => _api.sendInvitationEmail(
        groupId: groupId,
        email: recipient,
        code: code,
        groupName: groupName,
      ),
    );
  }

  Future<void> _editFamily(int groupId, String currentName) async {
    var name = currentName;
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.editFamilyName),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: currentName),
          decoration: InputDecoration(labelText: context.l10n.familyName),
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (submit != true || !mounted) return;
    await _run(() => _api.updateFamily(groupId, name.trim()));
  }

  Future<void> _deleteFamily(int groupId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteFamilyGroup),
        content: Text(
          context.l10n.groupWillBeDeletedAndMembersWillLose((name).toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _api.deleteFamily(groupId));
  }

  Future<void> _logout() async {
    final relay = context.read<AppProvider>().familyAlerts;
    await _api.logout();
    await relay.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.family),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    return ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(16),
      children: [
        if (_busy && !widget.embedded) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (!_signedIn) ...[
          Text(context.l10n.signInUsingTheProfileCardAboveTo),
          if (!widget.embedded) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      final relay = context.read<AppProvider>().familyAlerts;
                      _run(() async {
                        await _api.loginWithGoogle();
                        await relay.flush();
                      });
                    },
              icon: const Icon(Icons.account_circle),
              label: Text(context.l10n.signInWithGoogle),
            ),
          ],
        ] else ...[
          if (!widget.embedded)
            ListTile(
              title: Text(_name),
              subtitle: Text(context.l10n.accountConnected),
              trailing: TextButton(
                onPressed: _busy ? null : () => _run(_logout),
                child: Text(context.l10n.signOut),
              ),
            ),
          if (!_api.backendConfigured)
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text(context.l10n.groupSettingsAreNotActiveYet),
              subtitle: Text(
                context.l10n.localFeaturesRemainAvailableConnectTheBackendTo,
              ),
            )
          else ...[
            const Divider(),
            Text(context.l10n.familyGroups),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context
                    .l10n
                    .alertsForEmptyCompartmentsAndMeditraceDisconnectionsAre,
              ),
            ),
            if (_activeGroupId != null)
              ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text(context.l10n.familyAlertsActive),
                subtitle: Text(
                  context.l10n.meditraceWillSendAlertsToYourFamilyGroup,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            for (final item in _families)
              Card(
                child: ExpansionTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text((item as Map)['name'].toString()),
                  subtitle: Text(
                    context.l10n.members((item['members_count']).toString()),
                  ),
                  trailing: item['owner_id'] != _userId
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (action) {
                            final id = _groupId(item);
                            final name = item['name'].toString();
                            if (action == 'invite') {
                              _invite(id, name);
                            } else if (action == 'edit') {
                              _editFamily(id, name);
                            } else {
                              _deleteFamily(id, name);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'invite',
                              child: Text(context.l10n.inviteCaregiver),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(context.l10n.editName),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.deleteGroup),
                            ),
                          ],
                        ),
                  children: [
                    for (final member in (item['members'] as List? ?? []))
                      ListTile(
                        dense: true,
                        leading: Icon(
                          member['is_owner'] == true
                              ? Icons.star_outline
                              : Icons.person_outline,
                        ),
                        title: Text(
                          member['name']?.toString() ?? context.l10n.user,
                        ),
                        subtitle: Text(
                          member['email']?.toString() ??
                              context.l10n.emailNotRegisteredYet,
                        ),
                        trailing: member['is_owner'] == true
                            ? Text(context.l10n.owner)
                            : null,
                      ),
                  ],
                ),
              ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _textAction(
                      context.l10n.createGroup,
                      context.l10n.familyName,
                      _api.createFamily,
                    ),
              child: Text(context.l10n.createFamilyGroup),
            ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _textAction(
                      context.l10n.joinGroup,
                      context.l10n.invitationCode,
                      _api.joinFamily,
                    ),
              child: Text(context.l10n.enterInvitationCode),
            ),
          ],
        ],
      ],
    );
  }

  int _groupId(Object? item) {
    final value = item is Map ? item['id'] : null;
    final id = switch (value) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    if (id == null || id < 1) {
      throw StateError(context.l10n.invalidFamilyGroupId);
    }
    return id;
  }
}
