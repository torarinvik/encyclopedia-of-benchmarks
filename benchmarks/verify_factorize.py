#!/usr/bin/env python3
"""Verify factorize ports against independent prime-power and capacity oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_scalar_bytes_output import fnv1a

ALGORITHM = "factorize"
MAX_INPUT = 1_000_005
MAX_OUTPUT = 63
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(value: int) -> tuple[int, bytes]:
    if type(value) is not int or not 0 <= value <= MAX_INPUT:
        return -1, b""
    if value <= 1:
        pairs = [(value, 1)]
    else:
        remaining = value
        divisor = 2
        pairs = []
        while divisor <= remaining // divisor:
            if remaining % divisor == 0:
                exponent = 0
                while remaining % divisor == 0:
                    remaining //= divisor
                    exponent += 1
                pairs.append((divisor, exponent))
            divisor += 1
        if remaining > 1:
            pairs.append((remaining, 1))
    output = b"".join(struct.pack("<II", factor, exponent)
                     for factor, exponent in pairs)
    if len(output) > MAX_OUTPUT:
        raise ValueError(f"oracle output exceeds the ABI limit for input {value}")
    return len(output), output


def corpus(workload: dict) -> tuple[str, int]:
    values = set(range(4097))
    values.update((2**20, 3**12, 5**8, 999_983, MAX_INPUT))
    rng = random.Random(20261016)
    values.update(rng.randint(0, MAX_INPUT) for _ in range(512))

    for case in workload["cases"]:
        result, output = oracle(case["input_value"])
        capacity = case.get("output_capacity", len(output) or MAX_OUTPUT)
        if capacity < len(output):
            result, output = case.get("capacity_error_result", -2), b""
        if (case["expected_result"] != result
                or case.get("expected_output_hex") != output.hex()):
            raise ValueError(f"published workload disagrees with factorization oracle: {case['id']}")
        values.add(case["input_value"])

    records = []
    for value in sorted(values):
        result, output = oracle(value)
        if result < 0:
            records.append((value, result, MAX_OUTPUT, 0, b""))
            continue
        records.append((value, result, len(output), len(output), output))
        records.append((value, -2, len(output) - 1, 0, b""))

    for value in (I64_MIN, I64_MIN + 1, -1, MAX_INPUT + 1, MAX_INPUT + 2,
                  I64_MAX - 1, I64_MAX):
        records.append((value, -1, MAX_OUTPUT, 0, b""))
    records.sort(key=lambda record: (record[0], record[2], record[1]))
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
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=90)
    if checked.returncode:
        raise RuntimeError(f"scalar byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_scalar_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=90)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        value = case["input_value"]
        result, output = oracle(value)
        capacity = case.get("output_capacity", len(output) or MAX_OUTPUT)
        if capacity < len(output):
            result, output = case.get("capacity_error_result", -2), b""
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_value"] != value
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or record["measurement"]["result_checksum"] != fnv1a(output)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/factorize")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/f/factorize/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "factorize-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle/capacity cases, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda row: row["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
