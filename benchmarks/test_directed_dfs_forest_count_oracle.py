"""Keep the timed workload consistent with ordered directed DFS semantics."""
import json
from pathlib import Path
import unittest

from directed_dfs_forest_count_oracle import expected_result


class DirectedDFSWorkloadTest(unittest.TestCase):
    def test_workload_expected_results(self):
        path = Path(__file__).parent / "d/directed_dfs_forest_count/workload.json"
        for case in json.loads(path.read_text())["cases"]:
            with self.subTest(case=case["id"]):
                self.assertEqual(len(case["input_values"]), case["input_length"])
                self.assertEqual(expected_result(case["input_values"]), case["expected_result"])

    def test_root_order(self):
        # Root 0 visits 1; the later root 2 revisits 0, adding just one root.
        self.assertEqual(expected_result([2, 0, 1, 2, 0]), 2)
        self.assertEqual(expected_result([2, 2, 0, 0, 1]), 1)


if __name__ == "__main__":
    unittest.main()
