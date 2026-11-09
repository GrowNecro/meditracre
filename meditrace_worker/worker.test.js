import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import worker from './worker.js';
import {createInvitationCode, normalizeInvitationCode} from './invitations.js';

const code = '0123456789ABCDEF01234567';
const origin = 'https://meditrace.grownecro.tech';

test('new codes use the same full 24-character format as the Android app', () => {
  const generated = createInvitationCode();
  assert.match(generated, /^[0-9A-F]{24}$/);
  assert.equal(normalizeInvitationCode(` ${generated.toLowerCase()} `), generated);
});

test('legacy nine-character base36 codes remain valid without accepting arbitrary strings', () => {
  assert.equal(normalizeInvitationCode('z9x8w7v6u'), 'Z9X8W7V6U');
  for (const invalid of [null, '', 'short', 'Z'.repeat(24), '../secret', code + 'extra']) {
    assert.throws(() => normalizeInvitationCode(invalid));
  }
});

test('existing emailed invitation links have a working landing page too', async () => {
  const response = await worker.fetch(new Request(`${origin}/invite/z9x8w7v6u`), {});
  assert.equal(response.status, 200);
  assert.ok((await response.text()).includes('<code>Z9X8W7V6U</code>'));
});

test('invitation URL shows an app handoff and manual code instead of a 404', async () => {
  const response = await worker.fetch(new Request(`${origin}/invite/${code.toLowerCase()}?utm_source=email`), {});
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /text\/html/);
  assert.equal(response.headers.get('referrer-policy'), 'no-referrer');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const html = await response.text();
  assert.match(html, new RegExp(`intent://meditrace.grownecro.tech/invite/${code}#Intent;scheme=https;package=com.example.meditrace;`));
  assert.ok(html.includes(`<code>${code}</code>`));
  assert.ok(html.includes('/releases/latest/download/meditrace.apk'));
  assert.ok(html.includes('browser_fallback_url='));
});

test('invitation page supports Indonesian and an optional trailing slash', async () => {
  const response = await worker.fetch(new Request(`${origin}/invite/${code}/`, {
    headers: {'accept-language': 'id-ID,id;q=0.9,en;q=0.8'},
  }), {});
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.ok(html.includes('<html lang="id">'));
  assert.ok(html.includes('Undangan keluarga'));
});

test('malformed invitation paths do not reflect untrusted input', async () => {
  for (const path of ['/invite/short', '/invite/<script>', `/invite/${code}/extra`]) {
    const response = await worker.fetch(new Request(origin + path), {});
    assert.equal(response.status, 404);
    assert.match(response.headers.get('content-type'), /application\/json/);
  }
});

test('App Links configuration includes both local debug and stable release certificates', async () => {
  const configuration = await readFile(new URL('./wrangler.toml', import.meta.url), 'utf8');
  const fingerprints = /^ANDROID_SHA256_CERT_FINGERPRINTS = "([^"]+)"/m.exec(configuration)[1];
  const response = await worker.fetch(new Request(`${origin}/.well-known/assetlinks.json`), {
    ANDROID_SHA256_CERT_FINGERPRINTS: fingerprints,
  });
  const [{target}] = await response.json();
  assert.equal(target.package_name, 'com.example.meditrace');
  assert.ok(target.sha256_cert_fingerprints.includes('FE:B8:C1:10:63:A4:28:D3:71:43:97:9C:2B:65:CE:86:B4:FB:B4:BD:E2:B3:CA:CD:DB:C2:98:AD:6B:72:D5:ED'));
  assert.ok(target.sha256_cert_fingerprints.includes('38:41:FC:6E:BD:EC:F5:F2:C2:8C:7E:71:64:25:E9:0F:3D:FA:DD:65:ED:4F:76:78:C0:8D:38:B7:20:FF:5F:1F'));
});
