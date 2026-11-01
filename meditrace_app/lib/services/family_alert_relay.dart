import 'dart:math';
import 'dart:async';

import 'family_api.dart';
import 'local_database.dart';

/// Menyimpan kejadian sampai backend menerimanya. ID kejadian yang sama dipakai
/// saat retry sehingga backend tidak mengirim pemberitahuan ganda.
class FamilyAlertRelay {
  FamilyAlertRelay(this._database, {FamilyApi? api})
    : _api = api ?? FamilyApi();

  final LocalDatabase _database;
  final FamilyApi _api;
  Future<void>? _flushing;
  bool _flushAgain = false;
  int? _groupId;

  int? get groupId => _groupId;
  Map<String, dynamic>? _lastDeliveryResult;
  String? _lastError;

  Future<void> initialize() async {
    _groupId = int.tryParse(
      await _database.getSetting('alert_family_group_id') ?? '',
    );
    unawaited(flush());
  }

  Future<void> selectGroup(int? groupId) async {
    _groupId = groupId;
    await _database.setSetting('alert_family_group_id', '${groupId ?? ''}');
    await flush();
  }

  Future<Map<String, dynamic>?> report({
    required String kind,
    required String title,
    String? details,
  }) async {
    _lastError = null;
    _lastDeliveryResult = null;
    if (!await _api.hasSession) {
      return {'ok': false, 'error': 'Silakan login untuk mengirim peringatan.'};
    }
    final groupId = await _resolveGroup();
    if (groupId == null) {
      return {
        'ok': false,
        'error':
            'Belum ada grup keluarga aktif. Pastikan undangan sudah diterima.',
      };
    }
    // Grup dapat berubah setelah logout/login atau pembuatan ulang grup.
    // Alert lama harus mengikuti grup aktif yang baru dibaca dari Firestore.
    await _database.reassignPendingFamilyAlerts(groupId);
    await _database.queueFamilyAlert(
      clientEventId: _uuidV4(),
      groupId: groupId,
      kind: kind,
      title: title,
      details: details,
    );
    await flush();
    return _lastDeliveryResult ??
        {
          'ok': false,
          'error': _lastError ?? 'Peringatan belum berhasil dikirim ke server.',
        };
  }

  Future<int?> _resolveGroup() async {
    try {
      final me = await _api.me();
      final userId = (me['user'] as Map)['id'];
      final groups = (await _api.families())['groups'] as List? ?? [];
      if (groups.isEmpty) return null;
      final saved = _groupId;
      if (saved != null && groups.any((item) => _groupIdOf(item) == saved)) {
        return saved;
      }
      final owned = groups.where((item) => (item as Map)['owner_id'] == userId);
      final selected = owned.length == 1 ? owned.single : groups.first;
      final id = _groupIdOf(selected);
      if (id == null || id < 1) {
        throw StateError('ID grup keluarga tidak valid.');
      }
      await selectGroup(id);
      return id;
    } catch (error) {
      _lastError = 'Gagal membaca grup keluarga: $error';
      return null;
    }
  }

  int? _groupIdOf(Object? item) {
    final value = item is Map ? item['id'] : null;
    return switch (value) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
  }

  Future<void> flush() {
    final running = _flushing;
    if (running != null) {
      _flushAgain = true;
      return running;
    }
    final operation = _drain();
    _flushing = operation;
    return operation.whenComplete(() => _flushing = null);
  }

  Future<void> _drain() async {
    do {
      _flushAgain = false;
      await _flushPending();
    } while (_flushAgain);
  }

  Future<void> _flushPending() async {
    if (!await _api.hasSession) return;
    List<Map<String, Object?>> pending;
    try {
      pending = await _database.pendingFamilyAlerts();
    } catch (_) {
      return;
    }
    for (final item in pending) {
      try {
        final result = await _api.sendDeviceAlert(
          item['group_id'] as int,
          kind: item['kind'] as String,
          title: item['title'] as String,
          details: item['details'] as String?,
          clientEventId: item['client_event_id'] as String,
        );
        _lastDeliveryResult = result;
        await _database.removePendingFamilyAlert(
          item['client_event_id'] as String,
        );
      } catch (error) {
        _lastError = 'Gagal mengirim peringatan: $error';
        // Pertahankan urutan dan coba lagi saat aplikasi kembali aktif.
        break;
      }
    }
  }

  Future<void> clearOnLogout() async {
    await _database.clearPendingFamilyAlerts();
    await selectGroup(null);
  }

  void dispose() => _api.dispose();

  static String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
