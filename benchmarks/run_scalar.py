#!/usr/bin/env python3
"""Run the portable scalar benchmark runner and append JSONL records."""

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
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()

    letter = args.algorithm[0].lower() if args.algorithm and args.algorithm[0].isalpha() else "0-9"
    workload_path = (args.workload or ROOT / "benchmarks" / letter / args.algorithm / "workload.json").resolve()
    source_path = args.source.resolve()
    executable_path = args.executable.resolve()
    runner_source = ROOT / "benchmarks" / "harness" / "scalar_runner.c"
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
    repetitions = (
        args.repetitions
        if args.repetitions is not None
        else int(timing["repetitions_per_sample"])
    )
    if sample_count < 1 or warmup_rounds < 0 or repetitions < 1:
        parser.error("samples and repetitions must be positive; warmups cannot be negative")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    environment = {
        "os": platform.system(),
        "os_release": platform.release(),
        "architecture": platform.machine(),
        "cpu_model": platform.processor().strip() or None,
        "logical_cpu_count": os.cpu_count(),
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

    spec_sha256 = sha256_file(workload_path)
    records: list[dict[str, Any]] = []
    for case in workload["cases"]:
        input_value = int(case["input_value"])
        expected_result = int(case["expected_result"])
        command = [
            str(executable_path),
            str(input_value),
            str(expected_result),
            str(sample_count),
            str(warmup_rounds),
            str(repetitions),
        ]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            sys.stderr.write(completed.stderr)
            raise SystemExit(f"scalar runner failed for case {case['id']!r}")
        try:
            raw = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            raise SystemExit(f"scalar runner emitted invalid JSON for {case['id']!r}: {error}") from error
        if int(raw["observed_result"]) != expected_result:
            raise SystemExit(f"scalar runner returned the wrong result for {case['id']!r}")
        if len(raw["samples_ns"]) != sample_count:
            raise SystemExit(f"scalar runner returned the wrong sample count for {case['id']!r}")

        records.append(
            {
                "schema_version": "1.0.0",
                "run_id": run_id,
                "algorithm": args.algorithm,
                "implementation": implementation,
                "environment": environment,
                "workload": {
                    "id": workload["id"],
                    "spec_sha256": spec_sha256,
                    "input_length": None,
                    "input_value": input_value,
                    "case": str(case["id"]),
                    "target": None,
                    "expected_result": expected_result,
                },
                "measurement": {
                    "timer": "C clock() process CPU time",
                    "timer_resolution_ns": float(raw["timer_resolution_ns"]),
                    "comparison_model": "scalar_call",
                    "target_comparisons_per_sample": None,
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
