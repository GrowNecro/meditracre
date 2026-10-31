const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {randomBytes, createHash} = require('node:crypto');

initializeApp();
const db = getFirestore();
const region = 'asia-southeast2';
const callOptions = {region, enforceAppCheck: false};

function uidOf(request) {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Masuk dengan Google dahulu.');
  return request.auth.uid;
}
function text(value, max, label) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    throw new HttpsError('invalid-argument', `${label} tidak valid.`);
  }
  return value.trim();
}
function groupRef(groupId) {
  if (!Number.isSafeInteger(groupId) || groupId < 1 || groupId > 2147483647) {
    throw new HttpsError('invalid-argument', 'ID grup tidak valid.');
  }
  return db.collection('groups').doc(String(groupId));
}
function hash(value) { return createHash('sha256').update(value).digest('hex'); }

exports.ensureUser = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  await db.collection('users').doc(uid).set({
    name: request.auth.token.name || request.auth.token.email || 'Pengguna',
    email: request.auth.token.email || null,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {id: uid};
});

exports.createFamily = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const name = text(request.data?.name, 80, 'Nama grup');
  for (let attempt = 0; attempt < 5; attempt++) {
    const id = randomBytes(4).readUInt32BE() & 0x7fffffff;
    if (!id) continue;
    try {
      await groupRef(id).create({name, ownerUid: uid, memberUids: [uid],
        createdAt: FieldValue.serverTimestamp()});
      return {id};
    } catch (error) {
      if (error.code !== 6 && error.code !== 'already-exists') throw error;
    }
  }
  throw new HttpsError('internal', 'Gagal membuat ID grup. Coba lagi.');
});

exports.createInvitation = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const ref = groupRef(request.data?.groupId);
  const role = request.data?.role;
  if (role !== 'caregiver') throw new HttpsError('invalid-argument', 'Peran tidak valid.');
  const group = await ref.get();
  if (!group.exists || group.get('ownerUid') !== uid) {
    throw new HttpsError('permission-denied', 'Hanya pemilik grup dapat mengundang.');
  }
  const code = randomBytes(12).toString('hex').toUpperCase();
  await db.collection('invitations').doc(hash(code)).create({
    groupId: request.data.groupId, role, createdBy: uid,
    expiresAt: Timestamp.fromMillis(Date.now() + 7 * 86400000),
  });
  return {code};
});

exports.joinFamily = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const code = text(request.data?.code, 24, 'Kode undangan').toUpperCase();
  if (!/^[0-9A-F]{24}$/.test(code)) throw new HttpsError('invalid-argument', 'Kode undangan tidak valid.');
  const inviteRef = db.collection('invitations').doc(hash(code));
  return db.runTransaction(async (transaction) => {
    const invite = await transaction.get(inviteRef);
    if (!invite.exists || invite.get('expiresAt').toMillis() < Date.now()) {
      throw new HttpsError('not-found', 'Undangan kedaluwarsa atau sudah dipakai.');
    }
    const ref = groupRef(invite.get('groupId'));
    const group = await transaction.get(ref);
    if (!group.exists) throw new HttpsError('not-found', 'Grup tidak ditemukan.');
    transaction.update(ref, {memberUids: FieldValue.arrayUnion(uid)});
    transaction.delete(inviteRef);
    return {id: invite.get('groupId')};
  });
});

exports.sendAlert = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const groupId = request.data?.groupId;
  const ref = groupRef(groupId);
  const kind = text(request.data?.kind, 40, 'Jenis peringatan');
  if (!['manual', 'low_supply', 'device_disconnected'].includes(kind)) {
    throw new HttpsError('invalid-argument', 'Jenis peringatan tidak dikenal.');
  }
  const title = text(request.data?.title, 150, 'Judul');
  const eventId = text(request.data?.clientEventId, 100, 'ID kejadian');
  if (!/^[a-zA-Z0-9-]+$/.test(eventId)) throw new HttpsError('invalid-argument', 'ID kejadian tidak valid.');
  const details = request.data?.details == null ? null : text(request.data.details, 1000, 'Detail');
  const eventRef = db.collection('events').doc(`${groupId}_${eventId}`);
  await db.runTransaction(async (transaction) => {
    const [group, existing] = await Promise.all([transaction.get(ref), transaction.get(eventRef)]);
    if (!group.exists || !group.get('memberUids').includes(uid)) {
      throw new HttpsError('permission-denied', 'Anda bukan anggota grup.');
    }
    if (existing.exists) return;
    transaction.create(eventRef, {groupId, groupName: group.get('name'),
      recipientUids: group.get('memberUids'), senderUid: uid, kind, title,
      details, occurredAt: FieldValue.serverTimestamp()});
  });
  return {id: eventRef.id};
});

exports.registerDevice = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const token = text(request.data?.token, 4096, 'Token perangkat');
  await db.collection('users').doc(uid).collection('devices').doc(hash(token)).set({
    token, platform: 'android', updatedAt: FieldValue.serverTimestamp(),
  });
  return {ok: true};
});

exports.unregisterDevice = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const token = text(request.data?.token, 4096, 'Token perangkat');
  await db.collection('users').doc(uid).collection('devices').doc(hash(token)).delete();
  return {ok: true};
});

exports.acknowledgeAlert = onCall(callOptions, async (request) => {
  const uid = uidOf(request);
  const alertId = text(request.data?.alertId, 120, 'ID peringatan');
  const ref = db.collection('users').doc(uid).collection('alerts').doc(alertId);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'Peringatan tidak ditemukan.');
  await ref.update({acknowledgedAt: FieldValue.serverTimestamp()});
  return {ok: true};
});

exports.deliverAlert = onDocumentCreated({region, document: 'events/{eventId}'}, async (event) => {
  const record = event.data?.data();
  if (!record) return;
  const recipients = Array.isArray(record.recipientUids) ? record.recipientUids : [];
  for (const uid of recipients) {
    await db.collection('users').doc(uid).collection('alerts').doc(event.params.eventId).set({
      title: record.title, kind: record.kind, groupId: record.groupId,
      groupName: record.groupName, occurredAt: record.occurredAt,
      acknowledgedAt: null,
    }, {merge: true});
    if (uid === record.senderUid) continue;
    const devices = await db.collection('users').doc(uid).collection('devices').get();
    for (const device of devices.docs) {
      try {
        await getMessaging().send({token: device.get('token'),
          notification: {title: 'MEDITRACE', body: record.title},
          data: {eventId: event.params.eventId, groupId: String(record.groupId)}});
      } catch (error) {
        if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']
            .includes(error.code)) await device.ref.delete();
        else console.error('FCM send failed', error);
      }
    }
  }
});
