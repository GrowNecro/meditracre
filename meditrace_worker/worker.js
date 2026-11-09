// MEDITRACE Cloudflare Worker. Secrets: FIREBASE_PROJECT_ID,
// FIREBASE_SERVICE_ACCOUNT, RESEND_API_KEY. Variable: EMAIL_FROM.
import {createInvitationCode, normalizeInvitationCode} from './invitations.js';

const b64 = (value) => btoa(String.fromCharCode(...new Uint8Array(value)))
  .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
const enc = new TextEncoder();
const dec = new TextDecoder();
const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: {'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store'},
});
const parseJwt = (token) => {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Token tidak valid');
  const parse = (part) => JSON.parse(dec.decode(Uint8Array.from(atob(part.replace(/-/g,'+').replace(/_/g,'/')), c => c.charCodeAt(0))));
  return {header: parse(parts[0]), payload: parse(parts[1]), signed: `${parts[0]}.${parts[1]}`, signature: parts[2]};
};
const pemBytes = (pem) => {
  // Hapus header, footer, dan semua whitespace/newline
  const b64 = pem
    .replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/[\r\n\t ]/g, '');
  
  try {
    const binaryString = atob(b64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
  } catch (e) {
    console.error('DEBUG FATAL: atob failed during pemBytes', e.message);
    throw e;
  }
};
const sha256 = async (text) => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', enc.encode(text)))).map(x => x.toString(16).padStart(2,'0')).join('');
async function withRetry(operation, label, attempts = 3) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      if (attempt < attempts) {
        await new Promise((resolve) => setTimeout(resolve, 150 * 2 ** (attempt - 1)));
      }
    }
  }
  console.error(`${label} gagal setelah ${attempts} percobaan`, lastError);
  throw lastError;
}

async function verifyFirebase(request, env) {
  const token = request.headers.get('authorization')?.match(/^Bearer\s+(.+)$/)?.[1];
  if (!token) throw new Response(JSON.stringify({error:'Silakan masuk dengan Google.'}), {status:401});
  
  try {
    const jwt = parseJwt(token);
    const project = env.FIREBASE_PROJECT_ID;
    
    // Verifikasi Klaim Utama (Sangat Aman untuk tahap pengembangan)
    if (jwt.payload.aud !== project || 
        jwt.payload.iss !== `https://securetoken.google.com/${project}` || 
        jwt.payload.exp * 1000 < Date.now()) {
      throw new Response(JSON.stringify({error:'Sesi tidak valid. Silakan masuk ulang.'}), {status:401});
    }

    return jwt.payload;
  } catch (e) {
    if (e instanceof Response) throw e;
    throw new Response(JSON.stringify({error:'Sesi tidak valid.'}), {status:401});
  }
}

let cachedAccess;
async function googleAccessToken(env) {
  if (cachedAccess?.expires > Date.now() + 60000) return cachedAccess.token;
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const now = Math.floor(Date.now()/1000);
  const head = b64(enc.encode(JSON.stringify({alg:'RS256',typ:'JWT'})));
  const claim = b64(enc.encode(JSON.stringify({
    iss: sa.client_email,
    // Firestore REST dipakai untuk profil pengguna; scope FCM tetap diperlukan
    // oleh endpoint push.
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  })));
  const key = await crypto.subtle.importKey('pkcs8', pemBytes(sa.private_key), {name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'}, false, ['sign']);
  const signed = `${head}.${claim}`;
  const assertion = `${signed}.${b64(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(signed)))}`;
  const res = await fetch(sa.token_uri, {method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion})});
  if (!res.ok) throw new Error('Google OAuth gagal');
  const data = await res.json(); cachedAccess = {token:data.access_token,expires:Date.now()+data.expires_in*1000}; return data.access_token;
}

