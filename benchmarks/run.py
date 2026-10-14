#!/usr/bin/env python3
"""Run the shared C ABI benchmark runner and append schema-shaped JSONL records."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import platform
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def generated_value(index: int, length: int, generation: dict[str, Any]) -> int:
    kind = generation["kind"]
    multiplier = int(generation["multiplier"])
    if kind == "modular_affine":
        return ((index * multiplier) % int(generation["modulus"])) - int(generation["offset"])
    if kind == "ascending":
        offset = generation["offset"]
        return index * multiplier - (length if offset == "length" else int(offset))
    raise ValueError(f"unsupported input generation kind: {kind}")


def binary_search_comparisons(length: int, target: int, generation: dict[str, Any]) -> int:
    low = 0
    high = length
    comparisons = 0
    while low < high:
        middle = low + (high - low) // 2
        value = generated_value(middle, length, generation)
        comparisons += 1
        if value == target:
            break
        comparisons += 1
        if value < target:
            low = middle + 1
        else:
            high = middle
    return max(1, comparisons)


def exponential_search_comparisons(length: int, target: int, generation: dict[str, Any]) -> int:
    if length == 0:
        return 1
    upper = 1
    comparisons = 0
    while upper < length:
        comparisons += 1
        if generated_value(upper, length, generation) <= target:
            upper = length if upper > length // 2 else upper * 2
        else:
            break
    low = upper // 2
    high = upper
    while low < high:
        middle = low + (high - low) // 2
        value = generated_value(middle, length, generation)
        comparisons += 1
        if value == target:
            break
        comparisons += 1
        if value < target:
            low = middle + 1
        else:
            high = middle
    return max(1, comparisons)


def workload_cases(workload: dict[str, Any]) -> list[dict[str, int | str]]:
    input_spec = workload["input"]
    generation = input_spec["generation"]
    miss_case_ids = set(workload["empty_input_case_ids"])
    cases: list[dict[str, int | str]] = []

    for length_value in input_spec["lengths"]:
        length = int(length_value)
        active_cases = workload["cases"]
        if length == 0:
            active_cases = [case for case in active_cases if case["id"] in miss_case_ids]

        for case in active_cases:
            target_from = case["target_from"]
            if target_from == "fixed":
                target = int(case["target"])
            elif target_from == "first":
                target = generated_value(0, length, generation)
            elif target_from == "middle":
                target = generated_value(length // 2, length, generation)
            elif target_from == "last":
                target = generated_value(length - 1, length, generation)
            else:
                raise ValueError(f"unsupported target_from value: {target_from}")

            expected_from = case.get("expected_from", "fixed")
            if expected_from == "first_index":
                expected = 0
            elif expected_from == "middle_index":
                expected = length // 2
            elif expected_from == "last_index":
                expected = length - 1
            elif expected_from == "not_found":
                expected = -1
            else:
                expected = int(case["expected"])

            cases.append(
                {
                    "length": length,
                    "case": str(case["id"]),
                    "target": target,
                    "expected": expected,
                    "generation_kind": str(generation["kind"]),
                    "multiplier": int(generation["multiplier"]),
                    "modulus": int(generation.get("modulus", 1)),
                    "offset": (
                        length
                        if generation.get("offset") == "length"
                        else int(generation.get("offset", 0))
                    ),
                }
            )
    return cases


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", required=True)
    parser.add_argument("--language", required=True)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--compiler", required=True)
    parser.add_argument("--compiler-version", required=True)
    parser.add_argument("--build-flags", default="")
    parser.add_argument("--build-command", required=True)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--target-comparisons", type=int)
    args = parser.parse_args()

    letter = args.algorithm[0].lower() if args.algorithm and args.algorithm[0].isalpha() else "0-9"
    workload_path = (args.workload or ROOT / "benchmarks" / letter / args.algorithm / "workload.json").resolve()
    source_path = args.source.resolve()
    executable_path = args.executable.resolve()
    runner_source = ROOT / "benchmarks" / "harness" / "runner.c"
    output_path = (args.output or ROOT / "results" / letter / args.algorithm / f"{args.language}.jsonl").resolve()

    for path, label in (
        (workload_path, "workload"),
        (source_path, "source"),
        (executable_path, "executable"),
        (runner_source, "runner source"),
    ):
        if not path.is_file():
            parser.error(f"{label} file does not exist: {path}")

    try:
        source_relative = source_path.relative_to(ROOT).as_posix()
    except ValueError:
        parser.error("--source must be inside the encyclopedia repository")

    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload["algorithm"] != args.algorithm:
        parser.error(f"workload algorithm is {workload['algorithm']!r}, not {args.algorithm!r}")

    timing = workload["measurement"]
    sample_count = args.samples if args.samples is not None else int(timing["sample_count"])
    warmup_rounds = args.warmups if args.warmups is not None else int(timing["warmup_rounds"])
    target_comparisons = (
        args.target_comparisons
        if args.target_comparisons is not None
        else int(timing["target_comparisons_per_sample"])
    )
    if sample_count < 1 or warmup_rounds < 0 or target_comparisons < 1:
        parser.error("samples and target comparisons must be positive; warmups cannot be negative")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    cpu_model = platform.processor().strip() or None
    logical_cpu_count = os.cpu_count()
    environment = {
        "os": platform.system(),
        "os_release": platform.release(),
        "architecture": platform.machine(),
        "cpu_model": cpu_model,
        "logical_cpu_count": logical_cpu_count,
        "python_version": platform.python_version(),
    }
    implementation = {
        "language": args.language,
        "source_path": source_relative,
        "source_sha256": sha256_file(source_path),
        "runner_source_sha256": sha256_file(runner_source),
        "binary_sha256": sha256_file(executable_path),
        "compiler": args.compiler,
        "compiler_version": args.compiler_version,
        "build_flags": args.build_flags,
        "build_command": args.build_command,
    }

    records: list[dict[str, Any]] = []
    for case in workload_cases(workload):
        length = int(case["length"])
        expected = int(case["expected"])
        comparison_model = timing["comparison_model"]
        if comparison_model == "linear_scan":
            comparisons_per_call = expected + 1 if expected >= 0 else length
        elif comparison_model == "binary_search":
            comparisons_per_call = binary_search_comparisons(
                length, int(case["target"]), workload["input"]["generation"]
            )
        elif comparison_model == "exponential_search":
            comparisons_per_call = exponential_search_comparisons(
                length, int(case["target"]), workload["input"]["generation"]
            )
        else:
            parser.error(f"unsupported comparison model: {comparison_model}")
        estimated_comparisons = max(1, comparisons_per_call)
        repetitions = max(
            1,
            (target_comparisons + estimated_comparisons - 1) // estimated_comparisons,
        )
        command = [
            str(executable_path),
            str(length),
            str(case["target"]),
            str(expected),
            str(sample_count),
            str(warmup_rounds),
            str(repetitions),
            str(case["generation_kind"]),
            str(case["multiplier"]),
            str(case["modulus"]),
            str(case["offset"]),
        ]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            sys.stderr.write(completed.stderr)
            raise SystemExit(f"runner failed for {case['case']} at length {length}")
        try:
            raw = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            raise SystemExit(f"runner emitted invalid JSON for {case['case']}: {error}") from error
        if int(raw["observed_result"]) != expected:
            raise SystemExit(f"correctness mismatch for {case['case']} at length {length}")
        if len(raw["samples_ns"]) != sample_count:
            raise SystemExit(f"runner returned the wrong sample count for {case['case']}")

        records.append(
            {
                "schema_version": "1.0.0",
                "run_id": run_id,
                "algorithm": args.algorithm,
                "implementation": implementation,
                "environment": environment,
                "workload": {
                    "id": workload["id"],
                    "spec_sha256": sha256_file(workload_path),
                    "input_length": length,
                    "case": case["case"],
                    "target": int(case["target"]),
                    "expected_result": expected,
                },
                "measurement": {
                    "timer": "C clock() process CPU time",
                    "timer_resolution_ns": float(raw["timer_resolution_ns"]),
                    "comparison_model": comparison_model,
                    "target_comparisons_per_sample": target_comparisons,
                    "warmup_rounds": warmup_rounds,
                    "repetitions_per_sample": repetitions,
                    "samples_ns": [int(sample) for sample in raw["samples_ns"]],
                    "observed_result": int(raw["observed_result"]),
                    "result_checksum": int(raw["result_checksum"]),
                },
            }
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("a", encoding="utf-8", newline="\n") as output:
        for record in records:
            output.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
