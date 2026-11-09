export function createInvitationCode() {
  return Array.from(crypto.getRandomValues(new Uint8Array(12)),
    (byte) => byte.toString(16).padStart(2, '0')).join('').toUpperCase();
}

export function normalizeInvitationCode(value) {
  if (typeof value !== 'string') throw new Error('Kode undangan tidak valid.');
  const code = value.trim().toUpperCase();
  // Keep existing nine-character invitations usable until they expire.
  if (!/^(?:[0-9A-F]{24}|[0-9A-Z]{9})$/.test(code)) {
    throw new Error('Kode undangan tidak valid.');
  }
  return code;
}
