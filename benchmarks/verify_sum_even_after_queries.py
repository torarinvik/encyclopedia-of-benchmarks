#!/usr/bin/env python3
"""Verify the query-update ports against a recomputing even-sum oracle."""

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
from run_i64_array_bytes_output import expected_output

ALGORITHM = "sum_even_after_queries"
MAX_NUMBERS = 1000
MAX_QUERIES = 1000


def pack(numbers: list[int], queries: list[tuple[int, int]]) -> list[int]:
    return [len(numbers), len(queries), *numbers,
            *(value for query in queries for value in query)]


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 5 or len(values) > 4002
            or any(type(value) is not int for value in values)):
        return -1, b""
    number_count, query_count = values[:2]
    if not 1 <= number_count <= MAX_NUMBERS or not 1 <= query_count <= MAX_QUERIES:
        return -1, b""
    if len(values) != 2 + number_count + 2 * query_count:
        return -1, b""
    numbers = values[2:2 + number_count]
    if any(not 1 <= value <= 1000 for value in numbers):
        return -1, b""
    queries = list(zip(values[2 + number_count::2], values[3 + number_count::2]))
    if (len(queries) != query_count
            or any(not -1000 <= delta <= 1000 or not 0 <= index < number_count
                   for delta, index in queries)):
        return -1, b""

    working = list(numbers)
    answers = []
    for delta, index in queries:
        working[index] += delta
        answers.append(sum(value for value in working if value % 2 == 0))
    import struct

    return query_count, struct.pack("<" + "i" * len(answers), *answers)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: list[int]) -> None:
        cases[tuple(values)] = oracle(values)

    for case in workload["cases"]:
        result, output = oracle(case["input_values"])
        if (result != case["expected_result"]
                or output.hex() != case.get("expected_output_hex", "")):
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["input_values"])

    add([0, 1, 1, 0])
    add([1, 0, 1])
    add([1, 1, 5])
    add([1, 1, 5, 1])
    add([1, 1, 0, 0, 0])
    add([1, 1, 1, 1001, 0])
    add([1, 1, 1, -1001, 0])
    add([1, 1, 1, 1, -1])
    add([1, 1, 1, 1, 1])
    add([1001, 1, 1, 0, 0])
    add([1, 1001, 1])

    # Enumerate short arrays and all one/two-query sequences over small signed deltas.
    for number_count in range(1, 4):
        options = [(delta, index) for index in range(number_count)
                   for delta in range(-2, 3)]
        for numbers in product(range(1, 4), repeat=number_count):
            for query_count in (1, 2):
                for queries in product(options, repeat=query_count):
                    add(pack(list(numbers), list(queries)))

    rng = random.Random(20261015)
    for _ in range(384):
        number_count = rng.randint(1, 128)
        query_count = rng.randint(1, 192)
        numbers = [rng.randint(1, 1000) for _ in range(number_count)]
        queries = [(rng.randint(-1000, 1000), rng.randrange(number_count))
                   for _ in range(query_count)]
        add(pack(numbers, queries))

    large_numbers = [((index * 71) % 1000) + 1 for index in range(MAX_NUMBERS)]
    large_queries = [((index * 43) % 2001 - 1000, (index * 101) % MAX_NUMBERS)
                     for index in range(MAX_QUERIES)]
    add(pack(large_numbers, large_queries))

    lines = [f"{len(cases) + 1}\n"]
    for values, (expected_count, output) in cases.items():
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {expected_count} {len(output)}{values_text} {encoded}\n")

    # The shared checker supplies zero capacity when the expected output is empty.
    # A valid one-query call must therefore report the ABI's insufficient-capacity result.
    capacity_case = [1, 1, 2, 0, 0]
    lines.append(f"{len(capacity_case)} -2 0 "
                 + " ".join(map(str, capacity_case)) + " -\n")
    return "".join(lines), len(cases) + 1


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/sum_even_after_queries")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/s/sum_even_after_queries/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "sum-even-after-queries-corpus.txt").write_text(data, encoding="utf-8")

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
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
