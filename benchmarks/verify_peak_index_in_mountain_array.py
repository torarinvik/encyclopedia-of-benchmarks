#!/usr/bin/env python3
"""Check mountain-peak search ports against a linear peak oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "peak_index_in_mountain_array"
MAX_ARRAY_LENGTH = 100000
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
WORKLOAD_PATH = ROOT / "benchmarks/p/peak_index_in_mountain_array/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_ARRAY_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    peak = max(range(len(values)), key=values.__getitem__)
    if (peak == 0 or peak + 1 == len(values)
            or any(values[index] >= values[index + 1] for index in range(peak))
            or any(values[index] <= values[index + 1] for index in range(peak, len(values) - 1))):
        return -1
    return peak


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    for length in range(3, 8):
        for selected in combinations(range(-3, 4), length):
            peak = selected[-1]
            lower = selected[:-1]
            for peak_index in range(1, length - 1):
                for left_values in combinations(lower, peak_index):
                    left_set = set(left_values)
                    right_values = tuple(value for value in lower if value not in left_set)
                    values = (*left_values, peak, *reversed(right_values))
                    cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randrange(3, 257)
        selected = sorted(rng.sample(range(-100000, 100001), length))
        peak_index = rng.randrange(1, length - 1)
        left_values = sorted(rng.sample(selected[:-1], peak_index))
        left_set = set(left_values)
        right_values = sorted((value for value in selected[:-1] if value not in left_set),
                              reverse=True)
        values = tuple((*left_values, selected[-1], *right_values))
        cases[values] = oracle(list(values))

    for values in (
        (I64_MIN, -1, I64_MAX, 0),
        (I64_MIN, I64_MAX - 1, I64_MAX, I64_MIN + 1),
        (-5, -1, -6),
        (0, 1000, 999, 998),
        (0, 1, 2, 5, 4),
        (), (0,), (0, 1), (0, 1, 2), (2, 1, 0),
        tuple(range(MAX_ARRAY_LENGTH + 1)),
    ):
        cases[values] = oracle(list(values))

    for case in workload["cases"]:
        values = tuple(encode_case(case, algorithm=ALGORITHM))
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
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
    checked = subprocess.run([checker], input=data, capture_output=True,
                              text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array-scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/peak_index_in_mountain_array")
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
