"""Check exported build provenance without invoking a compiler or benchmark."""

import json
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import run_scalar


class ScalarProvenanceTests(unittest.TestCase):
    def exercise(self, digest, compiled_symbol=None, workload_symbol=None, rejects=False):
        with tempfile.TemporaryDirectory() as temporary:
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
            if workload_symbol is not None:
                spec = json.loads(workload.read_text())
                spec["function_symbol"] = workload_symbol
                workload.write_text(json.dumps(spec))
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
            if compiled_symbol is not None:
                manifest["function_symbol"] = compiled_symbol
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
                 patch("builtins.print"), patch("sys.stderr", new_callable=io.StringIO):
                if rejects:
                    with self.assertRaises(SystemExit) as error:
                        run_scalar.main()
                    self.assertEqual(error.exception.code, 2)
                    run.assert_not_called()
                    self.assertFalse(output.exists())
                    return
                self.assertEqual(run_scalar.main(), 0)
            run.assert_called_once()
            record = json.loads(output.read_text())
            self.assertEqual(record["implementation"]["compiler_sha256"], digest)
            self.assertEqual(record["implementation"]["compiler_version"], "same version text")
            self.assertEqual(record["implementation"]["function_symbol"], workload_symbol or "digital_root")
            self.assertEqual(record["implementation"]["build_manifest_sha256"], run_scalar.sha256_file(manifest_path))

    def test_export_retains_build_time_compiler_identity(self):
        for digest in ("a" * 64, None):
            with self.subTest(digest=digest):
                self.exercise(digest)

    def test_custom_symbol_is_preserved(self):
        self.exercise("a" * 64, "custom_entry", "custom_entry")

    def test_manifest_symbol_mismatch_is_rejected_before_execution(self):
        for compiled, workload in (("custom_entry", None), (None, "custom_entry"),
                                   ("custom_entry", "other_entry"), ("custom_entry", "not-valid!")):
            with self.subTest(compiled=compiled, workload=workload):
                self.exercise("a" * 64, compiled, workload, rejects=True)


if __name__ == "__main__":
    unittest.main()
