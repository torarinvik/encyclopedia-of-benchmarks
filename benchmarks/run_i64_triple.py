#!/usr/bin/env python3
"""Record a built three-input signed 64-bit benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
from functools import lru_cache
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess

from build_abi import ROOT, sha256_file

SUPPORTED_ALGORITHMS = {"problem188"}


@lru_cache(maxsize=512)
def problem188_modexpt(base: int, exponent: int, modulus: int) -> int:
    """Mirror the pinned recursive modular exponent helper, including exp==1."""
    if exponent == 1:
        return base
    if exponent % 2 == 0:
        half = problem188_modexpt(base, exponent // 2, modulus) % modulus
        return half * half % modulus
    return base * (problem188_modexpt(base, exponent - 1, modulus) % modulus) % modulus


@lru_cache(maxsize=256)
def problem188_source_result(base: int, height: int, digits: int) -> int:
    if (not 1 <= base <= 1_000_000_000 or base % 10 == 0
            or not 1 <= height <= 10_000 or not 1 <= digits <= 8):
        return -1
    result = base
    modulus = 10**digits
    for _ in range(1, height):
        result = problem188_modexpt(base, result, modulus)
    return result


def encode_case(case: dict, algorithm: str) -> tuple[int, int, int, int]:
    values = case.get("input_values")
    expected = case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1 for value in values)
            or type(expected) is not int or not -(2**63) <= expected <= 2**63 - 1):
        raise ValueError("i64 triple cases require three signed 64-bit inputs and one signed 64-bit result")
    first, second, third = values
    if algorithm == "problem188":
        source_result = problem188_source_result(first, second, third)
        if expected != source_result:
            raise ValueError("problem188 expected result must match the pinned modular tetration recurrence")
    else:
        raise ValueError(f"unsupported i64_triple algorithm: {algorithm}")
    return first, second, third, expected


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
    algorithm = manifest.get("algorithm")
    if manifest.get("family") != "i64_triple" or algorithm not in SUPPORTED_ALGORITHMS:
        parser.error("build manifest must declare a supported i64_triple ABI")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_triple_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_triple_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    workload_path = args.workload or ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_triple_call"):
        parser.error("workload does not match the built i64 triple algorithm")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1_000_000_000:
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
        first, second, third, expected = encode_case(case, algorithm)
        command = [str(executable), str(first), str(second), str(third), str(expected),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"i64 triple runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = int(raw["observed_result"])
        if observed != expected or len(raw["samples_ns"]) != samples:
            raise ValueError(f"i64 triple runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [first, second, third],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_triple_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "result_checksum": raw["result_checksum"]}})
    output = args.output or ROOT / "results" / algorithm[0] / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
