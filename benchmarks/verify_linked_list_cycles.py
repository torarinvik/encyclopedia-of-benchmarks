#!/usr/bin/env python3
"""Verify the portable linked-list cycle and cycle-entry implementations."""

from __future__ import annotations

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

ALGORITHMS = ("linked_list_has_cycle", "linked_list_cycle_entry")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: list[int], algorithm: str) -> int:
    malformed = -1 if algorithm == "linked_list_has_cycle" else -2
    if (not isinstance(values, list) or len(values) > 100000
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return malformed
    length = len(values)
    if any(value < -1 or value >= length for value in values):
        return malformed
    if length == 0:
        return 0 if algorithm == "linked_list_has_cycle" else -1
    visited: dict[int, int] = {}
    node = 0
    while node >= 0:
        if node in visited:
            return 1 if algorithm == "linked_list_has_cycle" else node
        visited[node] = len(visited)
        node = values[node]
    return 0 if algorithm == "linked_list_has_cycle" else -1


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values, algorithm)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with oracle: {algorithm}/{case['id']}")
        cases[tuple(values)] = expected

    for length in range(6):
        choices = [-1, *range(length)]
        for values in product(choices, repeat=length):
            cases[values] = oracle(list(values), algorithm)

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randrange(0, 65)
        choices = [-1, *range(length), -2, length, I64_MIN, I64_MAX]
        values = [rng.choice(choices) for _ in range(length)]
        cases[tuple(values)] = oracle(values, algorithm)

    max_length = 100000
    linear = [*range(1, max_length), -1]
    cycle = [*range(1, max_length), max_length // 2]
    cases[tuple(linear)] = oracle(linear, algorithm)
    cases[tuple(cycle)] = oracle(cycle, algorithm)

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array scalar check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {algorithm}/{case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/linked_list_cycles")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    root = args.build_dir.resolve()
    root.mkdir(parents=True, exist_ok=True)
    prepared = {}
    for algorithm in ALGORITHMS:
        workload = json.loads((ROOT / "benchmarks/l" / algorithm / "workload.json")
                              .read_text(encoding="utf-8"))
        data, count = corpus(workload, algorithm)
        corpus_path = root / f"{algorithm}-corpus.txt"
        corpus_path.write_text(data, encoding="utf-8")
        prepared[algorithm] = (workload, data, count)

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm, (workload, data, count) in prepared.items():
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      root / algorithm / language, args.elisa_compiler,
                                      data, count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)

    report = {"algorithms": list(ALGORITHMS),
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = root / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
