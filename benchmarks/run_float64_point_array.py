#!/usr/bin/env python3
"""Record a binary64 benchmark over caller-supplied 2D points."""

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

MAX_POINT_COUNT = 65536


def encode_case(case: dict) -> tuple[list[float], float | str]:
    points, expected = case.get("input_points"), case.get("expected_result")
    if not isinstance(points, list) or len(points) > MAX_POINT_COUNT:
        raise ValueError("point-array cases require up to 65536 coordinate pairs")
    flat: list[float] = []
    for point in points:
        if (not isinstance(point, list) or len(point) != 2
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       or not 0.0 <= float(value) <= 1.0 for value in point)):
            raise ValueError("each point must contain two finite binary64 coordinates in [0, 1]")
        flat.extend(map(float, point))
    if expected == "NaN":
        if points:
            raise ValueError("NaN is the expected result only for an empty point list")
        return flat, expected
    if type(expected) not in (int, float) or not math.isfinite(float(expected)):
        raise ValueError("expected result must be finite or the string 'NaN'")
    return flat, float(expected)


def matches(observed: object, expected: float | str, relative_tolerance: float) -> bool:
    if expected == "NaN":
        return observed == "NaN"
    try:
        value = float(observed)
        target = float(expected)
    except (TypeError, ValueError):
        return False
    return math.isfinite(value) and abs(value - target) <= relative_tolerance * abs(target)


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
    if manifest.get("family") != "float64_point_array" or manifest.get("algorithm") != "pi_approximation":
        parser.error("build manifest must declare the pi_approximation float64_point_array ABI")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_point_array_runner"]
    executable = Path(binary["path"])
    runner_source = ROOT / "benchmarks/harness/float64_point_array_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner_source) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = "p"
    workload_path = args.workload or ROOT / "benchmarks" / letter / "pi_approximation" / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "pi_approximation"
            or workload.get("measurement", {}).get("comparison_model") != "float64_point_array_call"):
        parser.error("workload does not match the pi_approximation point-array algorithm")
    timing = workload["measurement"]
    tolerance = float(timing["relative_tolerance"])
    if not math.isfinite(tolerance) or tolerance <= 0.0:
        parser.error("relative tolerance must be positive and finite")
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed runner limits")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases or len({case.get("id") for case in cases}) != len(cases):
        parser.error("workload requires unique case IDs")
    encoded_cases = [(case, *encode_case(case)) for case in cases]

    checker = manifest["binaries"].get("float64_point_array_check")
    if checker is not None:
        checker_executable = Path(checker["path"])
        checker_source = ROOT / "benchmarks/harness/float64_point_array_check.c"
        if (sha256_file(checker_executable) != checker["sha256"]
                or sha256_file(checker_source) != checker["harness_sha256"]):
            parser.error("checker or checker binary changed since the recorded build; rebuild first")
        check_input = [str(len(encoded_cases))]
        for case, flat, expected in encoded_cases:
            expected_arg = expected if expected == "NaN" else format(expected, ".17g")
            check_input.append(f"{len(flat) // 2} {expected_arg} {format(tolerance, '.17g')}")
            check_input.extend(format(value, ".17g") for value in flat)
        checked = subprocess.run([str(checker_executable)], input="\n".join(check_input) + "\n",
                                 capture_output=True, text=True, check=False)
        if checked.returncode:
            raise SystemExit(f"point-array checker failed: {checked.stderr}")

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
    for case, flat, expected in encoded_cases:
        point_count = len(flat) // 2
        expected_arg = expected if expected == "NaN" else format(expected, ".17g")
        command = [str(executable), "--stdin", str(point_count), expected_arg,
                   format(tolerance, ".17g"), str(samples), str(warmups), str(repetitions)]
        streamed_points = " ".join(format(value, ".17g") for value in flat) + "\n"
        completed = subprocess.run(command, input=streamed_points, capture_output=True,
                                   text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"point-array runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = raw["observed_result"]
        if (not matches(observed, expected, tolerance)
                or len(raw["samples_ns"]) != samples):
            raise ValueError(f"point-array runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id,
                        "algorithm": "pi_approximation", "implementation": implementation,
                        "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": point_count, "input_values": flat,
                                     "case": case["id"], "target": None,
                                     "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_point_array_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"],
                                        "observed_result": observed,
                                        "result_checksum": raw["result_checksum"],
                                        "result_relative_tolerance": tolerance}})
    output = args.output or ROOT / "results/p/pi_approximation" / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"),
                                         allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
