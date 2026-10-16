#!/usr/bin/env python3
"""Verify scalar-to-byte-buffer ports against independent oracles."""

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
from run_i64_scalar_bytes_output import MAX_OUTPUT_BYTES, expected_output

ALGORITHMS = ("decimal_to_binary", "decimal_to_octal", "decimal_to_hexadecimal", "integer_to_roman",
              "pascal_triangle_row", "floyd_triangle", "harmonic_series", "butterfly_pattern",
              "magicdiamondpattern")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def corpus(workload: dict) -> tuple[str, int]:
    encoding = workload.get("input", {}).get("encoding", workload.get("input", {}).get("radix", 2))
    capacity_error_result = workload.get("output", {}).get("capacity_error_result", -2)
    cases: dict[tuple[int, int], tuple[int, bytes]] = {}

    def add(value: int, capacity: int | None = None,
            capacity_error: int | None = None) -> None:
        result, output = expected_output(value, encoding)
        selected_capacity = (MAX_OUTPUT_BYTES if result < 0 else result) if capacity is None else capacity
        if result >= 0 and selected_capacity < result:
            result, output = (capacity_error_result if capacity_error is None else capacity_error), b""
        cases[(value, selected_capacity)] = (result, output)

    for case in workload["cases"]:
        value = case["input_value"]
        expected_result, output = expected_output(value, encoding)
        output_capacity = case.get("output_capacity", case.get("workspace_bytes",
                                                                len(output) or MAX_OUTPUT_BYTES))
        if type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_BYTES:
            raise ValueError(f"invalid output capacity in {case['id']}")
        if expected_result >= 0 and output_capacity < len(output):
            expected_result = case.get("capacity_error_result", capacity_error_result)
            output = b""
        expected_matches = (case.get("expected_output_hex") == output.hex()
                            if "expected_output_hex" in case
                            else case.get("expected_output") == output.decode("ascii"))
        if case["expected_result"] != expected_result or not expected_matches:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(value, output_capacity, case.get("capacity_error_result"))

    for value in range(4097):
        add(value)
    rng = random.Random(20261014)
    for _ in range(512):
        add(rng.randrange(0, I64_MAX + 1))
    for value in (I64_MIN, I64_MIN + 1, -1024, -2, -1, 0, 1, 2, I64_MAX - 1, I64_MAX):
        add(value)
    capacity_cases = ((0, 1, 7, 33, I64_MAX) if encoding == "pascal_triangle_row"
                      else (0, 1, 7, 90, I64_MAX) if encoding == "floyd_triangle"
                      else (0, 1, 7, 512, I64_MAX) if encoding == "harmonic_series"
                      else (0, 1, 45, 46, I64_MAX) if encoding == "butterfly_pattern"
                      else (0, 1, 7, 45, I64_MAX) if encoding == "magicdiamondpattern"
                      else (0, 1, 7, I64_MAX))
    for value in capacity_cases:
        result, _ = expected_output(value, encoding)
        add(value, max(0, result - 1))

    lines = [f"{len(cases)}\n"]
    for (value, capacity), (result, output) in sorted(cases.items()):
        encoded = output.hex() if output else "-"
        lines.append(f"{value} {result} {capacity} {len(output)} {encoded}\n")
    return "".join(lines), len(cases)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
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
    encoding = workload.get("input", {}).get("encoding", workload.get("input", {}).get("radix", 2))
    capacity_error_result = workload.get("output", {}).get("capacity_error_result", -2)
    for case, record in zip(workload["cases"], records):
        value = case["input_value"]
        required_result, required_output = expected_output(value, encoding)
        output_capacity = case.get("output_capacity", case.get("workspace_bytes",
                                                                  len(required_output) or MAX_OUTPUT_BYTES))
        expected = (case.get("capacity_error_result", capacity_error_result)
                    if output_capacity < len(required_output) else required_result)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] is not None
                or record["workload"]["input_value"] != value
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_scalar_bytes_output")
    args = parser.parse_args()
    if (args.jobs < 1 or len(set(args.languages)) != len(args.languages)
            or len(set(args.algorithms)) != len(args.algorithms)):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {
        algorithm: json.loads((ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                              .read_text(encoding="utf-8"))
        for algorithm in args.algorithms
    }

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm, workload in workloads.items():
            data, case_count = corpus(workload)
            algorithm_directory = directory / algorithm
            algorithm_directory.mkdir(parents=True, exist_ok=True)
            (algorithm_directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      algorithm_directory / language, args.elisa_compiler,
                                      data, case_count, workload)
                jobs[job] = (algorithm, language, case_count)
        for job in as_completed(jobs):
            algorithm, language, case_count = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle values, "
                  f"{result['workload_records']} workload records", flush=True)
    all_passed = not failures and len(results) == len(args.algorithms) * len(args.languages)
    report = {"algorithms": args.algorithms, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": all_passed,
              "results": sorted(results, key=lambda row: (row["algorithm"], row["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if all_passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