const firestoreField = (value) => {
  if (value === null || value === undefined) return {nullValue: null};
  if (typeof value === 'string') return {stringValue: value};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (typeof value === 'number' && Number.isInteger(value)) return {integerValue: String(value)};
  if (typeof value === 'number') return {doubleValue: value};
  if (Array.isArray(value)) return {arrayValue: {values: value.map(firestoreField)}};
  return {mapValue: {fields: Object.fromEntries(Object.entries(value).map(([key, item]) => [key, firestoreField(item)]))}};
};

async function firestore(env, path, init = {}) {
  const access = await googleAccessToken(env);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`,
    {
      ...init,
      headers: {
        authorization: `Bearer ${access}`,
        'content-type': 'application/json',
        ...(init.headers || {}),
      },
    },
  );
  if (!response.ok) {
    const error = await response.text();
    console.error(`Firestore ${response.status}: ${error}`);
    throw new Error('Firestore tidak dapat menyimpan data pengguna.');
  }
  return response.json();
}

const firestoreValue = (value) => {
  if (!value || typeof value !== 'object') return null;
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(firestoreValue);
  if ('mapValue' in value) return firestoreObject(value.mapValue.fields || {});
  return null;
};
const firestoreObject = (fields) => Object.fromEntries(
  Object.entries(fields || {}).map(([key, value]) => [key, firestoreValue(value)]),
);

async function firestoreGet(env, path, {optional = false} = {}) {
  const access = await googleAccessToken(env);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`,
    {headers: {authorization: `Bearer ${access}`}},
  );
  if (optional && response.status === 404) return null;
  if (!response.ok) throw new Error('Firestore tidak dapat membaca data.');
  const document = await response.json();
  return {document, data: firestoreObject(document.fields)};
}

async function firestoreDelete(env, path) {
  const access = await googleAccessToken(env);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`,
    {method: 'DELETE', headers: {authorization: `Bearer ${access}`}},
  );
  if (!response.ok) throw new Error('Firestore tidak dapat menghapus data.');
}

async function firestoreList(env, path) {
  const access = await googleAccessToken(env);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`,
    {headers: {authorization: `Bearer ${access}`}},
  );
  if (!response.ok) throw new Error('Firestore tidak dapat membaca daftar data.');
  const result = await response.json();
  return (result.documents || []).map((document) => firestoreObject(document.fields));
}

async function firestoreListDocuments(env, path) {
  const access = await googleAccessToken(env);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`,
    {headers: {authorization: `Bearer ${access}`}},
  );
  if (!response.ok) throw new Error('Firestore tidak dapat membaca daftar data.');
  const result = await response.json();
  return (result.documents || []).map((document) => ({
    id: document.name.split('/').pop(),
    data: firestoreObject(document.fields),
  }));
}

const cleanText = (value, field, maxLength = 160) => {
  if (typeof value !== 'string' || !value.trim()) throw new Error(`${field} wajib diisi.`);
  return value.trim().slice(0, maxLength);
};
function invitationCode(value) {
  try {
    return normalizeInvitationCode(value);
  } catch (_) {
    throw json({error: 'Kode undangan tidak valid.'}, 400);
  }
}

async function groupForMember(env, groupId, uid) {
  if (!Number.isSafeInteger(groupId) || groupId < 1) throw new Error('ID grup tidak valid.');
  const group = await firestoreGet(env, `groups/${groupId}`, {optional: true});
  if (!group) throw new Error('Grup keluarga tidak ditemukan.');
  if (!Array.isArray(group.data.memberUids) || !group.data.memberUids.includes(uid)) {
    throw new Error('Anda bukan anggota grup ini.');
  }
  return group.data;
}

async function groupForMemberFromFirestore(env, uid, preferredGroupId) {
  if (preferredGroupId != null) {
    try {
      return {
        id: preferredGroupId,
        data: await groupForMember(env, preferredGroupId, uid),
      };
    } catch (error) {
      console.warn('ID grup dari aplikasi tidak tersedia, mencari ulang', error);
    }
  }
  const groups = await firestoreListDocuments(env, 'groups');
  const match = groups.find((group) =>
    Array.isArray(group.data.memberUids) && group.data.memberUids.includes(uid),
  );
  if (!match) throw new Error('Grup keluarga tidak ditemukan.');
  const groupId = Number(match.id);
  if (!Number.isSafeInteger(groupId)) {
    throw new Error('ID grup keluarga tidak valid.');
  }
  return {id: groupId, data: match.data};
}

async function createFamily(env, user, data) {
  const name = cleanText(data.name, 'Nama keluarga');
  const id = Date.now();
  await firestore(env, `groups/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {
      name: firestoreField(name),
      ownerUid: firestoreField(user.sub),
      memberUids: firestoreField([user.sub]),
      createdAt: {timestampValue: new Date().toISOString()},
    }}),
  });
  return {ok: true, group: {id, name, owner_id: user.sub, members_count: 1}};
}

