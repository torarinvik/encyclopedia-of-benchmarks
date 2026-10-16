#!/usr/bin/env python3
"""Record float64 slice-to-slice C ABI benchmark workloads."""

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
from vector3_axis_rotation_oracle import expected_result as vector3_axis_rotation_oracle
from vector3_perspective_projection_oracle import expected_result as vector3_perspective_projection_oracle
from vectors_3d_oracle import expected_result as vectors_3d_oracle
from dimensionality_reduction_pca_oracle import expected_result as dimensionality_reduction_pca_oracle
from dimensionality_reduction_lda_oracle import expected_result as dimensionality_reduction_lda_oracle
from dimensionality_reduction_tsne_oracle import expected_result as dimensionality_reduction_tsne_oracle
from fresnel_diffract_oracle import expected_result as fresnel_diffract_oracle
from gauss_optimization_oracle import expected_result as gauss_optimization_oracle

ORACLES = {
    "vector3_axis_rotation": vector3_axis_rotation_oracle,
    "vector3_perspective_projection": vector3_perspective_projection_oracle,
    "vectors_3d": vectors_3d_oracle,
    "dimensionality_reduction_pca": dimensionality_reduction_pca_oracle,
    "dimensionality_reduction_lda": dimensionality_reduction_lda_oracle,
    "dimensionality_reduction_tsne": dimensionality_reduction_tsne_oracle,
    "fresnel_diffract": fresnel_diffract_oracle,
    "gauss_optimization": gauss_optimization_oracle,
}


def _output_value(value: object) -> float:
    if value == "NaN":
        return math.nan
    if type(value) not in (int, float):
        raise ValueError("float64-slice outputs must be finite numbers or the string 'NaN'")
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("float64-slice outputs cannot be infinite")
    return number


def _output_token(value: object) -> float | str:
    number = float(value)
    if math.isnan(number):
        return "NaN"
    if not math.isfinite(number):
        raise ValueError("float64-slice oracle produced an infinite output")
    return number


def _format_output(value: float | str) -> str:
    return "NaN" if value == "NaN" else format(float(value), ".17g")


def tolerances(workload: dict) -> tuple[float, float]:
    measurement = workload.get("measurement", {})
    output = workload.get("output", {})
    absolute = float(measurement.get("absolute_tolerance", output.get("absolute_tolerance", 0.0)))
    relative = float(measurement.get("relative_tolerance", output.get("relative_tolerance", 0.0)))
    if (not math.isfinite(absolute) or absolute < 0.0
            or not math.isfinite(relative) or relative < 0.0):
        raise ValueError("float64-slice tolerances must be finite and nonnegative")
    if ("absolute_tolerance" in output and float(output["absolute_tolerance"]) != absolute
            or "relative_tolerance" in output and float(output["relative_tolerance"]) != relative):
        raise ValueError("measurement and output tolerances must agree")
    return absolute, relative


