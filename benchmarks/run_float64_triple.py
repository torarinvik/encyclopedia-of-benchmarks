#!/usr/bin/env python3
"""Record a built three-input binary64 benchmark."""

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

ALGORITHM = "lerp"


def encode_case(case: dict, tolerance: float) -> tuple[float, float, float, float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values)
            or type(expected) not in (int, float) or not math.isfinite(float(expected))):
        raise ValueError("float64 triple cases require three finite values and one finite expected result")
    start, end, t = map(float, values)
    if abs(start) > 1e12 or abs(end) > 1e12 or not 0.0 <= t <= 1.0:
        raise ValueError("lerp inputs must use bounded endpoints and t in [0, 1]")
    if not math.isfinite(tolerance) or tolerance <= 0.0:
        raise ValueError("relative tolerance must be positive and finite")
    return start, end, t, float(expected)


def matches(observed: float, expected: float, tolerance: float, start: float, end: float) -> bool:
    scale = max(1.0, abs(start), abs(end))
    return math.isfinite(observed) and abs(observed - expected) <= tolerance * scale


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
    if manifest.get("family") != "float64_triple" or manifest.get("algorithm") != ALGORITHM:
        parser.error("build manifest must declare the lerp float64_triple ABI")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_triple_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/float64_triple_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    workload_path = args.workload or ROOT / "benchmarks/l/lerp/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("measurement", {}).get("comparison_model") != "float64_triple_call"):
        parser.error("workload does not match the built float64 triple algorithm")
    timing = workload["measurement"]
    tolerance = float(timing["input_scaled_tolerance"])
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
        start, end, t, expected = encode_case(case, tolerance)
        command = [str(executable), *(format(value, ".17g") for value in (start, end, t, expected, tolerance)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64 triple runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        if not matches(observed, expected, tolerance, start, end) or len(raw["samples_ns"]) != samples:
            raise ValueError(f"float64 triple runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": ALGORITHM,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [start, end, t],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_triple_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "result_checksum": raw["result_checksum"],
                                        "result_input_scaled_tolerance": tolerance}})
    output = args.output or ROOT / "results/l/lerp" / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
