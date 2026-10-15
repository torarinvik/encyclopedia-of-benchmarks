#!/usr/bin/env python3
"""Check the maximum-full-bags greedy ports against a sorted-deficit oracle."""

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

ALGORITHM = "maximum_bags_with_full_capacity"
MAX_BAGS = 8_191
MAX_INPUT_LENGTH = 2 + 2 * MAX_BAGS


def encode_bag_case(case: dict) -> list[int]:
    if "input_values" in case:
        return encode_case(case)
    capacities = case["capacities"]
    rocks = case["rocks"]
    if len(capacities) != len(rocks):
        raise ValueError(f"capacity and rocks counts differ: {case['id']}")
    return [case["additional_rocks"], len(capacities), *capacities, *rocks]


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)
            or not 0 <= values[0] <= 1_000_000_000
            or not 0 <= values[1] <= MAX_BAGS):
        return -1
    count = values[1]
    if len(values) != 2 + 2 * count:
        return -1
    capacities = values[2:2 + count]
    rocks = values[2 + count:]
    if (any(not 1 <= capacity <= 100_000 for capacity in capacities)
            or any(not 0 <= amount <= capacity for amount, capacity in zip(rocks, capacities))):
        return -1
    remaining = values[0]
    full_bags = 0
    for deficit in sorted(capacity - amount for capacity, amount in zip(capacities, rocks)):
        if deficit > remaining:
            break
        remaining -= deficit
        full_bags += 1
    return full_bags


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = oracle(list(values))

    for case in workload["cases"]:
        values = tuple(encode_bag_case(case))
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
        add(values)

    def packed_deficits(budget: int, deficits: tuple[int, ...]) -> tuple[int, ...]:
        capacities = tuple(max(1, deficit) for deficit in deficits)
        rocks = tuple(capacity - deficit for capacity, deficit in zip(capacities, deficits))
        return (budget, len(deficits), *capacities, *rocks)

    for count in range(7):
        for deficits in product((0, 1, 2), repeat=count):
            for budget in range(9):
                add(packed_deficits(budget, deficits))

    add((0, 0))
    add((0, MAX_BAGS, *((1,) * MAX_BAGS), *((1,) * MAX_BAGS)))
    add((1_000_000_000, MAX_BAGS, *((100_000,) * MAX_BAGS), *((0,) * MAX_BAGS)))
    deficits = tuple((index * 7919) % 100_001 for index in range(MAX_BAGS))
    capacities = tuple(max(1, deficit) for deficit in deficits)
    rocks = tuple(capacity - deficit for capacity, deficit in zip(capacities, deficits))
    add((20_000, MAX_BAGS, *capacities, *rocks))
    malformed = [(), (-1, 0), (1_000_000_001, 0), (0, -1), (0, 1, 1),
                 (0, 1, 0, 0), (0, 1, 1, -1), (0, 1, 1, 2), (0, 8192)]
    for values in malformed:
        add(values)

    rng = random.Random(20261015)
    for _ in range(512):
        count = rng.randint(0, 2048)
        capacities = tuple(rng.randint(1, 100_000) for _ in range(count))
        rocks = tuple(rng.randint(0, capacity) for capacity in capacities)
        values = (rng.randint(0, 1_000_000_000), count, *capacities, *rocks)
        add(values)

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    extra_link_sources = (
        (ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
        if language == "elisa" else ()
    )
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar",
                     extra_link_sources=extra_link_sources)
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
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
        values = encode_bag_case(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/maximum_bags_with_full_capacity")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/m/maximum_bags_with_full_capacity/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "oracle-corpus.txt").write_text(data, encoding="utf-8")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
