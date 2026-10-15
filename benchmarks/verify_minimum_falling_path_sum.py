#!/usr/bin/env python3
"""Verify minimum-falling-path-sum ports against a row-DP oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "minimum_falling_path_sum"
MAX_N = 100
MIN_VALUE, MAX_VALUE = -100, 100
INVALID_RESULT = -10001
WORKLOAD_PATH = ROOT / "benchmarks/m/minimum_falling_path_sum/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= 1 + MAX_N * MAX_N
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return INVALID_RESULT
    matrix = values[1:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in matrix):
        return INVALID_RESULT

    previous = matrix[:n]
    for row in range(1, n):
        current = []
        for column in range(n):
            best = min(previous[max(0, column - 1):min(n, column + 2)])
            current.append(best + matrix[row * n + column])
        previous = current
    return min(previous)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))

    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(values)] = expected

    for n in (1, 2, 3):
        for cells in product((-1, 0, 1), repeat=n * n):
            add((n, *cells))

    for n in range(1, 5):
        for value in (MIN_VALUE, MAX_VALUE):
            add((n, *([value] * (n * n))))
        checkerboard = [MIN_VALUE if (row + column) % 2 else MAX_VALUE
                        for row in range(n) for column in range(n)]
        add((n, *checkerboard))

    rng = random.Random(20261015)
    for _ in range(512):
        n = rng.randint(1, MAX_N)
        matrix = [rng.randint(MIN_VALUE, MAX_VALUE) for _ in range(n * n)]
        add((n, *matrix))
        mutation = rng.randrange(4)
        if mutation == 0:
            add((0, *matrix))
        elif mutation == 1:
            add((n, *matrix[:-1]))
        elif mutation == 2:
            invalid = list(matrix)
            invalid[rng.randrange(len(invalid))] = rng.choice((-101, 101))
            add((n, *invalid))
        else:
            add((n, *matrix, 0))

    add(())
    add((MAX_N + 1,))
    add((1, MIN_VALUE - 1))
    add((1, MAX_VALUE + 1))
    add((1, 0, 0))
    add((-(2**63),))
    add((2**63 - 1,))
    oversized = [MAX_N, *([0] * (MAX_N * MAX_N + 1))]
    add(oversized)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"i64-array C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/minimum_falling_path_sum")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle matrices, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
