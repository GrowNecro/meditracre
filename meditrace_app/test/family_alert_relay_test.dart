import 'package:flutter_test/flutter_test.dart';
import 'package:meditrace_app/services/family_alert_relay.dart';
import 'package:meditrace_app/services/family_api.dart';
import 'package:meditrace_app/services/local_database.dart';

void main() {
  test('kejadian disimpan dan retry memakai ID yang sama', () async {
    final database = _MemoryDatabase();
    final api = _FakeFamilyApi()..failNext = true;
    final relay = FamilyAlertRelay(database, api: api);
    await relay.initialize();
    await relay.report(kind: 'low_supply', title: 'Ruang 2 kosong');

    expect(database.pending, hasLength(1));
    final firstId = database.pending.single['client_event_id'];
    expect(api.sentIds, [firstId]);

    await relay.flush();
    expect(api.sentIds, [firstId, firstId]);
    expect(database.pending, isEmpty);
    expect(relay.groupId, 8);
    relay.dispose();
  });

  test('tanpa login tidak membuat peringatan keluarga', () async {
    final database = _MemoryDatabase();
    final api = _FakeFamilyApi()..signedIn = false;
    final relay = FamilyAlertRelay(database, api: api);
    await relay.report(
      kind: 'device_disconnected',
      title: 'MEDITRACE terputus',
    );
    expect(database.pending, isEmpty);
    expect(api.sentIds, isEmpty);
    relay.dispose();
  });
}

class _MemoryDatabase extends LocalDatabase {
  final settings = <String, String>{};
  final pending = <Map<String, Object?>>[];

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<void> queueFamilyAlert({
    required String clientEventId,
    required int groupId,
    required String kind,
    required String title,
    String? details,
  }) async {
    pending.add({
      'client_event_id': clientEventId,
      'group_id': groupId,
      'kind': kind,
      'title': title,
      'details': details,
    });
  }

  @override
  Future<List<Map<String, Object?>>> pendingFamilyAlerts() async =>
      List.of(pending);

  @override
  Future<void> reassignPendingFamilyAlerts(int groupId) async {
    for (final item in pending) {
      item['group_id'] = groupId;
    }
  }

  @override
  Future<void> removePendingFamilyAlert(String clientEventId) async {
    pending.removeWhere((item) => item['client_event_id'] == clientEventId);
  }
}

class _FakeFamilyApi extends FamilyApi {
  bool signedIn = true;
  bool failNext = false;
  final sentIds = <String>[];

  @override
  Future<bool> get hasSession async => signedIn;

  @override
  Future<Map<String, dynamic>> me() async => {
    'user': {'id': 'user-4'},
  };

  @override
  Future<Map<String, dynamic>> families() async => {
    'groups': [
      {'id': 8, 'owner_id': 'user-4'},
    ],
  };

  @override
  Future<Map<String, dynamic>> sendDeviceAlert(
    int groupId, {
    required String kind,
    required String title,
    required String clientEventId,
    String? details,
  }) async {
    expect(groupId, 8);
    sentIds.add(clientEventId);
    if (failNext) {
      failNext = false;
      throw const FamilyApiException('offline');
    }
    return {
      'alert': {'id': 1},
    };
  }
}
