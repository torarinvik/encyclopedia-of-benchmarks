#!/usr/bin/env python3
"""Verify Excess-3 encoder ports against an independent decimal-digit oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_scalar_bytes_output import MAX_OUTPUT_BYTES, expected_output, fnv1a

ALGORITHM = "excess_3_code"
WORKLOAD_PATH = ROOT / "benchmarks/e/excess_3_code/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(value: int) -> tuple[int, bytes]:
    if type(value) is not int or not I64_MIN <= value <= I64_MAX:
        return -1, b""
    digits = str(0 if value < 0 else value)
    output = bytearray((ord("0"), ord("b")))
    for digit in digits:
        excess = ord(digit) - ord("0") + 3
        for bit in (3, 2, 1, 0):
            output.append(ord("1") if excess // (2**bit) % 2 else ord("0"))
    return len(output), bytes(output)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, int], tuple[int, bytes]] = {}

    def include(value: int, capacity: int) -> None:
        result, output = oracle(value)
        if result >= 0 and capacity < result:
            result, output = -2, b""
        if expected_output(value, ALGORITHM) != oracle(value):
            raise ValueError(f"runner oracle disagrees for scalar {value}")
        cases[(value, capacity)] = (result, output)

    for case in workload["cases"]:
        value = case["input_value"]
        result, output = oracle(value)
        if (case.get("expected_result") != result
                or case.get("expected_output") != output.decode("ascii")):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        include(value, case.get("output_capacity", len(output)))

    for value in range(-256, 2049):
        result, output = oracle(value)
        include(value, len(output))
        if output:
            include(value, len(output) - 1)
        include(value, 0)

    for value in (I64_MIN, I64_MIN + 1, -10**18, -1, 0, 1, I64_MAX - 1, I64_MAX):
        result, output = oracle(value)
        include(value, len(output))
        include(value, max(0, len(output) - 1))

    rng = random.Random(20261015)
    for _ in range(256):
        value = rng.randrange(I64_MIN, I64_MAX + 1)
        result, output = oracle(value)
        include(value, len(output))

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
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
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
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        value = case["input_value"]
        result, expected_bytes = oracle(value)
        expected_result = result
        if case.get("output_capacity", MAX_OUTPUT_BYTES) < result:
            expected_result, expected_bytes = -2, b""
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_value"] != value
                or record["workload"]["expected_result"] != expected_result
                or record["measurement"]["observed_result"] != expected_result
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_scalar_bytes_output/excess_3_code")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "excess-3-code-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} scalar/capacity cases, "
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
