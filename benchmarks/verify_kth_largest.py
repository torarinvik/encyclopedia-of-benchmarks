#!/usr/bin/env python3
"""Verify kth-largest quickselect and full-sort ports against a sorting oracle."""

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

ALGORITHMS = ("kth_largest_element", "kth_largest_by_sort")
MAX_LENGTH = 512
I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_LENGTH + 1
            or any(type(value) is not int for value in values)):
        return -1
    k, array = values[0], values[1:]
    if (not 1 <= k <= len(array)
            or any(not I32_MIN <= value <= I32_MAX for value in array)):
        return -1
    return sorted(array, reverse=True)[k - 1]


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    if workload.get("algorithm") != algorithm:
        raise ValueError(f"workload does not describe {algorithm}")
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {algorithm}/{case['id']}")
        cases[tuple(values)] = expected

    for length in range(1, 6):
        for array in product(range(-2, 3), repeat=length):
            for k in range(1, length + 1):
                packed = (k, *array)
                cases[packed] = oracle(list(packed))

    boundaries = (I32_MIN, I32_MIN + 1, -1, 0, 1, I32_MAX - 1, I32_MAX)
    for length in range(1, 5):
        for array in product(boundaries, repeat=length):
            for k in range(1, length + 1):
                packed = (k, *array)
                cases[packed] = oracle(list(packed))

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randint(1, 128)
        array = [rng.randint(I32_MIN, I32_MAX) for _ in range(length)]
        k = rng.randint(1, length)
        packed = (k, *array)
        cases[packed] = oracle(list(packed))

    invalid = [[], [0], [0, 1], [-1, 1], [2, 1], [1, I32_MAX + 1],
               [1, I32_MIN - 1], [1, *([1] * (MAX_LENGTH + 1))]]
    for values in invalid:
        cases[tuple(values)] = -1

    lines = [str(len(cases)) + "\n"]
    for values, expected in sorted(cases.items()):
        lines.append(f"{len(values)} {expected} " + " ".join(map(str, values)) + "\n")
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
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/kth_largest")
    args = parser.parse_args()
    if (args.jobs < 1 or len(set(args.languages)) != len(args.languages)
            or len(set(args.algorithms)) != len(args.algorithms)):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    jobs = {}
    for algorithm in args.algorithms:
        workload = json.loads((ROOT / "benchmarks/k" / algorithm / "workload.json")
                              .read_text(encoding="utf-8"))
        data, case_count = corpus(workload, algorithm)
        (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
        for language in args.languages:
            jobs[(algorithm, language)] = (data, case_count, workload)

    results = {algorithm: [] for algorithm in args.algorithms}
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, algorithm, language,
                                  directory / algorithm / language, args.elisa_compiler,
                                  data, case_count, workload): (algorithm, language)
                   for (algorithm, language), (data, case_count, workload) in jobs.items()}
        for future in as_completed(futures):
            algorithm, language = futures[future]
            try:
                result = future.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr)
                return 1
            results[algorithm].append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle cases, "
                  f"{result['workload_records']} workload records", flush=True)

    for algorithm, entries in results.items():
        report = {"algorithm": algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
                  "platform": platform.platform(), "results": sorted(entries, key=lambda item: item["language"])}
        report_path = directory / algorithm / "verification.json"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
