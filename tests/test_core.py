import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from bankguard.core import compare, fingerprint

BASE = Path(__file__).resolve().parents[1] / "examples"

class SnapshotTests(unittest.TestCase):
    def test_three_rules(self):
        result = compare(BASE / "before.csv", BASE / "after.csv", "transaction_id")
        self.assertEqual([x["key"] for x in result["R1_modified"]], ["TX002"])
        self.assertEqual(result["R2_inserted_keys"], ["TX004"])
        self.assertEqual(result["R3_deleted_keys"], ["TX003"])
        self.assertEqual(result["unchanged_count"], 1)

    def test_fingerprint_independent_of_column_order(self):
        self.assertEqual(fingerprint({"a": "1", "b": "2"}), fingerprint({"b": "2", "a": "1"}))

    def test_missing_key_rejected(self):
        with self.assertRaises(ValueError):
            compare(BASE / "before.csv", BASE / "after.csv", "missing")

if __name__ == "__main__":
    unittest.main()
