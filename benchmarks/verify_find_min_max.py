#!/usr/bin/env python3
"""Check find-minimum and find-maximum ports against Python's min/max oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHMS = ("find_min", "find_max")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_LENGTH = 512


def oracle(algorithm: str, values: list[int]) -> int:
    if (not isinstance(values, list)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        raise ValueError("input must be an array of signed 64-bit integers")
    if not values or len(values) > MAX_LENGTH:
        return -1
    return min(values) if algorithm == "find_min" else max(values)


def checker_corpus(algorithm: str, cases: dict[tuple[int, ...], int]) -> str:
    lines = [f"{len(cases)}\n"]
    for values, _ in sorted(cases.items()):
        expected = oracle(algorithm, list(values))
        serialized = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{serialized}\n")
    return "".join(lines)


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

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(records_path)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=algorithm)
        expected = oracle(algorithm, values)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/find_min_max")
    args = parser.parse_args()
    if (args.jobs < 1 or len(set(args.algorithms)) != len(args.algorithms)
            or len(set(args.languages)) != len(args.languages)):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {algorithm: json.loads((ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                                       .read_text(encoding="utf-8"))
                 for algorithm in args.algorithms}
    shared_cases: dict[tuple[int, ...], int] = {(): -1}
    for length in range(1, 6):
        for values in itertools.product(range(-2, 3), repeat=length):
            shared_cases[values] = 0
    boundary_values = [I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX]
    for value in boundary_values:
        shared_cases[(value,)] = 0
    for values in (tuple(boundary_values), tuple(reversed(boundary_values)),
                   tuple([I64_MAX] * MAX_LENGTH), tuple([I64_MIN] * MAX_LENGTH),
                   tuple(range(-MAX_LENGTH // 2, MAX_LENGTH // 2)),
                   (-1,), tuple([0] * (MAX_LENGTH + 1))):
        shared_cases[values] = 0
    rng = random.Random(20261014)
    for _ in range(512):
        values = tuple(rng.choice([I64_MIN, I64_MAX, -1, 0, 1, rng.getrandbits(64) - 2**63])
                       for _ in range(rng.randrange(0, MAX_LENGTH + 1)))
        shared_cases[values] = 0
    for algorithm, workload in workloads.items():
        for case in workload["cases"]:
            values = encode_case(case, algorithm=algorithm)
            expected = oracle(algorithm, values)
            if expected != case["expected_result"]:
                parser.error(f"workload oracle mismatch: {algorithm}/{case['id']}")
            shared_cases[tuple(values)] = 0

    data_by_algorithm = {algorithm: checker_corpus(algorithm, shared_cases) for algorithm in args.algorithms}
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language,
                                directory / algorithm / language, args.elisa_compiler,
                                data_by_algorithm[algorithm], len(shared_cases), workloads[algorithm]):
                (algorithm, language)
                for algorithm in args.algorithms for language in args.languages}
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {len(shared_cases)} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithms": args.algorithms,
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": {"os": platform.system(), "architecture": platform.machine()},
              "oracle_cases": len(shared_cases), "all_passed": not failures,
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.algorithms) * len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
