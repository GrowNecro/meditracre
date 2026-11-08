"""Check that Firebase Android OAuth configuration matches the release signer."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

from prepare_android_release import PACKAGE_NAME


def fingerprint(certificate, algorithm):
    value = hashlib.new(algorithm, certificate).hexdigest().upper()
    return ":".join(value[index:index + 2] for index in range(0, len(value), 2))


def validate_oauth_certificate(firebase, certificate):
    expected = hashlib.sha1(certificate).hexdigest()
    for client in firebase.get("client", []):
        info = client.get("client_info", {}).get("android_client_info", {})
        if info.get("package_name") != PACKAGE_NAME:
            continue
        oauth = client.get("oauth_client", [])
        if not any(item.get("client_type") == 3 and item.get("client_id") for item in oauth):
            raise ValueError("Konfigurasi Firebase tidak memiliki OAuth Web client (client_type: 3). Aktifkan Google Sign-In dan unduh ulang google-services.json.")
        for item in oauth:
            android = item.get("android_info", {})
            registered = str(android.get("certificate_hash", "")).replace(":", "").lower()
            if (item.get("client_type") == 1
                    and android.get("package_name") == PACKAGE_NAME
                    and registered == expected):
                return
    raise ValueError(
        "SHA-1 keystore release tidak tercantum pada OAuth Android di GOOGLE_SERVICES_JSON. "
        "Tambahkan fingerprint release di Firebase Project settings > Your apps > "
        f"{PACKAGE_NAME}, unduh ulang google-services.json, lalu perbarui secret GOOGLE_SERVICES_JSON. "
        "Jangan mengubah certificate_hash di JSON secara manual."
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--firebase-path", type=Path, required=True)
    parser.add_argument("--keystore-path", type=Path, required=True)
    args = parser.parse_args()
    # Password is read by keytool from the environment, never from an argument.
    result = subprocess.run(
        ["keytool", "-exportcert", "-keystore", str(args.keystore_path),
         "-storepass:env", "ANDROID_KEYSTORE_PASSWORD", "-alias", os.environ["ANDROID_KEY_ALIAS"]],
        capture_output=True,
    )
    if result.returncode != 0:
        print("::error::Tidak dapat membaca sertifikat release. Periksa keystore, password, dan alias.", file=sys.stderr)
        return 1
    certificate = result.stdout
    if not certificate:
        print("::error::Sertifikat release kosong.", file=sys.stderr)
        return 1
    report = (
        "### Sertifikat Android release\n\n"
        f"Package: `{PACKAGE_NAME}`\n\n"
        f"SHA-1: `{fingerprint(certificate, 'sha1')}`\n\n"
        f"SHA-256: `{fingerprint(certificate, 'sha256')}`\n\n"
        "Daftarkan fingerprint ini di Firebase. Untuk App Links, daftarkan SHA-256 "
        "di ANDROID_SHA256_CERT_FINGERPRINTS pada Worker.\n"
    )
    print(report)
    if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(summary).open("a", encoding="utf8") as output:
            output.write(report)
    firebase = json.loads(args.firebase_path.read_text(encoding="utf-8-sig"))
    try:
        validate_oauth_certificate(firebase, certificate)
    except ValueError as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    print("OAuth Android cocok dengan sertifikat keystore release.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
