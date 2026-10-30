"""Check exported build provenance without invoking a compiler or benchmark."""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import run_scalar


class ScalarProvenanceTests(unittest.TestCase):
    def test_export_retains_build_time_compiler_identity(self):
        for digest in ("a" * 64, None):
            with self.subTest(digest=digest), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary).resolve()
                source = root / "digital_root.c"
                source.write_text("implementation snapshot")
                executable = root / "runner"
                executable.write_text("binary snapshot")
                harness = root / "benchmarks/harness/scalar_runner.c"
                harness.parent.mkdir(parents=True)
                harness.write_text("harness snapshot")
                workload = root / "workload.json"
                workload.write_text(json.dumps({
                    "algorithm": "digital_root", "id": "digital-root-v1",
                    "cases": [{"id": "zero", "input_value": 0, "expected_result": 0}],
                    "measurement": {},
                }))
                manifest = {
                    "family": "scalar", "algorithm": "digital_root", "language": "c",
                    "source_path": source.name,
                    "source_sha256": run_scalar.sha256_file(source),
                    "compiler": str(root / "compiler-no-longer-installed"),
                    "compiler_version": "same version text", "build_flags": "-O3",
                    "commands": [["compiler", "-O3"]],
                    "binaries": {"scalar_runner": {
                        "path": str(executable),
                        "sha256": run_scalar.sha256_file(executable),
                        "harness_sha256": run_scalar.sha256_file(harness),
                    }},
                }
                if digest is not None:
                    manifest["compiler_sha256"] = digest
                manifest_path = root / "build.json"
                manifest_path.write_text(json.dumps(manifest))
                output = root / "results.jsonl"
                argv = ["run_scalar.py", "--build-manifest", str(manifest_path),
                        "--workload", str(workload), "--output", str(output),
                        "--samples", "1", "--warmups", "0", "--repetitions", "1"]
                response = subprocess.CompletedProcess([], 0, json.dumps({
                    "observed_result": 0, "samples_ns": [10],
                    "timer_resolution_ns": 1, "result_checksum": 0,
                }), "")
                with patch.object(run_scalar, "ROOT", root), \
                     patch.object(run_scalar.platform, "processor", return_value="test CPU"), \
                     patch("sys.argv", argv), \
                     patch.object(run_scalar.subprocess, "run", return_value=response) as run, \
                     patch("builtins.print"):
                    self.assertEqual(run_scalar.main(), 0)
                run.assert_called_once()
                record = json.loads(output.read_text())
                self.assertEqual(record["implementation"]["compiler_sha256"], digest)
                self.assertEqual(record["implementation"]["compiler_version"], "same version text")


if __name__ == "__main__":
    unittest.main()
