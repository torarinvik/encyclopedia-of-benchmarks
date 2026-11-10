"""Check the sampled suffix-array fixture against both independent models."""

import json
from pathlib import Path
import unittest

import psi_suffix_array_access_oracle as primary
import psi_suffix_array_access_verifier_oracle as independent

ROOT = Path(__file__).resolve().parents[1]


class PsiSuffixArrayWorkloadTests(unittest.TestCase):
    def test_stride_three_fixture_has_consistent_samples_and_two_hops(self):
        workload = json.loads((ROOT / "benchmarks/p/psi_suffix_array_access/workload.json").read_text())
        case = next(item for item in workload["cases"]
                    if item["id"] == "banana-query-before-stride-three-sample")
        expected = (16, bytes.fromhex("05000000000000000200000000000000"))
        self.assertEqual(primary.expected_output(case["input_values"]), expected)
        self.assertEqual(independent.verify(case["input_values"]), expected)
        self.assertEqual(case["expected_result"], expected[0])
        self.assertEqual(bytes.fromhex(case["expected_output_hex"]), expected[1])


if __name__ == "__main__":
    unittest.main()
