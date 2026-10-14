#!/usr/bin/env python3
"""Check segment-tree operation traces against a direct-array oracle."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "segment_tree"
MAX_ITEMS = 256
MAX_OPERATIONS = 512
MAX_INPUT_VALUES = MAX_ITEMS + 3 + 3 * MAX_OPERATIONS
VALUE_LIMIT = 1_000_000
QUERY_OFFSET = 256_000_001
FINAL_OFFSET = 1_000_001


def encode_trace(mode: int, data: list[int], operations: list[tuple[int, int, int]]) -> list[int]:
    return [mode, len(data), *data, len(operations), *(value for operation in operations for value in operation)]


def oracle(values: list[int]) -> int:
    if len(values) < 3 or len(values) > MAX_INPUT_VALUES:
        return -1
    mode, item_count = values[:2]
    if mode not in (0, 1, 2) or item_count < 1 or item_count > MAX_ITEMS:
        return -1
    if len(values) < item_count + 3:
        return -1
    operation_count = values[item_count + 2]
    if operation_count < 0 or operation_count > MAX_OPERATIONS:
        return -1
    if len(values) != item_count + 3 + 3 * operation_count:
        return -1
    data = values[2:item_count + 2]
    if any(value < -VALUE_LIMIT or value > VALUE_LIMIT for value in data):
        return -1

    operations = [values[index:index + 3]
                  for index in range(item_count + 3, len(values), 3)]
    for opcode, first, second in operations:
        if opcode == 0:
            if first < 0 or first >= item_count or second < -VALUE_LIMIT or second > VALUE_LIMIT:
                return -1
        elif opcode == 1:
            if first < 0 or second < first or second >= item_count:
                return -1
        else:
            return -1

    checksum = 0
    for operation, (opcode, first, second) in enumerate(operations):
        if opcode == 0:
            data[first] = second
        else:
            selected = data[first:second + 1]
            if mode == 0:
                result = sum(selected)
            elif mode == 1:
                result = min(selected)
            else:
                result = max(selected)
            checksum += (operation + 1) * (result + QUERY_OFFSET)
    for index, value in enumerate(data):
        checksum += (operation_count + index + 1) * (value + FINAL_OFFSET)
    return checksum


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def include(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))

    # Exhaust short arrays and every update/query trace of length zero through two.
    for item_count in range(1, 4):
        for initial in itertools.product((-1, 0, 1), repeat=item_count):
            operations = ([(0, index, value) for index in range(item_count) for value in (-1, 0, 1)]
                          + [(1, left, right) for left in range(item_count)
                             for right in range(left, item_count)])
            for mode in range(3):
                for operation_count in range(3):
                    for trace in itertools.product(operations, repeat=operation_count):
                        include(encode_trace(mode, list(initial), list(trace)))

    rng = random.Random(20261014)
    for _ in range(768):
        item_count = rng.randrange(1, MAX_ITEMS + 1)
        initial = [rng.randrange(-VALUE_LIMIT, VALUE_LIMIT + 1) for _ in range(item_count)]
        operation_count = rng.randrange(MAX_OPERATIONS + 1)
        operations: list[tuple[int, int, int]] = []
        for _operation in range(operation_count):
            if rng.randrange(2) == 0:
                operations.append((0, rng.randrange(item_count), rng.randrange(-VALUE_LIMIT, VALUE_LIMIT + 1)))
            else:
                left = rng.randrange(item_count)
                right = rng.randrange(left, item_count)
                operations.append((1, left, right))
        include(encode_trace(rng.randrange(3), initial, operations))

    # Exercise the maximum array and trace length with updates interleaved with queries.
    max_data = [((index * 7919) % 2_000_001) - 1_000_000 for index in range(MAX_ITEMS)]
    max_operations = [((0, step % MAX_ITEMS, MAX_ITEMS - step * 997)
                       if step % 2 == 0 else (1, step % MAX_ITEMS, MAX_ITEMS - 1))
                      for step in range(MAX_OPERATIONS)]
    include(encode_trace(0, max_data, max_operations))

    malformed = [
        (), (0,), (0, 1), (3, 1, 0, 0), (0, 0, 0),
        (0, 1, 1, 1),                 # missing operation payload
        (0, 1, 0, 1, 0, 0, 99),     # trailing value
        (0, 1, VALUE_LIMIT + 1, 0),
        (0, 1, 0, 1, 0, 1, 0),      # unknown opcode
        (0, 1, 0, 1, 0, -1, 0),     # invalid update index
        (1, 2, 4, 5, 1, 1, 1, 0),  # reversed query interval
        (2, 1, 0, 1, 1, 0, 1),      # query beyond array
        (0, 1, 0, MAX_OPERATIONS + 1),
        (0, MAX_ITEMS + 1, 0),
        tuple([0, 1, 0, 0] + [0, 0, 0] * (MAX_OPERATIONS + 1)),
    ]
    for values in malformed:
        include(values)
    for _ in range(512):
        size = rng.randrange(0, 81)
        include(tuple(rng.choice((-1, 0, 1, 2, 3, 256, 513, 1_000_001)) for _ in range(size)))

    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        include(values)

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
        raise RuntimeError(f"array-scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
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
            raise RuntimeError(f"recorded result or provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/s/segment_tree/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path),
        "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/s/segment_tree")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload = json.loads((ROOT / "benchmarks/s/segment_tree/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
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
              "oracle_cases": case_count, "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
