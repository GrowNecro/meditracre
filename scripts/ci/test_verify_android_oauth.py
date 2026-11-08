from copy import deepcopy
import hashlib
import unittest

from verify_android_oauth import fingerprint, validate_oauth_certificate


class AndroidOAuthTest(unittest.TestCase):
    def setUp(self):
        self.release = b"release certificate"
        self.debug = b"debug certificate"
        self.android = {
            "client_type": 1,
            "android_info": {
                "package_name": "com.example.meditrace",
                "certificate_hash": hashlib.sha1(self.release).hexdigest(),
            },
        }
        self.firebase = {"client": [{
            "client_info": {"android_client_info": {"package_name": "com.example.meditrace"}},
            "oauth_client": [self.android, {"client_type": 3, "client_id": "web-client"}],
        }]}

    def test_accepts_release_certificate(self):
        validate_oauth_certificate(self.firebase, self.release)

    def test_rejects_different_signer_even_when_project_matches(self):
        with self.assertRaisesRegex(ValueError, "SHA-1"):
            validate_oauth_certificate(self.firebase, self.debug)

    def test_accepts_registered_debug_and_release_clients(self):
        debug = deepcopy(self.android)
        debug["android_info"]["certificate_hash"] = hashlib.sha1(self.debug).hexdigest()
        self.firebase["client"][0]["oauth_client"].insert(0, debug)
        validate_oauth_certificate(self.firebase, self.release)

    def test_requires_matching_package(self):
        self.android["android_info"]["package_name"] = "other.package"
        with self.assertRaises(ValueError):
            validate_oauth_certificate(self.firebase, self.release)

    def test_requires_web_client(self):
        self.firebase["client"][0]["oauth_client"].pop()
        with self.assertRaisesRegex(ValueError, "OAuth Web client"):
            validate_oauth_certificate(self.firebase, self.release)

    def test_normalizes_fingerprint_case_and_colons(self):
        self.android["android_info"]["certificate_hash"] = fingerprint(self.release, "sha1")
        validate_oauth_certificate(self.firebase, self.release)
        self.assertEqual(fingerprint(b"abc", "sha1"), "A9:99:3E:36:47:06:81:6A:BA:3E:25:71:78:50:C2:6C:9C:D0:D8:9D")


if __name__ == "__main__":
    unittest.main()
