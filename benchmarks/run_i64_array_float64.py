#!/usr/bin/env python3
"""Record a built binary64-result benchmark over a signed 64-bit input array."""

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
import sys

from build_abi import ROOT, sha256_file

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_INPUT_LENGTH = 4096


def encode_case(case: dict, algorithm: str) -> tuple[list[int], float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(expected) not in (int, float) or not math.isfinite(expected)):
        raise ValueError("array-float64 cases require up to 4096 signed 64-bit values and a finite result")
    if algorithm == "electrical_impedance":
        valid = (len(values) == 3 and all(0 <= value <= 1000 for value in values)
                 and sum(value == 0 for value in values) == 1)
        if valid:
            resistance, reactance, impedance = values
            if resistance == 0:
                valid = impedance >= reactance
                expected_from_source = (math.sqrt(impedance * impedance - reactance * reactance)
                                        if valid else -1e300)
            elif reactance == 0:
                valid = impedance >= resistance
                expected_from_source = (math.sqrt(impedance * impedance - resistance * resistance)
                                        if valid else -1e300)
            else:
                expected_from_source = math.sqrt(resistance * resistance + reactance * reactance)
        else:
            expected_from_source = -1e300
        if expected == -1e300:
            if valid:
                raise ValueError("valid electrical_impedance inputs cannot use the invalid sentinel")
        elif (not valid or not math.isclose(expected, expected_from_source,
                                            rel_tol=1e-12, abs_tol=1e-12)):
            raise ValueError("electrical_impedance expected_result must match its selected impedance formula")
    return values, float(expected)


def resolve_tolerances(workload: dict) -> tuple[float, float]:
    """Resolve finite nonnegative tolerances from output/measurement metadata.

    Results match when abs(observed - expected) <= absolute + relative * abs(expected).
    Missing tolerances default to zero, preserving exact comparison.
    """
    resolved = []
    for key in ("absolute_tolerance", "relative_tolerance"):
        declared = []
        for section in ("output", "measurement"):
            metadata = workload.get(section, {})
            if not isinstance(metadata, dict):
                raise ValueError(f"{section} metadata must be an object")
            if key not in metadata:
                continue
            value = metadata[key]
            if (isinstance(value, bool) or not isinstance(value, (int, float))
                    or value < 0):
                raise ValueError(f"{section}.{key} must be a finite nonnegative number")
            try:
                numeric_value = float(value)
            except OverflowError as error:
                raise ValueError(f"{section}.{key} must be a finite nonnegative number") from error
            if not math.isfinite(numeric_value):
                raise ValueError(f"{section}.{key} must be a finite nonnegative number")
            declared.append(numeric_value)
        if len(declared) == 2 and declared[0] != declared[1]:
            raise ValueError(f"output.{key} and measurement.{key} must agree")
        resolved.append(declared[0] if declared else 0.0)
    return resolved[0], resolved[1]


def result_matches(observed: float, expected: float, absolute_tolerance: float,
                   relative_tolerance: float) -> bool:
    return (math.isfinite(observed)
            and abs(observed - expected)
            <= absolute_tolerance + relative_tolerance * abs(expected))


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
    if manifest.get("family") != "i64_array_float64":
        parser.error("build manifest must declare the i64_array_float64 ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_array_float64_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_array_float64_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_float64_call"):
        parser.error("workload does not match the built i64-array float64 algorithm")
    timing = workload["measurement"]
    absolute_tolerance, relative_tolerance = resolve_tolerances(workload)
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed the runner limits")
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
        values, expected = encode_case(case, algorithm)
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        if len(values) > 1024:
            command = [str(executable), "--stdin", str(len(values)), repr(expected),
                       repr(absolute_tolerance), repr(relative_tolerance),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = " ".join(map(str, values)) + "\n"
        else:
            command = [str(executable), str(len(values)), *map(str, values), repr(expected),
                       repr(absolute_tolerance), repr(relative_tolerance),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = None
        completed = subprocess.run(command, input=streamed_values, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"array-float64 runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        if (not result_matches(observed, expected, absolute_tolerance, relative_tolerance)
                or len(raw["samples_ns"]) != samples):
            raise ValueError(f"array-float64 runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_array_float64_call",
                                        "absolute_tolerance": absolute_tolerance,
                                        "relative_tolerance": relative_tolerance,
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "result_checksum": raw["result_checksum"]}})

    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
