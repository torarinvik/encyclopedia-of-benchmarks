#!/usr/bin/env python3
"""Verify rainfall intensity ports against a bounded formula oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from rainfall_intensity_oracle import INVALID_RESULT, rainfall_intensity

ALGORITHM = "rainfall_intensity"
WORKLOAD_PATH = ROOT / "benchmarks/r/rainfall_intensity/workload.json"
ABS_TOL = 1e-12
REL_TOL = 1e-12


def matches(observed: float, expected: float) -> bool:
    if expected == INVALID_RESULT:
        return observed == INVALID_RESULT
    return math.isfinite(observed) and math.isclose(
        observed, expected, rel_tol=REL_TOL, abs_tol=ABS_TOL)


def corpus(workload: dict) -> list[tuple[int, ...]]:
    cases: set[tuple[int, ...]] = set()
    for values in itertools.product((1, 1_000), (1, 2, 3), (1, 50, 100),
                                    (1, 2, 3), (1, 10, 100), (1, 500, 1_000)):
        cases.add(values)
    for values in (
        (), (1, 2, 3, 4, 5), (1, 2, 3, 4, 5, 6, 7),
        (0, 2, 3, 2, 5, 10), (1_001, 2, 3, 2, 5, 10),
        (1, 0, 3, 2, 5, 10), (1, 4, 3, 2, 5, 10),
        (1, 2, 0, 2, 5, 10), (1, 2, 101, 2, 5, 10),
        (1, 2, 3, 0, 5, 10), (1, 2, 3, 4, 5, 10),
        (1, 2, 3, 2, 0, 10), (1, 2, 3, 2, 101, 10),
        (1, 2, 3, 2, 5, 0), (1, 2, 3, 2, 5, 1_001),
    ):
        cases.add(values)
    rng = random.Random(20261015)
    for _ in range(256):
        cases.add((rng.randint(1, 1_000), rng.randint(1, 3),
                   rng.randint(1, 100), rng.randint(1, 3),
                   rng.randint(1, 100), rng.randint(1, 1_000)))
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = rainfall_intensity(list(values))
        if not matches(case["expected_result"], expected):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases.add(values)
    return sorted(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           values_list: list[tuple[int, ...]], workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     family="i64_array_float64")
    runner = Path(manifest["binaries"]["i64_array_float64_runner"]["path"])
    for values in values_list:
        expected = rainfall_intensity(list(values))
        command = [str(runner), str(len(values)), *map(str, values), repr(expected),
                   repr(ABS_TOL), repr(REL_TOL), "1", "0", "1"]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=30)
        if completed.returncode:
            raise RuntimeError(f"{language} result mismatch for {values}: {completed.stderr}")
        observed = float(json.loads(completed.stdout)["observed_result"])
        if not matches(observed, expected):
            raise RuntimeError(f"{language} result differs from formula oracle: {values}")

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
        values = case["input_values"]
        expected = rainfall_intensity(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["measurement"]["comparison_model"] != "i64_array_float64_call"
                or len(record["measurement"]["samples_ns"]) != 1
                or record["workload"]["input_values"] != values
                or record["workload"]["input_length"] != len(values)
                or not matches(record["workload"]["expected_result"], expected)
                or not matches(record["measurement"]["observed_result"], expected)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": len(values_list), "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_float64/rainfall_intensity")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    values_list = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, args.build_dir / language,
                                   args.elisa_compiler, values_list, workload): language
                   for language in args.languages}
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda item: item["language"])
    report = {"algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": platform.platform(), "oracle_cases_per_language": len(values_list),
              "results": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
