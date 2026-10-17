#!/usr/bin/env python3
"""Verify list-intersection ports against an identity-based oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import permutations
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "intersection_of_two_linked_lists"
MAX_LIST_LENGTH = 1024
MAX_INPUT_LENGTH = 2 + 2 * MAX_LIST_LENGTH
MAX_NODE_ID = 2**31 - 1
INVALID_RESULT = -2
NO_INTERSECTION = -1
WORKLOAD_PATH = ROOT / "benchmarks/i/intersection_of_two_linked_lists/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    first_length, second_length = values[:2]
    if (not 0 <= first_length <= MAX_LIST_LENGTH
            or not 0 <= second_length <= MAX_LIST_LENGTH
            or len(values) != 2 + first_length + second_length):
        return INVALID_RESULT
    first = values[2:2 + first_length]
    second = values[2 + first_length:]
    if any(not 0 <= node_id <= MAX_NODE_ID for node_id in first + second):
        return INVALID_RESULT
    second_positions = {node_id: index for index, node_id in enumerate(second)}
    for index, node_id in enumerate(first):
        if node_id in second_positions:
            return node_id
    return NO_INTERSECTION


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(first: tuple[int, ...], second: tuple[int, ...]) -> None:
        values = (len(first), len(second), *first, *second)
        cases[values] = oracle(list(values))

    first_prefixes = [items for length in range(3)
                      for items in permutations((0, 1, 2), length)]
    second_prefixes = [items for length in range(3)
                       for items in permutations((3, 4, 5), length)]
    shared_tails = [items for length in range(3)
                    for items in permutations((6, 7, 8), length)]
    for first_prefix in first_prefixes:
        for second_prefix in second_prefixes:
            for shared_tail in shared_tails:
                add((*first_prefix, *shared_tail), (*second_prefix, *shared_tail))

    rng = random.Random(20261015)
    for _ in range(512):
        first_prefix = tuple(rng.sample(range(0, 100_000), rng.randrange(0, 129)))
        second_prefix = tuple(rng.sample(range(100_000, 200_000), rng.randrange(0, 129)))
        shared_tail = tuple(rng.sample(range(200_000, 300_000), rng.randrange(0, 129)))
        add(first_prefix, shared_tail)
        add(second_prefix, shared_tail)
        add(first_prefix, second_prefix)

    add(tuple(range(1023)) + (MAX_NODE_ID,), tuple(range(1023, 2046)) + (MAX_NODE_ID,))
    add(tuple(range(1024)), tuple(range(1024, 2048)))
    add((0, MAX_NODE_ID), (1, MAX_NODE_ID))

    malformed = (
        (), (0,), (-1, 0), (0, -1), (MAX_LIST_LENGTH + 1, 0),
        (1, 1, 7), (0, 0, 7), (1, 1, -1, 7), (1, 1, 7, MAX_NODE_ID + 1),
        (MAX_LIST_LENGTH + 1, MAX_LIST_LENGTH, *([1] * (MAX_INPUT_LENGTH - 1))),
    )
    for values in malformed:
        cases[tuple(values)] = oracle(list(values))

    for case in workload["cases"]:
        values = tuple(encode_case(case, algorithm=ALGORITHM))
        if case.get("input_length") != len(values):
            raise ValueError(f"declared input length differs for {case['id']}")
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            raise ValueError(f"workload disagrees with identity oracle: {case['id']}")
        cases[values] = expected

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
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
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/intersection_of_two_linked_lists")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
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
