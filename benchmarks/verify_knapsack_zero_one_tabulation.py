#!/usr/bin/env python3
"""Check all tabulated 0/1 knapsack ports against a separate Python oracle."""

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

ALGORITHM = "knapsack_zero_one_tabulation"
MAX_CAPACITY = 512
MAX_ITEMS = 128
MAX_WEIGHT = 4096
MAX_VALUE = 1_000_000_000
MAX_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
INVALID_RESULT = -1
PINNED_SOURCE = {
    "repository": "TheAlgorithms/Java",
    "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
    "path": "src/main/java/com/thealgorithms/dynamicprogramming/KnapsackZeroOneTabulation.java",
    "method": "compute",
    "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/KnapsackZeroOneTabulation.java",
    "role": "algorithm",
}
CASE_IDS = {
    "classic_example", "no_items_zero_capacity", "no_items_positive_capacity",
    "zero_capacity_skips_positive_weights", "exact_capacity_fit", "all_items_too_heavy",
    "combination_beats_best_single", "item_is_not_reused", "input_order_permutation",
    "zero_value_item", "maximum_capacity", "maximum_value_and_out_of_capacity_item",
    "maximum_item_count", "null_input_pointer_with_positive_length",
}


def validate_workload(workload: dict) -> None:
    """Require the reviewed source pin, packed-array bounds, and null probe."""
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    measurement = workload.get("measurement", {})
    cases = workload.get("cases")
    expected_input = {
        "kind": "packed_signed_64_bit_integer_array",
        "encoding": "[capacity, item_count, weight_0, value_0, ...]",
        "maximum_capacity": MAX_CAPACITY,
        "maximum_item_count": MAX_ITEMS,
        "item_weight_range": [1, MAX_WEIGHT],
        "item_value_range": [0, MAX_VALUE],
        "maximum_valid_input_length": MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": MAX_INPUT_LENGTH,
        "null_input_result": INVALID_RESULT,
        "invalid_result": INVALID_RESULT,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "meaning": "Maximum achievable value without exceeding capacity, using each item at most once.",
        "invalid_result": INVALID_RESULT,
    }
    if (workload.get("schema_version") != 1
            or workload.get("id") != "knapsack-zero-one-tabulation-v1"
            or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("pinned_source") != PINNED_SOURCE
            or input_spec != expected_input
            or output_spec != expected_output
            or measurement != {
                "comparison_model": "i64_array_scalar_call",
                "sample_count": 9,
                "warmup_rounds": 1,
                "repetitions_per_sample": 20,
            }
            or not isinstance(cases, list)):
        raise ValueError("knapsack workload metadata does not match its pinned contract")

    case_ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(case_ids) != len(cases) or len(case_ids) != len(set(case_ids)) or set(case_ids) != CASE_IDS:
        raise ValueError("knapsack workload fixture IDs do not match the reviewed fixture set")
    null_cases = [case for case in cases if case.get("input_is_null") is True]
    if (len(null_cases) != 1
            or null_cases[0].get("id") != "null_input_pointer_with_positive_length"
            or null_cases[0].get("input_values") != []
            or null_cases[0].get("input_length") != 1
            or null_cases[0].get("expected_result") != INVALID_RESULT):
        raise ValueError("knapsack workload must cover a positive-length null input pointer")
    maximum_item_case = next(case for case in cases if case.get("id") == "maximum_item_count")
    maximum_item_values = [MAX_CAPACITY, MAX_ITEMS, *([1, 1] * MAX_ITEMS)]
    if (maximum_item_case.get("input_values") != maximum_item_values
            or maximum_item_case.get("expected_result") != MAX_ITEMS):
        raise ValueError("knapsack workload is missing the exact maximum-item-count fixture")
    for case in cases:
        values = case.get("input_values")
        is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        if (not isinstance(values, list)
                or any(type(value) is not int for value in values)
                or type(is_null) is not bool
                or type(input_length) is not int
                or type(case.get("expected_result")) is not int
                or (is_null and (values or not 1 <= input_length <= MAX_INPUT_LENGTH))
                or (not is_null and (input_length != len(values)
                                     or len(values) > MAX_INPUT_LENGTH))):
            raise ValueError(f"knapsack workload input framing is invalid for {case.get('id')}")

    readme = (ROOT / "benchmarks/k/knapsack_zero_one_tabulation/README.md").read_text(encoding="utf-8")
    if PINNED_SOURCE["url"] not in readme or "null input pointer" not in readme:
        raise ValueError("knapsack README is missing the pinned source or null-input contract")


def oracle(packed: list[int]) -> int:
    if not isinstance(packed, list) or len(packed) < 2 or len(packed) > 258:
        return -1
    if any(type(value) is not int for value in packed):
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
    validate_workload(workload)
    cases: dict[tuple[int, ...], int] = {}
    special_records: list[str] = []
    for case in workload["cases"]:
        values = encode_case(case, ALGORITHM)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with Python oracle: {case['id']}")
        if case.get("input_is_null", False):
            special_records.append(f"NULL {case['input_length']} {expected}\n")
            continue
        cases[tuple(values)] = expected

    # Exhaust every short sequence over a small set of distinct item choices.
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
    for _ in range(512):
        item_count = rng.randrange(0, 18)
        packed = [rng.randrange(0, MAX_CAPACITY + 1), item_count]
        for _ in range(item_count):
            packed.extend((rng.choice([1, 2, 3, 8, 64, 513, 4096]),
                           rng.choice([0, 1, 7, 999, MAX_VALUE, rng.randrange(MAX_VALUE + 1)])))
        cases[tuple(packed)] = oracle(packed)

    invalid = [
        [], [0], [-1, 0], [513, 0], [0, -1], [0, 129], [4, 1],
        [0, 1, 0, 1], [0, 1, 4097, 1], [0, 1, 1, -1], [0, 1, 1, MAX_VALUE + 1],
    ]
    for packed in invalid:
        cases[tuple(packed)] = -1

    lines = [f"{len(cases) + len(special_records)}\n"]
    for packed, expected in sorted(cases.items()):
        suffix = "" if not packed else " " + " ".join(map(str, packed))
        lines.append(f"{len(packed)} {expected}{suffix}\n")
    lines.extend(special_records)
    return "".join(lines), len(cases) + len(special_records)


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
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
        input_length = case.get("input_length", len(values))
        input_is_null = case.get("input_is_null", False)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != input_length
                or record["workload"]["input_values"] != values
                or record["workload"].get("input_is_null", False) != input_is_null
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/k/knapsack_zero_one_tabulation/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
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
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