def encode_case(case: dict, algorithm: str, absolute_tolerance: float,
                relative_tolerance: float) -> tuple[list[float], int, list[float]]:
    oracle = ORACLES.get(algorithm)
    if oracle is None:
        raise ValueError(f"no float64-slice oracle registered for {algorithm}")
    raw_values = case.get("input_values")
    if (not isinstance(raw_values, list) or case.get("input_length") != len(raw_values)
            or not raw_values or len(raw_values) > 64
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in raw_values)):
        raise ValueError("float64-slice inputs must be finite arrays with a matching input_length")
    values = [float(value) for value in raw_values]
    oracle_output = oracle(values)
    expected_result = len(oracle_output) if oracle_output is not None else -1
    expected_output = [] if oracle_output is None else [_output_token(value) for value in oracle_output]
    if case.get("expected_result") != expected_result:
        raise ValueError(f"{case.get('id')}: expected_result disagrees with the independent oracle")
    raw_expected = case.get("expected_output")
    if (not isinstance(raw_expected, list) or len(raw_expected) != len(expected_output)):
        raise ValueError(f"{case.get('id')}: expected_output must match the oracle output shape")
    actual_output = [_output_token(_output_value(value)) for value in raw_expected]
    for actual, expected in zip(actual_output, expected_output):
        if expected == "NaN":
            if actual != "NaN":
                raise ValueError(f"{case.get('id')}: expected_output disagrees with the independent oracle")
            continue
        actual_number = float(actual)
        expected_number = float(expected)
        allowed = absolute_tolerance + relative_tolerance * abs(expected_number)
        if abs(actual_number - expected_number) > allowed:
            raise ValueError(f"{case.get('id')}: expected_output disagrees with the independent oracle")
    return values, expected_result, actual_output


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
    if manifest.get("family") != "float64_slice_io" or algorithm not in ORACLES:
        parser.error("build manifest must declare a registered float64_slice_io algorithm")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    runner_binary = manifest["binaries"]["float64_slice_io_runner"]
    executable = Path(runner_binary["path"])
    runner_source = ROOT / "benchmarks/harness/float64_slice_io_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != runner_binary["sha256"]
            or sha256_file(runner_source) != runner_binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = algorithm[0]
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "float64_slice_io_call"):
        parser.error("workload does not match the float64_slice_io algorithm")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed runner limits")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases or len({case.get("id") for case in cases}) != len(cases):
        parser.error("workload requires unique case IDs")
    workspace = workload.get("workspace", {}).get("elements")
    if type(workspace) is not int or not 1 <= workspace <= 64:
        parser.error("workload workspace.elements must be an integer from 1 through 64")
    encoded_cases = [
        (case, *encode_case(case, algorithm, absolute_tolerance, relative_tolerance))
        for case in cases
    ]
    for case, _values, expected_result, expected_output in encoded_cases:
        if expected_result >= 0 and (expected_result > workspace or expected_result != len(expected_output)):
            parser.error(f"workspace is too small for {case['id']}")

    checker = manifest["binaries"].get("float64_slice_io_check")
    if checker is not None:
        checker_binary = Path(checker["path"])
        checker_source = ROOT / "benchmarks/harness/float64_slice_io_check.c"
        if (sha256_file(checker_binary) != checker["sha256"]
                or sha256_file(checker_source) != checker["harness_sha256"]):
            parser.error("checker or checker binary changed since the recorded build; rebuild first")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": runner_binary["harness_sha256"],
                           "binary_sha256": runner_binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case, values, expected_result, expected_output in encoded_cases:
        header = (f"{len(values)} {expected_result} {len(expected_output)} {workspace} "
                  f"{absolute_tolerance:.17g} {relative_tolerance:.17g}\n")
        payload = (" ".join(format(value, ".17g") for value in values) + " " +
                   " ".join(_format_output(value) for value in expected_output) + "\n")
        completed = subprocess.run(
            [str(executable), "--stdin", str(samples), str(warmups), str(repetitions)],
            input=header + payload, capture_output=True, text=True, check=False,
        )
        if completed.returncode:
            raise SystemExit(f"float64-slice runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed_result = raw.get("observed_result")
        observed_output = raw.get("observed_output")
        if (observed_result != expected_result or not isinstance(observed_output, list)
                or len(observed_output) != len(expected_output)
                or any((expected == "NaN" and value != "NaN") or
                       (expected != "NaN" and
                        (not math.isfinite(_output_value(value)) or
                         abs(_output_value(value) - float(expected)) >
                         absolute_tolerance + relative_tolerance * abs(float(expected))))
                       for value, expected in zip(observed_output, expected_output))
                or len(raw.get("samples_ns", [])) != samples):
            raise ValueError(f"float64-slice runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id,
                        "algorithm": algorithm, "implementation": implementation,
                        "environment": environment,
                        "workload": {"id": workload["id"], "case_id": case["id"],
                                     "input_length": len(values), "input_values": values,
                                     "expected_result": expected_result,
                                     "expected_output": expected_output},
                        "measurement": {"comparison_model": "float64_slice_io_call",
                                        "observed_result": observed_result,
                                        "observed_output": observed_output,
                                        "samples_ns": raw["samples_ns"],
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "sample_count": samples, "warmup_rounds": warmups,
                                        "repetitions_per_sample": repetitions,
                                        "absolute_tolerance": absolute_tolerance,
                                        "relative_tolerance": relative_tolerance}})
    destination = args.output or ROOT / "benchmarks" / "results" / f"{algorithm}-{language}.jsonl"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("".join(json.dumps(record, sort_keys=True) + "\n" for record in records),
                           encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
