import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

from verified_benchmark_process import run_verified


def receipt(path):
    return {"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


class VerifiedProcessTest(unittest.TestCase):
    def test_real_process_records_input_output_and_checked_hashes(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "build artifact"
            artifact.write_text("original")
            result = run_verified([sys.executable, "-c", "print(input().upper())"],
                                  "hello\n", [receipt(artifact), receipt(Path(sys.executable))], timeout=2)
            self.assertEqual(result["stdout"], "HELLO\n")
            self.assertEqual(result["artifacts_before"], result["artifacts_after"])

    def test_stale_receipt_prevents_execution(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact, marker = Path(directory) / "artifact", Path(directory) / "ran"
            artifact.write_text("old")
            original = receipt(artifact)
            artifact.write_text("new")
            with self.assertRaisesRegex(ValueError, "differs"):
                run_verified([sys.executable, "-c", "import pathlib,sys;pathlib.Path(sys.argv[1]).touch()",
                              str(marker)], "", [original, receipt(Path(sys.executable))], timeout=2)
            self.assertFalse(marker.exists())

    def test_mutation_during_execution_invalidates_measurement(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "artifact"
            artifact.write_text("old")
            with self.assertRaisesRegex(ValueError, "differs"):
                run_verified([sys.executable, "-c", "import pathlib,sys;pathlib.Path(sys.argv[1]).write_text('new')",
                              str(artifact)], "", [receipt(artifact), receipt(Path(sys.executable))], timeout=2)

    def test_runner_without_receipt_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "artifact"
            artifact.write_text("data")
            with self.assertRaisesRegex(ValueError, "runner executable"):
                run_verified([sys.executable, "-c", "pass"], "", [receipt(artifact)])

    def test_timeout_also_stops_pipe_inheriting_child(self):
        start = time.monotonic()
        with self.assertRaises(subprocess.TimeoutExpired):
            run_verified([sys.executable, "-c",
                          "import subprocess,sys,time;subprocess.Popen([sys.executable,'-c','import time;time.sleep(10)']);time.sleep(10)"],
                         "", [receipt(Path(sys.executable))], timeout=0.15)
        self.assertLess(time.monotonic() - start, 2)

    def test_timeout_reaps_process_and_rejects_long_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "artifact"
            artifact.write_text("data")
            with self.assertRaises(subprocess.TimeoutExpired):
                run_verified([sys.executable, "-c", "import time;time.sleep(10)"],
                             "", [receipt(artifact), receipt(Path(sys.executable))], timeout=0.05)
            with self.assertRaises(ValueError):
                run_verified([sys.executable], "", [receipt(artifact), receipt(Path(sys.executable))], timeout=30)


if __name__ == "__main__":
    unittest.main()
