"""Exercise target receipts against real compiler drivers without dry-run writes."""
from __future__ import annotations

import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import unittest

from build_abi import build, probe_compile_target, sha256_file
from verify_distance_formula import WORKLOAD, batch, verify


class TargetProbeTest(unittest.TestCase):
    def setUp(self):
        self.clang = shutil.which("clang")
        if not self.clang:
            self.skipTest("Clang is required for the driver integration test")
        self.native = "-mcpu=native" if platform.machine() in {"arm64", "aarch64"} else "-march=native"

    def test_dry_run_resolves_native_without_writing_output(self):
        with tempfile.TemporaryDirectory(prefix="target probe ") as tmp:
            source, output = Path(tmp) / "input file.c", Path(tmp) / "output file.o"
            source.write_text("int identity(int x) { return x; }\n")
            before = sha256_file(source)
            result = probe_compile_target([self.clang, self.native, "-c", str(source), "-o", str(output)])
            self.assertEqual(result["status"], "resolved", result)
            self.assertTrue(result["targets"])
            self.assertTrue(all(target["cpu"] and target["cpu"] != "native" for target in result["targets"]))
            self.assertFalse(output.exists())
            self.assertEqual(sha256_file(source), before)

    def test_gnu_driver_native_resolution(self):
        gcc = next((shutil.which(name) for name in ("gcc-16", "gcc-15", "gcc")
                    if shutil.which(name)), None)
        if not gcc:
            self.skipTest("GNU GCC is unavailable")
        version = subprocess.run([gcc, "--version"], capture_output=True, text=True, timeout=2)
        if "clang" in version.stdout.lower():
            self.skipTest("gcc is a Clang alias")
        with tempfile.TemporaryDirectory(prefix="gcc target probe ") as tmp:
            source, output = Path(tmp) / "input.c", Path(tmp) / "output.o"
            source.write_text("int identity(int x) { return x; }\n")
            result = probe_compile_target([gcc, self.native, "-c", str(source), "-o", str(output)])
            self.assertEqual(result["status"], "resolved", result)
            self.assertFalse(output.exists())

    def test_failed_probe_is_reported_without_writing_output(self):
        result = probe_compile_target([self.clang, "--no-such-target-probe-option"])
        self.assertEqual(result["status"], "unavailable")
        self.assertNotEqual(result["returncode"], 0)
        self.assertEqual(result["targets"], [])

    def test_elisa_explicit_cpu_build_passes_oracle(self):
        compiler = Path.home() / ".elisac/elisac-stage0"
        if not compiler.is_file():
            self.skipTest("installed Stage0 is required")
        with tempfile.TemporaryDirectory(prefix="elisa target build ") as tmp:
            directory = Path(tmp)
            manifest = build("distance_formula", "elisa", directory, compiler=str(compiler),
                             cc=self.clang, family="i64_array_float64", with_checker=True,
                             implementation_flags=("-mcpu=generic",))
            self.assertIn("-mcpu=generic", manifest["commands"][0])
            data, count = batch(json.loads(WORKLOAD.read_text()))
            self.assertEqual(verify(directory / "build.json", data, count)["cases_checked"], count)

    def test_stage1_allocating_port_links_its_runtime(self):
        default = Path(__file__).resolve().parents[2] / "Elisa-compiler/bin/elisac-stage1"
        compiler = Path(os.environ.get("ELISA_STAGE1_BIN", str(default)))
        if not compiler.is_file():
            self.skipTest("Stage1 checkout is required")
        with tempfile.TemporaryDirectory(prefix="stage1 allocating build ") as tmp:
            directory = Path(tmp)
            manifest = build("breadth_first_search_zero_one_shortest_path", "elisa", directory,
                             compiler=str(compiler), cc=self.clang, family="i64_array_scalar")
            self.assertTrue(any("stage1_runtime.o" in flag for flag in manifest["native_link_flags"]))
            runner = directory / "i64_array_scalar_runner"
            # One vertex and no edges: the source is already the destination.
            result = subprocess.run([str(runner), "4", "1", "0", "0", "0", "0", "1", "0", "1"],
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_real_build_records_target_and_still_passes_independent_oracle(self):
        with tempfile.TemporaryDirectory(prefix="target build ") as tmp:
            directory = Path(tmp)
            manifest = build("distance_formula", "c", directory, compiler=self.clang,
                             cc=self.clang, family="i64_array_float64", with_checker=True,
                             implementation_flags=(self.native,))
            self.assertEqual(manifest["target_cpu_probe"]["status"], "resolved")
            artifact = Path(manifest["artifact"])
            self.assertEqual(sha256_file(artifact), manifest["artifact_sha256"])
            data, count = batch(json.loads(WORKLOAD.read_text()))
            self.assertEqual(verify(directory / "build.json", data, count)["cases_checked"], count)


if __name__ == "__main__":
    unittest.main()
