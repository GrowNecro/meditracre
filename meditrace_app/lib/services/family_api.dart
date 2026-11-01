import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Firebase facade; schedules and BLE data remain in local SQLite.
class FamilyApi {
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    // Client ID bukan rahasia; fallback ini sama dengan client web pada
    // google-services.json agar `flutter run` tanpa dart-define tetap login.
    defaultValue: '676550038130-7d0ssg76olenfpa8rlnkehpkh56r9aue.apps.googleusercontent.com',
  );
  static const _backendUrl = String.fromEnvironment(
    'FAMILY_API_URL',
    defaultValue: 'https://meditrace.grownecro.tech',
  );
  static Future<void>? _googleInitialization;
  static StreamSubscription<String>? _tokenChanges;
  static const _storage = FlutterSecureStorage();
  static const _lastTokenKey = 'meditrace_last_fcm_token';

  bool get _configured => Firebase.apps.isNotEmpty;
  bool get backendConfigured => _backendUrl.isNotEmpty;
  Future<bool> get hasSession async =>
      _configured && FirebaseAuth.instance.currentUser != null;

  Future<Map<String, dynamic>> loginWithGoogle() async {
    _requireConfigured();
    if (_googleWebClientId.isEmpty) {
      throw const FamilyApiException(
        'GOOGLE_WEB_CLIENT_ID belum diisi. Lengkapi konfigurasi Firebase dan OAuth.',
      );
    }
    try {
      final signIn = GoogleSignIn.instance;
      await (_googleInitialization ??= signIn.initialize(
        serverClientId: _googleWebClientId,
      ));
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const FamilyApiException('Google tidak mengirim ID token.');
      }
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      if (backendConfigured) {
        await _call('ensureUser');
        await _registerPush();
      }
      return await me();
    } on FamilyApiException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw FamilyApiException(
        'Login Google gagal: ${error.description ?? error.code.name}',
      );
    } on FirebaseAuthException catch (error) {
      throw FamilyApiException(
        'Login Firebase gagal: ${error.message ?? error.code}',
      );
    }
  }

  Future<void> logout() async {
    if (!_configured) return;
    try {
      final token = await _storage.read(key: _lastTokenKey);
      if (token != null && FirebaseAuth.instance.currentUser != null) {
        await _call('unregisterDevice', {'token': token});
        await _storage.delete(key: _lastTokenKey);
      }
    } catch (_) {
      throw const FamilyApiException(
        'Untuk keluar dengan aman, hubungkan internet agar notifikasi HP ini dihentikan dahulu.',
      );
    }
    await FirebaseAuth.instance.signOut();
    if (_googleInitialization != null) await GoogleSignIn.instance.signOut();
  }

  Future<Map<String, dynamic>> me() async {
    _requireSignedIn();
    final user = FirebaseAuth.instance.currentUser!;
    return {
      'user': {
        'id': user.uid,
        'name': user.displayName ?? user.email ?? 'Pengguna',
        'email': user.email,
      },
    };
  }

  Future<Map<String, dynamic>> families() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberUids', arrayContains: _uid)
          .get();
      return {
        'groups': [
          for (final doc in snapshot.docs)
            {
              'id': int.parse(doc.id),
              'name': doc.data()['name'],
              'owner_id': doc.data()['ownerUid'],
              'members_count': (doc.data()['memberUids'] as List?)?.length ?? 0,
            },
        ],
      };
    } on FirebaseException catch (error) {
      throw FamilyApiException(error.message ?? error.code);
    }
  }

  Future<Map<String, dynamic>> inbox() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('alerts')
          .orderBy('occurredAt', descending: true)
          .limit(50)
          .get();
      return {
        'data': [
          for (final doc in snapshot.docs)
            {
              'id': doc.id,
              'title': doc.data()['title'],
              'group_name': doc.data()['groupName'],
              'occurred_at': (doc.data()['occurredAt'] as Timestamp?)
                  ?.toDate()
                  .toLocal()
                  .toString(),
              'acknowledged_at': doc.data()['acknowledgedAt'],
            },
        ],
      };
    } on FirebaseException catch (error) {
      throw FamilyApiException(error.message ?? error.code);
    }
  }

  Future<Map<String, dynamic>> createFamily(String name) =>
      _call('createFamily', {'name': name});
  Future<Map<String, dynamic>> updateFamily(int groupId, String name) =>
      _call('updateFamily', {'groupId': groupId, 'name': name});
  Future<Map<String, dynamic>> deleteFamily(int groupId) =>
      _call('deleteFamily', {'groupId': groupId});
  Future<Map<String, dynamic>> joinFamily(String code) =>
      _call('joinFamily', {'code': code});
  Future<Map<String, dynamic>> invite(int groupId, String role) =>
      _call('createInvitation', {'groupId': groupId, 'role': role});
  Future<Map<String, dynamic>> sendInvitationEmail({
    required int groupId,
    required String email,
    required String code,
    required String groupName,
  }) => _call('sendInvitationEmail', {
    'groupId': groupId,
    'email': email,
    'code': code,
    'groupName': groupName,
  });
  Future<Map<String, dynamic>> sendAlert(
    int groupId,
    String title,
  ) => sendDeviceAlert(
    groupId,
    kind: 'manual',
    title: title,
    clientEventId:
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
  );
  Future<Map<String, dynamic>> sendDeviceAlert(
    int groupId, {
    required String kind,
    required String title,
    required String clientEventId,
    String? details,
  }) => _call('sendAlert', {
    'groupId': groupId,
    'kind': kind,
    'title': title,
    'clientEventId': clientEventId,
    'details': ?details,
  });
  Future<Map<String, dynamic>> registerDevice(String token) =>
      _call('registerDevice', {'token': token});
  Future<Map<String, dynamic>> unregisterDevice(String token) =>
      _call('unregisterDevice', {'token': token});
  Future<Map<String, dynamic>> acknowledge(String alertId) =>
      _call('acknowledgeAlert', {'alertId': alertId});
  Future<Map<String, dynamic>> testEmail(String email) =>
      _call('testEmail', {'email': email});

  Future<void> refreshPushRegistration() async {
    if (backendConfigured && await hasSession) await _registerPush();
  }

  Future<void> _registerPush() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // Firebase Messaging 17 recommends FID registration, but Admin SDK
      // direct-send still uses FCM registration tokens for this backend.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) {
        await registerDevice(token);
        await _storage.write(key: _lastTokenKey, value: token);
      }
      // ignore: deprecated_member_use
      _tokenChanges ??= messaging.onTokenRefresh.listen((newToken) {
        if (FirebaseAuth.instance.currentUser != null) {
          unawaited(_savePushToken(newToken));
        }
      });
    } catch (_) {
      // A denied permission or unavailable FCM must not prevent sign-in.
    }
  }

  Future<void> _savePushToken(String token) async {
    try {
      await registerDevice(token);
      await _storage.write(key: _lastTokenKey, value: token);
    } catch (_) {
      // Refresh is retried when the family screen next opens.
    }
  }

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    _requireSignedIn();
    if (!backendConfigured) {
      throw const FamilyApiException(
        'Backend keluarga belum aktif. Fitur grup dan push menyusul.',
      );
    }
    try {
      final token = await FirebaseAuth.instance.currentUser!.getIdToken();
      final url = Uri.parse(
        '${_backendUrl.replaceFirst(RegExp(r'/+$'), '')}/v1/$name',
      );
      if (url.scheme != 'https') {
        throw const FamilyApiException('Backend keluarga harus memakai HTTPS.');
      }
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FamilyApiException('Balasan backend tidak valid.');
      }
      final result = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FamilyApiException(
          (result['error'] as String?) ??
              'Backend gagal (${response.statusCode}).',
        );
      }
      return result;
    } on FamilyApiException {
      rethrow;
    } on TimeoutException {
      throw const FamilyApiException('Backend keluarga tidak merespons.');
    } on http.ClientException {
      throw const FamilyApiException(
        'Tidak dapat menghubungi backend keluarga.',
      );
    } on FormatException {
      throw const FamilyApiException('Balasan backend tidak valid.');
    }
  }

  String get _uid {
    _requireSignedIn();
    return FirebaseAuth.instance.currentUser!.uid;
  }

  void _requireConfigured() {
    if (!_configured) {
      throw const FamilyApiException(
        'Firebase belum dikonfigurasi. Isi FIREBASE_* lalu build ulang aplikasi.',
      );
    }
  }

  void _requireSignedIn() {
    _requireConfigured();
    if (FirebaseAuth.instance.currentUser == null) {
      throw const FamilyApiException('Silakan masuk dengan Google.');
    }
  }

  void dispose() {}
}

class FamilyApiException implements Exception {
  const FamilyApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
