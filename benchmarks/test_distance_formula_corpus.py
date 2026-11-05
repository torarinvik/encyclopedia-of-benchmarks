import json
import math
import unittest
from distance_formula_oracle import expected_result
from verify_distance_formula import WORKLOAD, corpus


class DistanceCorpusTest(unittest.TestCase):
    def setUp(self):
        self.workload = json.loads(WORKLOAD.read_text())
        self.cases = corpus(self.workload)

    def test_combined_invalid_coordinates_catch_inverted_fast_path(self):
        # A wrong small-range fast path can reject every singly-invalid test
        # correctly, yet accept four out-of-range coordinates together.
        def wrong(values):
            if len(values) == 4 and all(abs(v) >= 524288 for v in values):
                return math.hypot(values[2] - values[0], values[3] - values[0])
            return expected_result(values)
        for index in range(4):
            values = [0, 0, 0, 0]
            values[index] = 1000001
            self.assertEqual(wrong(values), expected_result(values))
        counterexample = (1000001,) * 4
        self.assertIn(counterexample, self.cases)
        self.assertNotEqual(wrong(counterexample), expected_result(counterexample))
        self.assertIn((-2**63, 2**63 - 1, -1000001, 1000001), self.cases)

    def test_power_of_two_neighbors_and_i64_domain(self):
        for bit in [0, 19, 20, 31, 32, 62]:
            for sign in (-1, 1):
                for offset in (-1, 0, 1):
                    for index in range(4):
                        values = [2, 10, 5, 14]
                        values[index] = sign * (1 << bit) + offset
                        self.assertIn(tuple(values), self.cases)
        self.assertTrue(all(-2**63 <= v < 2**63 for case in self.cases for v in case))

    def test_deterministic_unique_corpus_retains_workload_and_lengths(self):
        self.assertEqual(self.cases, corpus(self.workload))
        self.assertEqual(len(self.cases), len(set(self.cases)))
        self.assertGreater(len(self.cases), 7000)
        for case in self.workload['cases']:
            self.assertIn(tuple(case['input_values']), self.cases)
        self.assertTrue(set(range(8)) <= {len(case) for case in self.cases})


if __name__ == '__main__':
    unittest.main()
