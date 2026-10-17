#!/usr/bin/env python3
"""Verify both Detect Capital implementations against an ASCII-case oracle."""

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

ALGORITHMS = ("detect_capital_usage", "detect_capital_usage_scan")
MAX_LENGTH = 1024


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not 1 <= value <= 127 for value in values)):
        return -1
    if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in values):
        return -1
    upper = [65 <= value <= 90 for value in values]
    return int(not values or all(upper) or not any(upper)
               or (upper[0] and not any(upper[1:])))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case, algorithm=workload['algorithm'])
        if case.get("input_length") != len(values):
            raise ValueError(f"declared input length differs for {case['id']}")
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with capitalization oracle: {case['id']}")
        cases[tuple(values)] = expected

    # Exhaust all upper/lower patterns through length 14.
    for length in range(15):
        for values in product((65, 97), repeat=length):
            items = list(values)
            cases[tuple(items)] = oracle(items)

    for values in ([0], [-1], [128], [65] * (MAX_LENGTH + 1),
                   [65] * MAX_LENGTH, [65, *([97] * (MAX_LENGTH - 1))]):
        cases[tuple(values)] = oracle(values)

    rng = random.Random(20261020)
    for _ in range(512):
        length = rng.randrange(MAX_LENGTH + 1)
        values = [rng.choice((65, 66, 97, 98)) for _ in range(length)]
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
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/detect_capital_usage")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {algorithm: json.loads((ROOT / "benchmarks/d" / algorithm / "workload.json")
                                       .read_text(encoding="utf-8")) for algorithm in ALGORITHMS}
    first_cases = workloads[ALGORITHMS[0]]["cases"]
    if workloads[ALGORITHMS[1]]["cases"] != first_cases:
        raise ValueError("capitalization variants must publish identical workloads")
    data, case_count = corpus(workloads[ALGORITHMS[0]])
    (directory / "detect_capital_usage-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language,
                                directory / algorithm / language, args.elisa_compiler,
                                data, case_count, workloads[algorithm]): (algorithm, language)
                for algorithm in ALGORITHMS for language in args.languages}
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithms": list(ALGORITHMS), "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
