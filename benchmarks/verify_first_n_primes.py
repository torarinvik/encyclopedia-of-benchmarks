#!/usr/bin/env python3
"""Verify first-N-primes byte-output ports against an independent oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "first_n_primes"
MAX_COUNT = 20
MAX_OUTPUT = 63
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(number_of_primes: int) -> tuple[int, bytes]:
    if type(number_of_primes) is not int or not 0 <= number_of_primes <= MAX_COUNT:
        return -1, b""
    primes = []
    candidate = 2
    while len(primes) < number_of_primes:
        divisor = 2
        while divisor <= candidate // divisor and candidate % divisor != 0:
            divisor += 1
        if divisor > candidate // divisor:
            primes.append(str(candidate))
        candidate += 1
    output = ",".join(primes).encode("ascii")
    if len(output) > MAX_OUTPUT:
        raise ValueError(f"prime list exceeds the output bound for count {number_of_primes}")
    return len(output), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, int], tuple[int, bytes]] = {}

    def add(value: int, capacity: int) -> None:
        result, output = oracle(value)
        if result >= 0 and capacity < result:
            result, output = -2, b""
        cases[(value, capacity)] = (result, output)

    for case in workload["cases"]:
        result, output = oracle(case["input_value"])
        if (case["expected_result"] != result
                or case["expected_output"].encode("ascii") != output):
            raise ValueError(f"published workload disagrees with prime oracle: {case['id']}")
        add(case["input_value"], MAX_OUTPUT)

    for value in range(MAX_COUNT + 1):
        result, _ = oracle(value)
        add(value, result)
        if result > 0:
            add(value, result - 1)

    for value in (I64_MIN, I64_MIN + 1, -1, MAX_COUNT + 1, I64_MAX - 1, I64_MAX):
        add(value, MAX_OUTPUT)

    records = [(value, result, capacity, len(output), output)
               for (value, capacity), (result, output) in sorted(cases.items())]
    lines = [f"{len(records)}\n"]
    for value, result, capacity, output_length, output in records:
        encoded = output.hex() if output else "-"
        lines.append(f"{value} {result} {capacity} {output_length} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_scalar_bytes_output")
    checker = manifest["binaries"]["i64_scalar_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"scalar byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_scalar_bytes_output.py"),
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
        value = case["input_value"]
        expected, expected_output = oracle(value)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_value"] != value
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or record["measurement"]["result_checksum"] != fnv1a(expected_output)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/first_n_primes")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/f/first_n_primes/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "first-n-primes-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle cases, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return int(bool(failures) or len(results) != len(args.languages))


if __name__ == "__main__":
    raise SystemExit(main())
