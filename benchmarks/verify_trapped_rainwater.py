#!/usr/bin/env python3
"""Verify all trapped-rainwater ports against a two-boundary oracle."""

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

from build_abi import EXTENSIONS, OPTIONAL_EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "trapped_rainwater"
ALGORITHMS = (ALGORITHM, "trapped_rainwater_two_pointer")
MAX_LENGTH = 4096
MAX_HEIGHT = 1_000_000


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_LENGTH
            or any(type(value) is not int or value < 0 or value > MAX_HEIGHT for value in values)):
        return -1
    left_maxima: list[int] = []
    highest = 0
    for value in values:
        highest = max(highest, value)
        left_maxima.append(highest)
    right_maxima = [0] * len(values)
    highest = 0
    for index in range(len(values) - 1, -1, -1):
        highest = max(highest, values[index])
        right_maxima[index] = highest
    return sum(min(left_maxima[index], right_maxima[index]) - value
               for index, value in enumerate(values))


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case, algorithm=algorithm)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with the water-volume oracle: {case['id']}")
        cases[tuple(values)] = expected

    for length in range(8):
        for values in product(range(4), repeat=length):
            items = list(values)
            cases[tuple(items)] = oracle(items)

    boundary_cases = [[], [0], [MAX_HEIGHT], [-1], [MAX_HEIGHT + 1],
                      [0, -1, 0], [0, MAX_HEIGHT + 1, 0],
                      [0] * (MAX_LENGTH + 1),
                      [MAX_HEIGHT, *([0] * (MAX_LENGTH - 2)), MAX_HEIGHT]]
    for length in (16, 17):
        boundary_cases.append([MAX_HEIGHT, *([0] * (length - 2)), MAX_HEIGHT])
        for invalid in (-(1 << 63), (1 << 63) - 1):
            boundary_cases.append([invalid] + [0] * (length - 1))
            boundary_cases.append([0] * (length - 1) + [invalid])
    if algorithm == "trapped_rainwater_two_pointer":
        # Put an invalid value at each position, including where the pointers meet.
        for profile in ([MAX_HEIGHT, 2, 1, 2, MAX_HEIGHT], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1]):
            for index in range(len(profile)):
                for invalid in (-(1 << 63), (1 << 63) - 1):
                    boundary_cases.append([*profile[:index], invalid, *profile[index + 1:]])
    for values in boundary_cases:
        cases[tuple(values)] = oracle(values)

    rng = random.Random(20261016)
    for _ in range(512):
        values = [rng.randrange(0, 1001) for _ in range(rng.randrange(0, 258))]
        cases[tuple(values)] = oracle(values)
    for _ in range(32):
        values = [rng.choice([0, 1, 2, MAX_HEIGHT]) for _ in range(rng.randrange(0, 1025))]
        cases[tuple(values)] = oracle(values)

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
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS | OPTIONAL_EXTENSIONS,
                        default=list(EXTENSIONS))
    parser.add_argument("--algorithm", choices=ALGORITHMS, default=ALGORITHM)
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    algorithm = args.algorithm
    directory = (args.build_dir or ROOT / "build" / algorithm).resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload_path = ROOT / "benchmarks/t" / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload, algorithm)
    (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
