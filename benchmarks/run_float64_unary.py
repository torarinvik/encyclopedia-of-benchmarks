#!/usr/bin/env python3
"""Record a built one-input binary64 benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
from pathlib import Path
import platform
import shlex
import subprocess

from build_abi import ROOT, sha256_file


def encode_case(case: dict) -> tuple[float, float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 1
            or type(values[0]) not in (int, float) or not math.isfinite(float(values[0]))
            or type(expected) not in (int, float) or not math.isfinite(float(expected))):
        raise ValueError("float64 unary cases require one finite input and one finite expected result")
    return float(values[0]), float(expected)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", required=True, type=Path)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()
    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("family") != "float64_unary":
        parser.error("build manifest must declare the float64_unary ABI")
    algorithm = manifest["algorithm"]
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_unary_runner"]
    executable = Path(binary["path"])
    runner_source = ROOT / "benchmarks/harness/float64_unary_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner_source) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "float64_unary_call"):
        parser.error("workload does not match the built float64 unary algorithm")
    timing = workload["measurement"]
    tolerance = float(timing["relative_tolerance"])
    absolute_tolerance = float(timing.get("absolute_tolerance", 0.0))
    if (not math.isfinite(tolerance) or tolerance <= 0.0
            or not math.isfinite(absolute_tolerance) or absolute_tolerance < 0.0):
        parser.error("workload float64 tolerances must be finite, with positive relative and nonnegative absolute values")
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed runner limits")
    if len({case["id"] for case in workload["cases"]}) != len(workload["cases"]):
        parser.error("workload case IDs must be unique")
    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": binary["harness_sha256"],
                           "binary_sha256": binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case in workload["cases"]:
        value, expected = encode_case(case)
        command = [str(executable), *(format(number, ".17g") for number in
                   (value, expected, tolerance, absolute_tolerance)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64 unary runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        if (not math.isfinite(observed)
                or abs(observed - expected) > absolute_tolerance + tolerance * abs(expected)
                or len(raw["samples_ns"]) != samples):
            raise ValueError(f"float64 unary runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [value],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_unary_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "result_checksum": raw["result_checksum"],
                                        "result_relative_tolerance": tolerance,
                                        "result_absolute_tolerance": absolute_tolerance}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