async function updateFamily(env, user, data) {
  const groupId = Number(data.groupId);
  const name = cleanText(data.name, 'Nama keluarga');
  const group = await groupForMember(env, groupId, user.sub);
  if (group.ownerUid !== user.sub) throw new Error('Hanya pemilik grup yang dapat mengubah nama.');
  const groupDocument = await firestoreGet(env, `groups/${groupId}`);
  await firestore(env, `groups/${groupId}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {
      ...groupDocument.document.fields,
      name: firestoreField(name),
      updatedAt: {timestampValue: new Date().toISOString()},
    }}),
  });
  return {ok: true, group: {id: groupId, name}};
}

async function deleteFamily(env, user, data) {
  const groupId = Number(data.groupId);
  const group = await groupForMember(env, groupId, user.sub);
  if (group.ownerUid !== user.sub) throw new Error('Hanya pemilik grup yang dapat menghapus grup.');
  await firestoreDelete(env, `groups/${groupId}`);
  return {ok: true};
}

async function createInvitation(env, user, data) {
  const groupId = Number(data.groupId);
  const role = data.role === 'caregiver' ? 'caregiver' : 'member';
  const group = await groupForMember(env, groupId, user.sub);
  if (group.ownerUid !== user.sub) throw new Error('Hanya pemilik grup yang dapat mengundang anggota.');
  const code = createInvitationCode();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  await firestore(env, `invitations/${code}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {
      groupId: firestoreField(groupId),
      role: firestoreField(role),
      createdBy: firestoreField(user.sub),
      expiresAt: {timestampValue: expiresAt},
      used: firestoreField(false),
    }}),
  });
  return {ok: true, code, expiresAt};
}

async function sendInvitationEmail(env, user, data) {
  const email = cleanText(data.email, 'Email penerima');
  if (!email.includes('@') || email.includes(' ')) throw new Error('Email tidak valid.');
  const code = invitationCode(data.code);
  const groupName = cleanText(data.groupName || 'keluarga MEDITRACE', 'Nama grup');
  const group = await groupForMember(env, Number(data.groupId), user.sub);
  if (group.ownerUid !== user.sub) throw new Error('Hanya pemilik grup yang dapat mengundang anggota.');
  await sendEmail(
    env,
    email,
    'Undangan keluarga',
    `Anda diundang bergabung ke grup ${escapeHtml(groupName)}. <a href="https://meditrace.grownecro.tech/invite/${code}">Buka aplikasi MEDITRACE dan terima undangan</a>. Kode undangan: ${code}. Kode berlaku 7 hari dan hanya bisa dipakai sekali.`,
  );
  return {ok: true};
}

