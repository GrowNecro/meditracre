"""Validate Actions secrets before provisioning temporary Android build files."""

import argparse
import base64
import binascii
import json
import os
from pathlib import Path
import sys


REQUIRED_SECRETS = (
    "GOOGLE_SERVICES_JSON",
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "ANDROID_KEY_PASSWORD",
)
PACKAGE_NAME = "com.example.meditrace"


def validate_configuration(environment):
    missing = [name for name in REQUIRED_SECRETS if not environment.get(name, "").strip()]
    if missing:
        raise ValueError("Repository secrets belum diisi: " + ", ".join(missing))

    try:
        firebase = json.loads(environment["GOOGLE_SERVICES_JSON"])
    except (ValueError, TypeError):
        raise ValueError("GOOGLE_SERVICES_JSON harus berisi JSON utuh dari Firebase Android.") from None
    if not isinstance(firebase, dict):
        raise ValueError("GOOGLE_SERVICES_JSON harus berupa objek konfigurasi Firebase Android.")
    project = firebase.get("project_info")
    if not isinstance(project, dict) or not project.get("project_id") or not project.get("project_number"):
        raise ValueError("GOOGLE_SERVICES_JSON tidak memiliki project_info yang lengkap.")
    clients = firebase.get("client")
    if not isinstance(clients, list):
        raise ValueError("GOOGLE_SERVICES_JSON tidak memiliki daftar client Android.")
    matching_client = False
    for client in clients:
        if not isinstance(client, dict):
            continue
        info = client.get("client_info")
        if not isinstance(info, dict):
            continue
        android = info.get("android_client_info")
        if isinstance(android, dict) and android.get("package_name") == PACKAGE_NAME:
            api_keys = client.get("api_key")
            matching_client = bool(info.get("mobilesdk_app_id")) and any(
                isinstance(key, dict) and bool(key.get("current_key"))
                for key in (api_keys if isinstance(api_keys, list) else [])
            )
            if matching_client:
                break
    if not matching_client:
        raise ValueError(f"GOOGLE_SERVICES_JSON harus memiliki client lengkap untuk {PACKAGE_NAME}.")

    try:
        encoded = "".join(environment["ANDROID_KEYSTORE_BASE64"].split())
        keystore = base64.b64decode(encoded, validate=True)
    except (ValueError, binascii.Error):
        raise ValueError("ANDROID_KEYSTORE_BASE64 bukan Base64 yang valid; konversi ulang file .jks.") from None
    if not keystore:
        raise ValueError("ANDROID_KEYSTORE_BASE64 menghasilkan keystore kosong.")
    return firebase, keystore


def write_private_file(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as output:
        os.chmod(path, 0o600)
        output.write(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--firebase-path", type=Path, required=True)
    parser.add_argument("--keystore-path", type=Path, required=True)
    args = parser.parse_args()
    try:
        firebase, keystore = validate_configuration(os.environ)
    except ValueError as error:
        # Messages contain names of invalid settings, never their values.
        print(f"::error::{error}", file=sys.stderr)
        return 1
    write_private_file(args.firebase_path, (json.dumps(firebase) + "\n").encode())
    write_private_file(args.keystore_path, keystore)
    print("Konfigurasi Firebase dan signing tersedia. Keytool akan memeriksa keystore dan alias.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
