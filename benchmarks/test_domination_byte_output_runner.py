"""Exercise the domination workload through the shared byte-output recorder."""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DominationByteOutputRunnerTests(unittest.TestCase):
    def test_record_checked_workload(self):
        compiler = shutil.which("clang")
        if compiler is None:
            self.skipTest("clang is required for the C benchmark")
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "results.jsonl"
            subprocess.run(
                [sys.executable, str(ROOT / "benchmarks/build_abi.py"),
                 "--family", "i64_array_bytes_output", "--algorithm",
                 "domination_local_reduction", "--language", "c", "--compiler",
                 compiler, "--cc", compiler, "--output-dir", directory],
                cwd=ROOT, check=True, capture_output=True, text=True, timeout=30,
            )
            subprocess.run(
                [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
                 "--build-manifest", str(Path(directory) / "build.json"),
                 "--output", str(output), "--samples", "1", "--warmups", "0",
                 "--repetitions", "1"],
                cwd=ROOT, check=True, capture_output=True, text=True, timeout=30,
            )
            records = [json.loads(line) for line in output.read_text().splitlines()]
            self.assertEqual(len(records), 6)
            self.assertEqual({record["workload"]["case"] for record in records}, {
                "exit-guard-prisoner-reduction", "all-neighbors-prisoners",
                "not-applicable-empty-prisoner-set", "invalid-duplicate-edge",
                "short-output-capacity", "null-output",
            })
            workload = json.loads((ROOT / "benchmarks/d/domination_local_reduction/workload.json").read_text())
            workload["comparison_model"] = "incorrect"
            invalid = Path(directory) / "invalid-workload.json"
            invalid.write_text(json.dumps(workload))
            result = subprocess.run(
                [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
                 "--build-manifest", str(Path(directory) / "build.json"),
                 "--workload", str(invalid), "--output", str(output)],
                cwd=ROOT, capture_output=True, text=True, timeout=30,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("metadata differs", result.stderr)
            self.assertEqual(len(output.read_text().splitlines()), 6)


if __name__ == "__main__":
    unittest.main()
