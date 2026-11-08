import base64
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest

from prepare_android_release import REQUIRED_SECRETS, validate_configuration


class ReleaseConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.firebase = {
            "project_info": {"project_id": "example", "project_number": "123"},
            "client": [{
                "client_info": {
                    "mobilesdk_app_id": "example-app-id",
                    "android_client_info": {"package_name": "com.example.meditrace"},
                },
                "api_key": [{"current_key": "example-api-key"}],
            }],
        }
        self.environment = dict.fromkeys(REQUIRED_SECRETS, "example-password")
        self.environment["GOOGLE_SERVICES_JSON"] = json.dumps(self.firebase)
        self.environment["ANDROID_KEYSTORE_BASE64"] = base64.b64encode(b"test keystore").decode()

    def test_missing_secrets_are_reported_together_without_values(self):
        with self.assertRaises(ValueError) as result:
            validate_configuration({"GOOGLE_SERVICES_JSON": "private-value"})
        self.assertIn("ANDROID_KEYSTORE_BASE64", str(result.exception))
        self.assertIn("ANDROID_KEY_PASSWORD", str(result.exception))
        self.assertNotIn("private-value", str(result.exception))

    def test_invalid_json_does_not_leak_input(self):
        self.environment["GOOGLE_SERVICES_JSON"] = "private-value"
        with self.assertRaises(ValueError) as result:
            validate_configuration(self.environment)
        self.assertNotIn("private-value", str(result.exception))

    def test_rejects_service_account_and_other_app_configuration(self):
        for value in [[], None, {"type": "service_account"}, {"project_info": {}},
                      {**self.firebase, "client": []}]:
            with self.subTest(value=value):
                self.environment["GOOGLE_SERVICES_JSON"] = json.dumps(value)
                with self.assertRaises(ValueError):
                    validate_configuration(self.environment)
        other = deepcopy(self.firebase)
        other["client"][0]["client_info"]["android_client_info"]["package_name"] = "other.app"
        self.environment["GOOGLE_SERVICES_JSON"] = json.dumps(other)
        with self.assertRaisesRegex(ValueError, "com.example.meditrace"):
            validate_configuration(self.environment)

    def test_requires_mobile_app_id_and_api_key(self):
        for field in ["client_info", "api_key"]:
            value = deepcopy(self.firebase)
            value["client"][0].pop(field)
            self.environment["GOOGLE_SERVICES_JSON"] = json.dumps(value)
            with self.subTest(field=field), self.assertRaises(ValueError):
                validate_configuration(self.environment)

    def test_supports_multiple_clients_and_wrapped_base64(self):
        self.firebase["client"].insert(0, {"client_info": {}})
        self.environment["GOOGLE_SERVICES_JSON"] = json.dumps(self.firebase)
        self.environment["ANDROID_KEYSTORE_BASE64"] += "\n  "
        firebase, keystore = validate_configuration(self.environment)
        self.assertEqual(firebase, self.firebase)
        self.assertEqual(keystore, b"test keystore")

    def test_rejects_corrupted_or_empty_base64(self):
        for encoded in ["invalid!", "====", " "]:
            self.environment["ANDROID_KEYSTORE_BASE64"] = encoded
            with self.subTest(encoded=encoded), self.assertRaises(ValueError):
                validate_configuration(self.environment)

    def test_invalid_configuration_does_not_overwrite_files(self):
        with TemporaryDirectory() as directory:
            firebase = Path(directory) / "google-services.json"
            keystore = Path(directory) / "release.jks"
            firebase.write_text("existing config")
            keystore.write_bytes(b"existing key")
            result = subprocess.run(
                [sys.executable, str(Path(__file__).with_name("prepare_android_release.py")),
                 "--firebase-path", str(firebase), "--keystore-path", str(keystore)],
                env={"GOOGLE_SERVICES_JSON": "private-value"},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 1)
            self.assertNotIn("private-value", result.stderr)
            self.assertEqual(firebase.read_text(), "existing config")
            self.assertEqual(keystore.read_bytes(), b"existing key")


if __name__ == "__main__":
    unittest.main()