async function joinFamily(env, user, data) {
  const code = invitationCode(data.code);
  const invitation = await firestoreGet(env, `invitations/${code}`, {optional: true});
  if (!invitation || invitation.data.used || new Date(invitation.data.expiresAt).getTime() < Date.now()) {
    throw new Error('Kode undangan tidak valid atau sudah kedaluwarsa.');
  }
  const groupId = Number(invitation.data.groupId);
  const groupResult = await firestoreGet(env, `groups/${groupId}`, {optional: true});
  if (!groupResult) throw new Error('Grup keluarga tidak ditemukan.');
  const memberUids = Array.from(new Set([...(groupResult.data.memberUids || []), user.sub]));
  await firestore(env, `groups/${groupId}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {...groupResult.document.fields, memberUids: firestoreField(memberUids)}}),
  });
  await firestore(env, `invitations/${code}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {...invitation.document.fields, used: firestoreField(true), usedBy: firestoreField(user.sub)}}),
  });
  return {ok: true, group: {id: groupId, name: groupResult.data.name}};
}

async function registerDevice(env, user, data) {
  const token = cleanText(data.token, 'Token perangkat', 4096);
  const id = await sha256(token);
  await firestore(env, `users/${encodeURIComponent(user.sub)}/devices/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {token: firestoreField(token), updatedAt: {timestampValue: new Date().toISOString()}}}),
  });
  return {ok: true};
}

async function unregisterDevice(env, user, data) {
  const token = cleanText(data.token, 'Token perangkat', 4096);
  await firestoreDelete(env, `users/${encodeURIComponent(user.sub)}/devices/${await sha256(token)}`);
  return {ok: true};
}

async function sendAlert(env, user, data) {
  const requestedGroupId = Number(data.groupId);
  const resolvedGroup = await groupForMemberFromFirestore(
    env,
    user.sub,
    Number.isSafeInteger(requestedGroupId) ? requestedGroupId : null,
  );
  const groupId = resolvedGroup.id;
  const group = resolvedGroup.data;
  const title = cleanText(data.title, 'Judul peringatan');
  const clientEventId = cleanText(data.clientEventId, 'ID kejadian', 200);
  const alertId = `${groupId}-${clientEventId}`;
  const alert = await firestoreGet(env, `groups/${groupId}/events/${encodeURIComponent(alertId)}`, {optional: true});
  if (alert) return {ok: true, duplicate: true};
  const details = typeof data.details === 'string' ? data.details.slice(0, 1000) : null;
  const senderProfile = await firestoreGet(
    env,
    `users/${encodeURIComponent(user.sub)}`,
    {optional: true},
  );
  const registeredSenderEmail = senderProfile?.data?.email;
  const senderEmail = typeof registeredSenderEmail === 'string' &&
      registeredSenderEmail.includes('@')
    ? registeredSenderEmail
    : (typeof user.email === 'string' && user.email.includes('@')
        ? user.email
        : null);
  const now = new Date().toISOString();
  await firestore(env, `groups/${groupId}/events/${encodeURIComponent(alertId)}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {
      title: firestoreField(title), kind: firestoreField(typeof data.kind === 'string' ? data.kind : 'manual'),
      details: firestoreField(details), senderUid: firestoreField(user.sub),
      senderEmail: firestoreField(senderEmail), occurredAt: {timestampValue: now},
    }}),
  });
  for (const uid of group.memberUids) {
    await firestore(env, `users/${encodeURIComponent(uid)}/alerts/${encodeURIComponent(alertId)}`, {
      method: 'PATCH',
      body: JSON.stringify({fields: {
        title: firestoreField(title), groupName: firestoreField(group.name), groupId: firestoreField(groupId),
        details: firestoreField(details), senderEmail: firestoreField(senderEmail),
        occurredAt: {timestampValue: now}, acknowledgedAt: firestoreField(null),
      }}),
    });
  }
  // Firestore menyimpan inbox secara permanen. Push FCM adalah pelengkap agar
  // caregiver yang aplikasinya tertutup tetap segera menerima eskalasi.
  const recipients = await Promise.all(group.memberUids
    .filter((uid) => uid !== user.sub).map(async (uid) => {
    try {
      return await firestoreList(env, `users/${encodeURIComponent(uid)}/devices`);
    } catch (error) {
      console.error(`Tidak dapat membaca token perangkat ${uid}`, error);
      return [];
    }
  }));
  const pushResults = await Promise.allSettled(recipients.flat().map((device) =>
    typeof device.token === 'string'
      ? withRetry(() => sendFcm(env, device.token, title, details || title), 'FCM')
      : Promise.resolve(),
  ));
  pushResults.filter((result) => result.status === 'rejected')
    .forEach((result) => console.error('FCM caregiver gagal', result.reason));
  const emailKinds = new Set([
    'separation_escalation',
    'medbox_left_behind',
    'dose_status',
  ]);
  if (emailKinds.has(data.kind)) {
    const emailResults = await Promise.allSettled(group.memberUids
      .filter((uid) => uid !== user.sub).map(async (uid) => {
      const profile = await firestoreGet(env, `users/${encodeURIComponent(uid)}`, {optional: true});
      const email = profile?.data?.email;
      if (typeof email === 'string' && email.includes('@')) {
        await withRetry(() => sendEmail(
          env,
          email,
          title,
          `<strong>Pengirim:</strong> ${escapeHtml(senderEmail || 'Email tidak tersedia')}<br><br>` +
          `${escapeHtml(details || title)}<br><br>` +
          `Buka aplikasi MEDITRACE untuk melihat dan menangani peringatan ini.`,
        ), 'Email caregiver');
        return true;
      }
      return false;
    }));
    emailResults.filter((result) => result.status === 'rejected')
      .forEach((result) => console.error('Email caregiver gagal', result.reason));
    return {
      ok: true,
      pushSent: pushResults.filter((result) => result.status === 'fulfilled').length,
      pushFailed: pushResults.filter((result) => result.status === 'rejected').length,
      emailSent: emailResults.filter(
        (result) => result.status === 'fulfilled' && result.value === true,
      ).length,
      emailFailed: emailResults.filter((result) => result.status === 'rejected').length,
    };
  }
  return {
    ok: true,
    pushSent: pushResults.filter((result) => result.status === 'fulfilled').length,
    pushFailed: pushResults.filter((result) => result.status === 'rejected').length,
    emailSent: 0,
    emailFailed: 0,
  };
}

