#!/usr/bin/env python3
"""Record a built binary64-base, signed-int32-exponent benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess

from build_abi import ROOT, sha256_file


def encode_case(case: dict) -> tuple[float, int, float]:
    base, exponent, expected = case.get("base"), case.get("exponent"), case.get("expected_result")
    if (type(base) not in (int, float) or not math.isfinite(float(base))
            or type(exponent) is not int or not -(2**31) <= exponent <= 2**31 - 1
            or type(expected) not in (int, float) or not math.isfinite(float(expected))):
        raise ValueError("float64_i32 cases require a finite base, signed int32 exponent, and finite result")
    base, expected = float(base), float(expected)
    if not -100.0 < base < 100.0 or (base == 0.0 and exponent <= 0):
        raise ValueError("base or exponent violates the powx_n input contract")
    if not -10000.0 <= expected <= 10000.0:
        raise ValueError("expected result is outside the powx_n output contract")
    return base, exponent, expected


def result_bits(value: float) -> str:
    return f"{struct.unpack('>Q', struct.pack('>d', value))[0]:016x}"


def matches(observed: float, expected: float, tolerance: float) -> bool:
    if not math.isfinite(observed):
        return False
    if expected == 0.0:
        return observed == 0.0 and math.copysign(1.0, observed) == math.copysign(1.0, expected)
    return abs(observed - expected) <= tolerance * abs(expected)


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
    if manifest.get("family") != "float64_i32" or manifest.get("algorithm") != "powx_n":
        parser.error("build manifest must declare the powx_n float64_i32 ABI")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_i32_runner"]
    executable = Path(binary["path"])
    runner_source = ROOT / "benchmarks/harness/float64_i32_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner_source) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    workload_path = args.workload or ROOT / "benchmarks/p/powx_n/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "powx_n"
            or workload.get("measurement", {}).get("comparison_model") != "float64_i32_call"):
        parser.error("workload does not match the powx_n float64_i32 algorithm")
    timing = workload["measurement"]
    tolerance = float(timing["relative_tolerance"])
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
        base, exponent, expected = encode_case(case)
        command = [str(executable), format(base, ".17g"), str(exponent),
                   format(expected, ".17g"), format(tolerance, ".17g"),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64_i32 runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        observed_bits = raw["observed_bits"]
        if (not matches(observed, expected, tolerance)
                or observed_bits != result_bits(observed)
                or len(raw["samples_ns"]) != samples):
            raise ValueError(f"float64_i32 runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": "powx_n",
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": 2, "input_values": [base, exponent],
                                     "case": case["id"], "target": None,
                                     "expected_result": expected, "expected_bits": result_bits(expected)},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_i32_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "observed_bits": observed_bits,
                                        "result_checksum": raw["result_checksum"],
                                        "result_relative_tolerance": tolerance}})
    output = args.output or ROOT / "results/p/powx_n" / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
