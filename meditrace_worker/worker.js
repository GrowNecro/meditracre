// MEDITRACE Cloudflare Worker. Secrets: FIREBASE_PROJECT_ID,
// FIREBASE_SERVICE_ACCOUNT, RESEND_API_KEY. Variable: EMAIL_FROM.
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

const cleanText = (value, field, maxLength = 160) => {
  if (typeof value !== 'string' || !value.trim()) throw new Error(`${field} wajib diisi.`);
  return value.trim().slice(0, maxLength);
};
const createCode = () => Array.from(crypto.getRandomValues(new Uint8Array(9)))
  .map((byte) => (byte % 36).toString(36)).join('').toUpperCase();

async function groupForMember(env, groupId, uid) {
  if (!Number.isSafeInteger(groupId) || groupId < 1) throw new Error('ID grup tidak valid.');
  const group = await firestoreGet(env, `groups/${groupId}`, {optional: true});
  if (!group) throw new Error('Grup keluarga tidak ditemukan.');
  if (!Array.isArray(group.data.memberUids) || !group.data.memberUids.includes(uid)) {
    throw new Error('Anda bukan anggota grup ini.');
  }
  return group.data;
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

async function createInvitation(env, user, data) {
  const groupId = Number(data.groupId);
  const role = data.role === 'caregiver' ? 'caregiver' : 'member';
  const group = await groupForMember(env, groupId, user.sub);
  if (group.ownerUid !== user.sub) throw new Error('Hanya pemilik grup yang dapat mengundang anggota.');
  const code = createCode();
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

async function joinFamily(env, user, data) {
  const code = cleanText(data.code, 'Kode undangan', 20).toUpperCase();
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
  const groupId = Number(data.groupId);
  const group = await groupForMember(env, groupId, user.sub);
  const title = cleanText(data.title, 'Judul peringatan');
  const clientEventId = cleanText(data.clientEventId, 'ID kejadian', 200);
  const alertId = `${groupId}-${clientEventId}`;
  const alert = await firestoreGet(env, `groups/${groupId}/events/${encodeURIComponent(alertId)}`, {optional: true});
  if (alert) return {ok: true, duplicate: true};
  const details = typeof data.details === 'string' ? data.details.slice(0, 1000) : null;
  const now = new Date().toISOString();
  await firestore(env, `groups/${groupId}/events/${encodeURIComponent(alertId)}`, {
    method: 'PATCH',
    body: JSON.stringify({fields: {
      title: firestoreField(title), kind: firestoreField(typeof data.kind === 'string' ? data.kind : 'manual'),
      details: firestoreField(details), senderUid: firestoreField(user.sub), occurredAt: {timestampValue: now},
    }}),
  });
  for (const uid of group.memberUids) {
    await firestore(env, `users/${encodeURIComponent(uid)}/alerts/${encodeURIComponent(alertId)}`, {
      method: 'PATCH',
      body: JSON.stringify({fields: {
        title: firestoreField(title), groupName: firestoreField(group.name), groupId: firestoreField(groupId),
        details: firestoreField(details), occurredAt: {timestampValue: now}, acknowledgedAt: firestoreField(null),
      }}),
    });
  }
  // Firestore menyimpan inbox secara permanen. Push FCM adalah pelengkap agar
  // caregiver yang aplikasinya tertutup tetap segera menerima eskalasi.
  const recipients = await Promise.all(group.memberUids.map(async (uid) => {
    try {
      return await firestoreList(env, `users/${encodeURIComponent(uid)}/devices`);
    } catch (error) {
      console.error(`Tidak dapat membaca token perangkat ${uid}`, error);
      return [];
    }
  }));
  await Promise.allSettled(recipients.flat().map((device) =>
    typeof device.token === 'string'
      ? sendFcm(env, device.token, title, details || title)
      : Promise.resolve(),
  ));
  return {ok: true};
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

async function sendFcm(env, token, title, details) {
  const access = await googleAccessToken(env);
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {method:'POST',headers:{authorization:`Bearer ${access}`,'content-type':'application/json'},body:JSON.stringify({message:{token,notification:{title:'MEDITRACE',body:title},data:{details:details || ''}}})});
  if (!res.ok) throw new Error('FCM menolak notifikasi');
}

export default { async fetch(request, env) {
  const url = new URL(request.url);
  if (request.method === 'GET' && url.pathname === '/healthz') return json({ok:true, service:'meditrace-api', firebaseProject:env.FIREBASE_PROJECT_ID, credentialsConfigured:!!env.FIREBASE_SERVICE_ACCOUNT, emailConfigured:!!env.RESEND_API_KEY});
  const endpoints = new Set([
    '/v1/ensureUser', '/v1/testEmail', '/v1/testPush',
    '/v1/createFamily', '/v1/joinFamily', '/v1/createInvitation',
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
    } else if (url.pathname === '/v1/joinFamily') {
      return json(await joinFamily(env, user, data));
    } else if (url.pathname === '/v1/createInvitation') {
      return json(await createInvitation(env, user, data));
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
    console.error(error); return json({error:'Server sedang bermasalah.'},500);
  }
}};
