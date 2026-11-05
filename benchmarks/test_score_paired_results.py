import copy
import math
import unittest
from score_paired_results import score


def report(round_id=0, values=None):
    values = values or {"short": {"before": [1, 9], "after": [4, 4]},
                        "long": {"before": [100, 100], "after": [100, 100]}}
    return {"rows": [dict(process_round=round_id, case=case, variant=variant,
                          batch=batch, ns=value, repetitions=100)
                     for case, variants in values.items()
                     for variant, times in variants.items()
                     for batch, value in enumerate(times)]}


class PairedScoreTest(unittest.TestCase):
    def test_arithmetic_means_before_case_geomean(self):
        result = score([report()], "before", "after", ["short", "long"])
        self.assertAlmostEqual(result["baseline_geomean_ns"], math.sqrt(500))
        self.assertAlmostEqual(result["candidate_geomean_ns"], 20)
        self.assertGreater(result["time_reduction_percent"], 10)
        self.assertEqual(result["cases"][0]["baseline_mean_ns"], 5)

    def test_equal_process_weights_and_regressions(self):
        second = report(1, {"short": {"before": [5], "after": [8]},
                            "long": {"before": [100], "after": [100]}})
        result = score([report(), second], "before", "after", ["short", "long"])
        self.assertEqual(result["cases"][0]["candidate_mean_ns"], 6)
        self.assertEqual(result["regressions"], ["short"])

    def test_identical_samples_have_no_gain(self):
        result = score([report(values={"x": {"before": [2, 2], "after": [2, 2]}})],
                       "before", "after", ["x"])
        self.assertEqual(result["speedup_percent"], 0)

    def test_missing_pair_and_missing_case_are_rejected(self):
        data = report()
        data["rows"].pop()
        with self.assertRaisesRegex(ValueError, "unpaired"):
            score([data], "before", "after", ["short", "long"])
        with self.assertRaisesRegex(ValueError, "missing"):
            score([report()], "before", "after", ["short", "absent"])

    def test_duplicate_round_and_duplicate_batch_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "unique process"):
            score([report(), report()], "before", "after", ["short", "long"])
        data = report()
        data["rows"].append(copy.deepcopy(data["rows"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate batch"):
            score([data], "before", "after", ["short", "long"])

    def test_invalid_times_and_repetition_counts_are_rejected(self):
        for value in [0, -1, float("nan"), float("inf")]:
            data = report()
            data["rows"][0]["ns"] = value
            with self.assertRaises(ValueError):
                score([data], "before", "after", ["short", "long"])
        for value in [0, -1, True, 1.5, 101]:
            data = report()
            data["rows"][0]["repetitions"] = value
            with self.assertRaises(ValueError):
                score([data], "before", "after", ["short", "long"])


if __name__ == "__main__":
    unittest.main()
