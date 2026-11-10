"""Check independent byte-output verifier startup and known answers."""

import json
from pathlib import Path
import unittest

import sugiyama_barycentric_crossing_reduction_verifier_oracle as sugiyama
import verify_i64_array_bytes_output as verifier

ROOT = Path(__file__).resolve().parents[1]


class ByteOutputVerifierTests(unittest.TestCase):
    def test_aes256_known_answer_and_inverse(self):
        key = tuple(bytes.fromhex(
            "000102030405060708090a0b0c0d0e0f"
            "101112131415161718191a1b1c1d1e1f"))
        plaintext = bytes.fromhex("00112233445566778899aabbccddeeff")
        ciphertext = bytes.fromhex("8ea2b7ca516745bfeafc49904b496089")
        self.assertEqual(verifier._aes_verifier_encrypt(key, tuple(plaintext)), ciphertext)
        self.assertEqual(verifier._aes_verifier_decrypt(key, tuple(ciphertext)), plaintext)

    def test_sugiyama_expected_output_and_error_framing(self):
        workload = json.loads((ROOT / "benchmarks/s/sugiyama_barycentric_crossing_reduction/workload.json").read_text())
        case = workload["cases"][0]
        values = case["input_values"]
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        self.assertEqual(sugiyama.expected_output(values), expected)
        self.assertTrue(sugiyama.verify(values, *expected))
        self.assertEqual(sugiyama.expected_output(values, capacity=0), (-2, b""))
        self.assertTrue(sugiyama.verify(values, -2, b"", capacity=0))
        self.assertEqual(sugiyama.expected_output([], input_is_null=True), (-1, b""))
        self.assertTrue(sugiyama.verify([], -1, b"", input_is_null=True))


if __name__ == "__main__":
    unittest.main()
