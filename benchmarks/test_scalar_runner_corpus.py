"""The timed scalar executable must be checked against the complete corpus."""

from pathlib import Path
import json
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent


class ScalarRunnerCorpusTest(unittest.TestCase):
    def test_corpus_and_timing_share_the_linked_implementation(self):
        with tempfile.TemporaryDirectory() as tmp:
            executable = Path(tmp) / "runner"
            subprocess.run(["cc", "-O3", "-DBENCHMARK_FUNCTION=digital_root",
                            str(ROOT / "benchmarks/harness/scalar_runner.c"),
                            str(ROOT / "c/d/digital_root.c"), "-o", str(executable)],
                           check=True, capture_output=True, timeout=20)
            def check(data):
                return subprocess.run([str(executable), "--check-corpus"], input=data,
                                      text=True, capture_output=True, timeout=5)
            good = check("-1 -1\n0 0\n284 5\n")
            self.assertEqual(good.returncode, 0, good.stderr)
            self.assertEqual(json.loads(good.stdout)["cases_checked"], 3)
            self.assertEqual(check("284 4\n").returncode, 3)
            for invalid in ("", "0 0\n1", "0 0\ngarbage"):
                self.assertEqual(check(invalid).returncode, 2)
            timed = subprocess.run([str(executable), "284", "5", "1", "0", "1"],
                                   capture_output=True, text=True, timeout=5, check=True)
            self.assertEqual(json.loads(timed.stdout)["observed_result"], 5)


if __name__ == "__main__":
    unittest.main()