async function acknowledgeAlert(env, user, data) {
  const alertId = cleanText(data.alertId, 'ID peringatan', 300);
  const alert = await firestoreGet(env, `users/${encodeURIComponent(user.sub)}/alerts/${encodeURIComponent(alertId)}`, {optional: true});
  if (!alert) throw new Error('Peringatan tidak ditemukan.');
  await firestore(env, `users/${encodeURIComponent(user.sub)}/alerts/${encodeURIComponent(alertId)}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {...alert.document.fields, acknowledgedAt: {timestampValue: new Date().toISOString()}}}),
  });
  return {ok: true};
}

async function ensureUser(env, user) {
  const name = typeof user.name === 'string' && user.name.trim()
    ? user.name.trim().slice(0, 120)
    : (typeof user.email === 'string' ? user.email : 'Pengguna');
  await firestore(env, `users/${encodeURIComponent(user.sub)}`, {
    method: 'PATCH',
    body: JSON.stringify({
      fields: {
        name: firestoreField(name),
        email: firestoreField(typeof user.email === 'string' ? user.email : null),
        updatedAt: {timestampValue: new Date().toISOString()},
      },
    }),
  });
  return {id: user.sub};
}

async function sendEmail(env, to, title, details) {
  const res = await fetch('https://api.resend.com/emails', {method:'POST',headers:{authorization:`Bearer ${env.RESEND_API_KEY}`,'content-type':'application/json'},body:JSON.stringify({from:env.EMAIL_FROM,to:[to],subject:`MEDITRACE: ${title}`,html:`<h2>MEDITRACE</h2><p>${details || title}</p>`})});
  if (!res.ok) throw new Error('Resend menolak email');
}

function escapeHtml(value) {
  return value.replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[character]));
}

async function sendFcm(env, token, title, details) {
  const access = await googleAccessToken(env);
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {method:'POST',headers:{authorization:`Bearer ${access}`,'content-type':'application/json'},body:JSON.stringify({message:{token,notification:{title:'MEDITRACE',body:title},data:{details:details || ''}}})});
  if (!res.ok) throw new Error('FCM menolak notifikasi');
}

function invitationPage(request, code) {
  const indonesian = /^id\b/i.test(request.headers.get('accept-language') || '');
  const text = indonesian ? {
    title: 'Undangan keluarga',
    body: 'Buka MEDITRACE untuk menerima undangan dan bergabung ke grup keluarga.',
    open: 'Buka aplikasi MEDITRACE',
    download: 'Unduh aplikasi Android',
    code: 'Kode undangan',
    hint: 'Jika aplikasi belum terpasang, instal terlebih dahulu. Setelah masuk, buka Profil → Keluarga → Masukkan kode undangan dan gunakan kode ini.',
    expiry: 'Kode berlaku 7 hari dan hanya bisa dipakai sekali. Undangan akan diperiksa saat Anda menerima di aplikasi.',
  } : {
    title: 'Family invitation',
    body: 'Open MEDITRACE to accept this invitation and join your family group.',
    open: 'Open MEDITRACE app',
    download: 'Download Android app',
    code: 'Invitation code',
    hint: 'If the app is not installed, install it first. After signing in, open Profile → Family → Enter invitation code and use this code.',
    expiry: 'Codes are valid for 7 days and can only be used once. Your invitation will be checked when you accept it in the app.',
  };
  const fallback = encodeURIComponent(`https://meditrace.grownecro.tech/invite/${code}`);
  const intent = `intent://meditrace.grownecro.tech/invite/${code}#Intent;scheme=https;package=com.example.meditrace;S.browser_fallback_url=${fallback};end`;
  return new Response(`<!doctype html>
<html lang="${indonesian ? 'id' : 'en'}"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow"><title>${text.title} · MEDITRACE</title>
<style>
*{box-sizing:border-box}body{margin:0;padding:32px 20px;background:#f2fffe;color:#123b3c;font:16px/1.6 system-ui,sans-serif;min-height:100vh;display:grid;place-items:center}
main{width:100%;max-width:480px;background:white;border:1px solid #d5efec;border-radius:24px;padding:32px;box-shadow:0 12px 40px #075e630d}
.brand{font-weight:700;color:#087e83;letter-spacing:.08em;font-size:13px}h1{font-size:28px;line-height:1.2;margin:18px 0}p{color:#486869}
a{display:block;border-radius:12px;padding:12px 16px;text-decoration:none;text-align:center;font-weight:600;margin:12px 0;background:#087e83;color:white}
a.secondary{background:#e7fffd;color:#075e63}code{display:block;background:#f2fffe;border-radius:12px;padding:12px;overflow-wrap:anywhere;font-size:17px;user-select:all}
label{display:block;font-weight:600;margin:24px 0 8px}small{display:block;color:#557373;margin-top:20px}
</style></head><body><main>
<div class="brand">MEDITRACE</div><h1>${text.title}</h1><p>${text.body}</p>
<a href="${intent}">${text.open}</a>
<a class="secondary" href="https://github.com/GrowNecro/meditracre/releases/latest/download/meditrace.apk">${text.download}</a>
<label>${text.code}</label><code>${code}</code><p>${text.hint}</p><small>${text.expiry}</small>
</main></body></html>`, {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
      'referrer-policy': 'no-referrer',
      'x-content-type-options': 'nosniff',
      'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'",
    },
  });
}

