#!/usr/bin/env python3
"""Check the sorted-array median ports against a sorting oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations_with_replacement, product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "median_of_two_sorted_arrays"
MAX_TOTAL_LENGTH = 1024
I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 3
            or any(type(value) is not int for value in values)):
        return -1
    first_count, second_count = values[:2]
    if (not 0 <= first_count <= MAX_TOTAL_LENGTH
            or not 0 <= second_count <= MAX_TOTAL_LENGTH
            or first_count + second_count == 0
            or first_count + second_count > MAX_TOTAL_LENGTH
            or len(values) != first_count + second_count + 2):
        return -1
    first = values[2:2 + first_count]
    second = values[2 + first_count:]
    if any(not I32_MIN <= value <= I32_MAX for value in first + second):
        return -1
    if first != sorted(first) or second != sorted(second):
        return -1
    ordered = sorted(first + second)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return 2 * ordered[middle]
    return ordered[middle - 1] + ordered[middle]


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[tuple(values)] = expected

    small_values = range(-2, 3)
    small_sorted = [list(combinations_with_replacement(small_values, length))
                    for length in range(5)]
    for first_group, second_group in product(small_sorted, repeat=2):
        for first, second in product(first_group, second_group):
            if len(first) + len(second) > 0:
                packed = [len(first), len(second), *first, *second]
                cases[tuple(packed)] = oracle(packed)

    boundaries = (I32_MIN, I32_MIN + 1, -1, 0, 1, I32_MAX - 1, I32_MAX)
    boundary_sorted = [list(combinations_with_replacement(boundaries, length))
                       for length in range(4)]
    for first_group, second_group in product(boundary_sorted, repeat=2):
        for first, second in product(first_group, second_group):
            if len(first) + len(second) > 0:
                packed = [len(first), len(second), *first, *second]
                cases[tuple(packed)] = oracle(packed)

    rng = random.Random(20261015)
    for _ in range(512):
        first_length = rng.randint(0, 80)
        second_length = rng.randint(0, 80)
        if first_length + second_length == 0:
            first_length = 1
        first = sorted(rng.randint(I32_MIN, I32_MAX) for _ in range(first_length))
        second = sorted(rng.randint(I32_MIN, I32_MAX) for _ in range(second_length))
        packed = [first_length, second_length, *first, *second]
        cases[tuple(packed)] = oracle(packed)

    invalid = [
        [], [0, 0], [-1, 1, 0], [1025, 0], [2, 0, 1], [2, 0, 2, 1],
        [0, 2, 2, 1], [1, 0, I32_MAX + 1], [0, 1, I32_MIN - 1],
        [1, 0, 5, 6], [600, 425, *range(1024), 1024],
    ]
    for values in invalid:
        cases[tuple(values)] = -1

    lines = [str(len(cases)) + "\n"]
    for values, expected in sorted(cases.items()):
        lines.append(f"{len(values)} {expected} " + " ".join(map(str, values)) + "\n")
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
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/median_of_two_sorted_arrays")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/m/median_of_two_sorted_arrays/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "median_of_two_sorted_arrays-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle cases, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
