#!/usr/bin/env python3
"""Verify branch-and-bound knapsack ports against a fractional-bound oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from fractions import Fraction
from itertools import product
import json
from pathlib import Path
import random
import subprocess
import sys

from branch_and_bound_knapsack_oracle import (
    MAX_CAPACITY, MAX_INPUT_LENGTH, MAX_ITEMS, MAX_ITEM_VALUE, MAX_ITEM_WEIGHT,
    expected_output as recorder_oracle,
)
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output as shared_oracle
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "branch_and_bound_knapsack_solver"
WORKLOAD_PATH = ROOT / "benchmarks/b/branch_and_bound_knapsack_solver/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent queue implementation; fractions make pruning exact."""
    if (not isinstance(values, (tuple, list)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    count, capacity = values[:2]
    if (not 0 <= count <= MAX_ITEMS or not 0 <= capacity <= MAX_CAPACITY
            or len(values) != 2 + 2 * count):
        return -1, b""
    items = []
    for index in range(count):
        weight, value = values[2 + 2 * index:4 + 2 * index]
        if not 1 <= weight <= MAX_ITEM_WEIGHT or not 1 <= value <= MAX_ITEM_VALUE:
            return -1, b""
        items.append((index, weight, value))
    ordered = sorted(items, key=lambda item: Fraction(item[2], item[1]), reverse=True)
    queue = [(-1, 0, 0, 0)]
    head = 0
    best_value = 0
    best_mask = 0

    def fractional_bound(level: int, weight: int, value: int) -> Fraction:
        room = capacity - weight
        bound = Fraction(value)
        index = level + 1
        while room > 0 and index < count:
            _, item_weight, item_value = ordered[index]
            if item_weight <= room:
                bound += item_value
                room -= item_weight
            else:
                bound += Fraction(item_value * room, item_weight)
                room = 0
            index += 1
        return bound

    while head < len(queue):
        level, weight, value, mask = queue[head]
        head += 1
        if level == count - 1:
            continue
        next_level = level + 1
        _, item_weight, item_value = ordered[next_level]
        left_weight, left_value = weight + item_weight, value + item_value
        left_mask = mask | (1 << next_level)
        if left_weight <= capacity and left_value > best_value:
            best_value, best_mask = left_value, left_mask
        if fractional_bound(next_level, left_weight, left_value) > best_value and left_weight < capacity:
            queue.append((next_level, left_weight, left_value, left_mask))
        if fractional_bound(next_level, weight, value) > best_value:
            queue.append((next_level, weight, value, mask))

    chosen = bytes(ordered[level][0] for level in range(count - 1, -1, -1)
                   if best_mask & (1 << level))
    return len(chosen), chosen


def assert_optimal(values: tuple[int, ...], result: tuple[int, bytes]) -> None:
    if result[0] < 0:
        return
    count, capacity = values[:2]
    items = [tuple(values[2 + 2 * i:4 + 2 * i]) for i in range(count)]
    selected_ids = set(result[1])
    if len(selected_ids) != result[0] or any(index >= count for index in selected_ids):
        raise ValueError(f"oracle emitted invalid selected IDs for {values}")
    selected_weight = sum(items[index][0] for index in selected_ids)
    selected_value = sum(items[index][1] for index in selected_ids)
    optimum = max(
        (sum(items[index][1] for index in range(count) if mask & (1 << index))
         for mask in range(1 << count)
         if sum(items[index][0] for index in range(count) if mask & (1 << index)) <= capacity),
        default=0,
    )
    if selected_weight > capacity or selected_value != optimum:
        raise ValueError(f"branch-and-bound result is not optimal for {values}: {result}, optimum={optimum}")


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
    default_capacity = workload["workspace"]["bytes"]

    def add(values: tuple[int, ...] | list[int], output_capacity: int = default_capacity) -> None:
        packed = tuple(values)
        expected = oracle(packed)
        if (recorder_oracle(list(packed)) != expected
                or shared_oracle(list(packed), ALGORITHM) != expected):
            raise ValueError(f"independent and recorder oracles disagree: {packed}")
        assert_optimal(packed, expected)
        if not 0 <= output_capacity <= default_capacity:
            raise ValueError(f"invalid output capacity: {output_capacity}")
        actual = (-2, b"") if expected[0] >= 0 and output_capacity < len(expected[1]) else expected
        cases[(packed, output_capacity)] = actual

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = oracle(values)
        output_capacity = case.get("workspace_bytes", default_capacity)
        actual = (-2, b"") if expected[0] >= 0 and output_capacity < len(expected[1]) else expected
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != actual[0]
                or case.get("expected_output_hex") != actual[1].hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values, output_capacity)

    item_types = ((1, 1), (1, 2), (2, 1), (2, 2))
    for count in range(5):
        for items in product(item_types, repeat=count):
            item_values = tuple(value for pair in items for value in pair)
            packed_prefix = (count,)
            total_weight = sum(weight for weight, _ in items)
            for capacity in range(total_weight + 2):
                add((*packed_prefix, capacity, *item_values))

    rng = random.Random(20261015)
    for _ in range(512):
        count = rng.randrange(MAX_ITEMS + 1)
        items = [(rng.randrange(1, 1001), rng.randrange(1, 1001)) for _ in range(count)]
        capacity = rng.randrange(MAX_CAPACITY + 1)
        add((count, capacity, *(field for item in items for field in item)))

    sample = (3, 8, 2, 5, 3, 8, 1, 2)
    required = oracle(sample)
    for output_capacity in (0, max(0, len(required[1]) - 1), len(required[1]), default_capacity):
        add(sample, output_capacity)

    invalid = (
        (), (-1, 0), (0,), (9, 0), (0, -1), (0, 8001), (1, 0, 0, 1),
        (1, 0, 1, 0), (1, 0, 1001, 1), (1, 0, 1, 1001),
        (1, 0, 1), (1, 0, 1, 1, 2), (1, 0, I64_MIN, 1),
    )
    for values in invalid:
        add(values)

    records = sorted(cases.items(), key=lambda item: (len(item[0][0]), item[0][0], item[0][1]))
    lines = [f"{len(records)}\n"]
    for (values, output_capacity), (result, payload) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(payload)} {output_capacity}{suffix} {payload.hex() or '-'}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int, workload: dict) -> dict:
    shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
             if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output",
                     extra_link_sources=shims)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI check failed: {checked.stdout}\n{checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete branch-and-bound corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        expected = oracle(values)
        capacity = case.get("workspace_bytes", len(expected[1]))
        if expected[0] >= 0 and capacity < len(expected[1]):
            expected = (-2, b"")
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["output_capacity"] != capacity
                or record["workload"]["expected_result"] != expected[0]
                or record["measurement"]["observed_result"] != expected[0]
                or record["measurement"]["result_checksum"] != fnv1a(expected[1])):
            raise RuntimeError(f"recorder provenance/result mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "workload_records": len(records), "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/b/branch_and_bound_knapsack_solver")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    checker_input, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "branch-and-bound-knapsack-corpus.txt").write_text(checker_input, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                checker_input, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(report_path)
    return 0 if all(item["status"] == "passed" for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
