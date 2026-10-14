#!/usr/bin/env python3
"""Check fractional knapsack ports against an exact rational greedy oracle."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from fractions import Fraction
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "fractional_knapsack"
MAX_CAPACITY = 1_000_000
MAX_ITEMS = 128
MAX_WEIGHT = 1_000_000
MAX_VALUE = 1_000_000
SCALE = 1_000_000


def oracle(packed: list[int]) -> int:
    if len(packed) < 2 or len(packed) > 258:
        return -1
    capacity, item_count = packed[:2]
    if not 0 <= capacity <= MAX_CAPACITY or not 0 <= item_count <= MAX_ITEMS:
        return -1
    if len(packed) != 2 + 2 * item_count:
        return -1
    items: list[tuple[int, int]] = []
    for item in range(item_count):
        weight, value = packed[2 + 2 * item:4 + 2 * item]
        if not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE:
            return -1
        items.append((weight, value))
    items.sort(key=lambda item: Fraction(item[1], item[0]), reverse=True)
    remaining = capacity
    total = Fraction(0, 1)
    for weight, value in items:
        if remaining == 0:
            break
        portion = min(weight, remaining)
        total += Fraction(value * portion, weight)
        remaining -= portion
    return total.numerator * SCALE // total.denominator


def checker_corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with rational oracle: {case['id']}")
        cases[tuple(values)] = expected

    choices = ((1, 0), (1, 1), (2, 3), (3, 4), (4, 5))
    sequences: list[tuple[tuple[int, int], ...]] = [()]
    for size in range(1, 5):
        sequences.extend(product(choices, repeat=size))
    for items in sequences:
        for capacity in range(8):
            packed = [capacity, len(items)]
            for weight, value in items:
                packed.extend((weight, value))
            cases[tuple(packed)] = oracle(packed)

    rng = random.Random(20261014)
    for _ in range(512):
        item_count = rng.randrange(0, 33)
        packed = [rng.randrange(0, 1001), item_count]
        for _ in range(item_count):
            packed.extend((rng.choice((1, 2, 3, 8, 64, 513, MAX_WEIGHT)),
                           rng.choice((0, 1, 7, 999, MAX_VALUE, rng.randrange(MAX_VALUE + 1)))))
        cases[tuple(packed)] = oracle(packed)

    invalid = [
        [], [0], [-1, 0], [MAX_CAPACITY + 1, 0], [0, -1], [0, MAX_ITEMS + 1],
        [4, 1], [0, 1, 0, 1], [0, 1, MAX_WEIGHT + 1, 1],
        [0, 1, 1, -1], [0, 1, 1, MAX_VALUE + 1], [0, 0, 1],
        [0, 1, 1], [0, 1, 1, 1, 2, 2],
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
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text().splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        expected = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/fractional_knapsack")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/f/fractional_knapsack/workload.json").read_text())
    data, case_count = checker_corpus(workload)

    results: list[dict] = []
    failures: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {pool.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({"language": language, "error": str(exc)})
                print(f"FAIL {language}: {exc}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {language}: {case_count} oracle traces, {result['workload_records']} workload records",
                  flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "oracle_cases": case_count, "results": sorted(results, key=lambda row: row["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
