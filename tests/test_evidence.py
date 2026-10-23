import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))
from bankguard.evidence import capture, verify

DATA = Path(__file__).resolve().parents[1] / 'examples' / 'before.csv'

class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.csv = Path(self.tmp.name) / 'before.csv'
        self.csv.write_bytes(DATA.read_bytes())
        self.manifest = Path(self.tmp.name) / 'before.json'
        self.env = patch.dict(os.environ, {'BANKGUARD_HMAC_KEY': 'demo-only-not-a-real-bank-secret-1234567890'})
        self.env.start(); self.addCleanup(self.env.stop)

    def test_capture_and_verify(self):
        capture(self.csv, self.manifest, 'transaction_id')
        self.assertTrue(verify(self.csv, self.manifest)['verified'])

    def test_tampered_data_rejected(self):
        capture(self.csv, self.manifest, 'transaction_id')
        self.csv.write_text(self.csv.read_text().replace('100.00', '999.00'))
        with self.assertRaisesRegex(ValueError, 'difere'):
            verify(self.csv, self.manifest)

    def test_tampered_manifest_rejected(self):
        capture(self.csv, self.manifest, 'transaction_id')
        self.manifest.write_text(self.manifest.read_text().replace('local-demo-only', 'tampered'))
        with self.assertRaisesRegex(ValueError, 'HMAC'):
            verify(self.csv, self.manifest)

    def test_no_overwrite(self):
        capture(self.csv, self.manifest, 'transaction_id')
        with self.assertRaises(FileExistsError):
            capture(self.csv, self.manifest, 'transaction_id')

    def test_short_key_rejected(self):
        with patch.dict(os.environ, {'BANKGUARD_HMAC_KEY': 'short'}):
            with self.assertRaises(ValueError):
                capture(self.csv, self.manifest, 'transaction_id')
