"""Check exact boundaries and integration with both scalar validation paths."""

import unittest

from newton_square_root_oracle import MAX_INPUT, boundary_inputs, expected_result
from run_scalar import validate_expected_result
from verify_scalar import corpus


class NewtonSquareRootOracleTests(unittest.TestCase):
    def test_domain_and_exact_square_boundaries(self):
        for root in (0, 1, 2, 46340, 1 << 20, (1 << 31) - 1):
            square = root * root
            self.assertEqual(expected_result(square), root)
            if root:
                self.assertEqual(expected_result(square - 1), root - 1)
            self.assertEqual(expected_result(square + 2 * root), root)
        for value in (-(1 << 63), -1, MAX_INPUT + 1, (1 << 63) - 1):
            self.assertEqual(expected_result(value), -1)
        self.assertEqual(expected_result(MAX_INPUT), (1 << 31) - 1)

    def test_extended_corpus_obeys_integer_interval(self):
        for value in boundary_inputs():
            root = expected_result(value)
            if 0 <= value <= MAX_INPUT:
                self.assertLessEqual(root * root, value)
                self.assertGreater((root + 1) * (root + 1), value)
            else:
                self.assertEqual(root, -1)

    def test_verifier_and_runner_reject_wrong_answers(self):
        data, _ = corpus("newton_square_root")
        self.assertGreater(len(data.splitlines()), 20_000)
        validate_expected_result("newton_square_root", 16, 4)
        with self.assertRaises(ValueError):
            validate_expected_result("newton_square_root", 16, 5)


if __name__ == "__main__":
    unittest.main()
