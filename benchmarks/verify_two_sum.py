#!/usr/bin/env python3
"""Check two-sum ports against an independent first-pair oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "two_sum"
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
MAX_VALUES = 256


def oracle(values: list[int]) -> int:
    if (not values or len(values) > MAX_VALUES + 1
            or any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values)):
        return -2
    target, numbers = values[0], values[1:]
    first_index: dict[int, int] = {}
    for right_index, value in enumerate(numbers):
        complement = target - value
        if complement in first_index:
            return first_index[complement] * 256 + right_index
        first_index.setdefault(value, right_index)
    return -1


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def include(values: tuple[int, ...] | list[int]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))

    # Exhaust every target and value sequence over a small signed alphabet.
    for value_count in range(6):
        for numbers in product(range(-2, 3), repeat=value_count):
            for target in range(-4, 5):
                include((target, *numbers))

    boundary_cases = [
        (),
        (0,),
        (0, I32_MIN, I32_MAX),
        (-1, I32_MIN, I32_MAX),
        (I32_MIN, I32_MAX, -1),
        (I32_MAX, I32_MIN, -1),
        (I32_MAX + 1, 1),
        (0, I32_MIN - 1),
        (0, I32_MAX + 1),
        (0, *range(1, MAX_VALUES + 2)),
    ]
    for values in boundary_cases:
        include(values)

    rng = random.Random(20261014)
    for _ in range(512):
        value_count = rng.randrange(MAX_VALUES + 1)
        numbers = [rng.randrange(-100_000, 100_001) for _ in range(value_count)]
        if value_count >= 2 and rng.randrange(2) == 0:
            left, right = rng.sample(range(value_count), 2)
            target = numbers[left] + numbers[right]
        else:
            target = rng.randrange(-200_000, 200_001)
        include((target, *numbers))

    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if case["expected_result"] != expected:
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
        raise RuntimeError(f"C ABI oracle check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("array-scalar checker did not consume the full corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
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
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/t/two_sum/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/two_sum")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload = json.loads((ROOT / "benchmarks/t/two_sum/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "two_sum-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} inputs and "
                      f"{result['workload_records']} workload records", flush=True)
            results.append(result)

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(args.languages)
                      and all(result["status"] == "passed" for result in results),
        "corpus_sha256": sha256_file(corpus_path),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda result: result["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
