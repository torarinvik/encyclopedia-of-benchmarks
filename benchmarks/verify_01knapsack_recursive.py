#!/usr/bin/env python3
"""Verify direct recursive 0/1 knapsack ports through the shared array ABI."""

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

ALGORITHM = "01knapsack_recursive"
MAX_CAPACITY = 512
MAX_ITEMS = 16
MAX_WEIGHT = 4096
MAX_VALUE = 1_000_000_000


def oracle(packed: list[int] | tuple[int, ...]) -> int:
    if len(packed) < 2 or len(packed) > 2 + 2 * MAX_ITEMS:
        return -1
    capacity, item_count = packed[:2]
    if not 0 <= capacity <= MAX_CAPACITY or not 0 <= item_count <= MAX_ITEMS:
        return -1
    if len(packed) != 2 + 2 * item_count:
        return -1
    dp = [0] * (capacity + 1)
    for item in range(item_count):
        weight, value = packed[2 + 2 * item:4 + 2 * item]
        if not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE:
            return -1
        for current_capacity in range(capacity, weight - 1, -1):
            dp[current_capacity] = max(
                dp[current_capacity], dp[current_capacity - weight] + value
            )
    return dp[capacity]


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        packed = tuple(encode_case(case, ALGORITHM))
        expected = oracle(packed)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[packed] = expected

    choices = ((1, 0), (1, 1), (2, 3), (3, 4), (4, 5))
    sequences: list[tuple[tuple[int, int], ...]] = [()]
    for size in range(1, 5):
        sequences.extend(product(choices, repeat=size))
    for items in sequences:
        for capacity in range(7):
            packed = [capacity, len(items)]
            for weight, value in items:
                packed.extend((weight, value))
            cases[tuple(packed)] = oracle(packed)

    rng = random.Random(20261014)
    for _ in range(384):
        item_count = rng.randrange(0, 14)
        packed = [rng.randrange(0, MAX_CAPACITY + 1), item_count]
        for _ in range(item_count):
            packed.extend((rng.choice([1, 2, 3, 8, 64, 513, MAX_WEIGHT]),
                           rng.choice([0, 1, 7, 999, MAX_VALUE, rng.randrange(MAX_VALUE + 1)])))
        cases[tuple(packed)] = oracle(packed)

    invalid = [
        (), (0,), (-1, 0), (MAX_CAPACITY + 1, 0), (0, -1),
        (0, MAX_ITEMS + 1), (4, 1), (0, 1, 0, 1),
        (0, 1, MAX_WEIGHT + 1, 1), (0, 1, 1, -1),
        (0, 1, 1, MAX_VALUE + 1),
    ]
    for packed in invalid:
        cases[tuple(packed)] = -1

    lines = [f"{len(cases)}\n"]
    for packed, expected in sorted(cases.items()):
        suffix = "" if not packed else " " + " ".join(map(str, packed))
        lines.append(f"{len(packed)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array-scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/01knapsack_recursive")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language choices must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/0-9/01knapsack_recursive/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "01knapsack_recursive-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / "0-9" / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