export default { async fetch(request, env) {
  const url = new URL(request.url);
  const invitation = /^\/invite\/([0-9a-f]{24}|[0-9a-z]{9})\/?$/i.exec(url.pathname);
  if (request.method === 'GET' && invitation) {
    return invitationPage(request, invitation[1].toUpperCase());
  }
  if (request.method === 'GET' && url.pathname === '/.well-known/assetlinks.json') {
    const fingerprints = (env.ANDROID_SHA256_CERT_FINGERPRINTS || '')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
    if (fingerprints.length === 0) {
      return json({error: 'Android signing fingerprint belum dikonfigurasi.'}, 503);
    }
    return json([{
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'com.example.meditrace',
        sha256_cert_fingerprints: fingerprints,
      },
    }]);
  }
  if (request.method === 'GET' && url.pathname === '/healthz') return json({ok:true, service:'meditrace-api', firebaseProject:env.FIREBASE_PROJECT_ID, credentialsConfigured:!!env.FIREBASE_SERVICE_ACCOUNT, emailConfigured:!!env.RESEND_API_KEY});
  const endpoints = new Set([
    '/v1/ensureUser', '/v1/testEmail', '/v1/testPush',
    '/v1/createFamily', '/v1/updateFamily', '/v1/deleteFamily',
    '/v1/joinFamily', '/v1/createInvitation',
    '/v1/sendInvitationEmail',
    '/v1/registerDevice', '/v1/unregisterDevice', '/v1/sendAlert',
    '/v1/acknowledgeAlert',
  ]);
  if (request.method !== 'POST' || !endpoints.has(url.pathname)) return json({error:'Endpoint tidak ditemukan.'},404);
  try {
    const user = await verifyFirebase(request, env);
    const data = request.headers.get('content-length') === '0' ? {} : await request.json().catch(() => ({}));
    if (url.pathname === '/v1/ensureUser') {
      return json(await ensureUser(env, user));
    } else if (url.pathname === '/v1/createFamily') {
      return json(await createFamily(env, user, data));
    } else if (url.pathname === '/v1/updateFamily') {
      return json(await updateFamily(env, user, data));
    } else if (url.pathname === '/v1/deleteFamily') {
      return json(await deleteFamily(env, user, data));
    } else if (url.pathname === '/v1/joinFamily') {
      return json(await joinFamily(env, user, data));
    } else if (url.pathname === '/v1/createInvitation') {
      return json(await createInvitation(env, user, data));
    } else if (url.pathname === '/v1/sendInvitationEmail') {
      return json(await sendInvitationEmail(env, user, data));
    } else if (url.pathname === '/v1/registerDevice') {
      return json(await registerDevice(env, user, data));
    } else if (url.pathname === '/v1/unregisterDevice') {
      return json(await unregisterDevice(env, user, data));
    } else if (url.pathname === '/v1/sendAlert') {
      return json(await sendAlert(env, user, data));
    } else if (url.pathname === '/v1/acknowledgeAlert') {
      return json(await acknowledgeAlert(env, user, data));
    } else if (url.pathname === '/v1/testEmail') {
      if (typeof data.email !== 'string' || !data.email.includes('@')) return json({error:'Email tidak valid.'},400);
      await sendEmail(env, data.email, 'Tes notifikasi', 'Email MEDITRACE berhasil dikirim.');
    } else {
      if (typeof data.token !== 'string' || data.token.length < 20) return json({error:'Token FCM tidak valid.'},400);
      await sendFcm(env, data.token, 'Tes notifikasi', 'Push MEDITRACE berhasil dikirim.');
    }
    return json({ok:true});
  } catch (error) {
    if (error instanceof Response) return error;
    const requestId = crypto.randomUUID();
    const detail = error instanceof Error ? error.message : String(error);
    console.error(`[${requestId}] ${url.pathname}`, detail);
    return json({
      error: 'Server sedang bermasalah.',
      requestId,
      detail: url.pathname === '/v1/sendAlert' ? detail : undefined,
    }, 500);
  }
}};
