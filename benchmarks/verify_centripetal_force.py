#!/usr/bin/env python3
"""Verify centripetal-force ports through the i64_array_float64 ABI."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from centripetal_force_oracle import (
    INVALID_RESULT, MAX_ABSOLUTE_VELOCITY, MAX_MASS, MAX_RADIUS, expected_result,
)
from run_i64_array_float64 import encode_case, resolve_tolerances, result_matches

ALGORITHM = "centripetal_force"
WORKLOAD_PATH = ROOT / "benchmarks/c/centripetal_force/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def corpus(workload: dict) -> tuple[list[tuple[int, ...]], float, float]:
    absolute_tolerance, relative_tolerance = resolve_tolerances(workload)
    cases = {tuple(case["input_values"]) for case in workload["cases"]}

    masses = (0, 1, MAX_MASS // 2, MAX_MASS - 1, MAX_MASS)
    velocities = (-MAX_ABSOLUTE_VELOCITY, -MAX_ABSOLUTE_VELOCITY + 1,
                  -1, 0, 1, MAX_ABSOLUTE_VELOCITY - 1, MAX_ABSOLUTE_VELOCITY)
    radii = (1, 2, MAX_RADIUS // 2, MAX_RADIUS - 1, MAX_RADIUS)
    for mass in masses:
        for velocity in velocities:
            for radius in radii:
                cases.add((mass, velocity, radius))

    generator = random.Random(0xCE4719A1)
    for _ in range(256):
        cases.add((generator.randint(0, MAX_MASS),
                   generator.randint(-MAX_ABSOLUTE_VELOCITY, MAX_ABSOLUTE_VELOCITY),
                   generator.randint(1, MAX_RADIUS)))

    cases.update((
        (), (1,), (1, 2), (1, 2, 3, 4),
        (-1, 2, 1), (MAX_MASS + 1, 2, 1),
        (1, -MAX_ABSOLUTE_VELOCITY - 1, 1),
        (1, MAX_ABSOLUTE_VELOCITY + 1, 1),
        (1, 2, 0), (1, 2, MAX_RADIUS + 1),
        (I64_MIN, 0, 1), (1, I64_MAX, 1), (1, 0, I64_MAX),
    ))

    for case in workload["cases"]:
        values, expected = encode_case(case, ALGORITHM)
        oracle_result = expected_result(values)
        if not result_matches(expected, oracle_result, absolute_tolerance, relative_tolerance):
            raise ValueError(f"workload disagrees with the centripetal-force oracle: {case['id']}")
    return sorted(cases), absolute_tolerance, relative_tolerance


def _run_one(runner: Path, values: tuple[int, ...], expected: float,
             absolute_tolerance: float, relative_tolerance: float) -> float:
    command = [str(runner), str(len(values)), *map(str, values), repr(expected),
               repr(absolute_tolerance), repr(relative_tolerance), "1", "0", "1"]
    completed = subprocess.run(command, capture_output=True, text=True, timeout=30)
    if completed.returncode:
        raise RuntimeError(f"array-float64 runner rejected {values}: {completed.stderr}")
    return float(json.loads(completed.stdout)["observed_result"])


def verify(language: str, directory: Path, elisa_compiler: str | None,
           cases: list[tuple[int, ...]], workload: dict,
           absolute_tolerance: float, relative_tolerance: float) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     family="i64_array_float64")
    runner = Path(manifest["binaries"]["i64_array_float64_runner"]["path"])
    for values in cases:
        expected = expected_result(values)
        observed = _run_one(runner, values, expected, absolute_tolerance, relative_tolerance)
        if not result_matches(observed, expected, absolute_tolerance, relative_tolerance):
            raise RuntimeError(f"{language} result differs from the centripetal-force oracle: {values}")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_float64.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values, expected = encode_case(case, ALGORITHM)
        oracle_result = expected_result(values)
        observed = float(record["measurement"]["observed_result"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["measurement"]["comparison_model"] != "i64_array_float64_call"
                or len(record["measurement"]["samples_ns"]) != 1
                or record["workload"]["input_values"] != values
                or record["workload"]["input_length"] != len(values)
                or not result_matches(expected, oracle_result, absolute_tolerance, relative_tolerance)
                or not result_matches(observed, oracle_result, absolute_tolerance, relative_tolerance)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": len(cases), "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_float64/centripetal_force")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    cases, absolute_tolerance, relative_tolerance = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, args.build_dir / language,
                                   args.elisa_compiler, cases, workload,
                                   absolute_tolerance, relative_tolerance): language
                   for language in args.languages}
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda item: item["language"])
    report = {"algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": platform.platform(), "oracle_cases_per_language": len(cases),
              "results": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
