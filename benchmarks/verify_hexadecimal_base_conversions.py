#!/usr/bin/env python3
"""Verify hexadecimal-to-binary and hexadecimal-to-octal ports against Python integers."""

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
from run_i64_array_bytes_output import fnv1a

ALGORITHMS = ("hexadecimal_to_binary", "hexadecimal_to_octal")
I64_MAX = 2**63 - 1


def oracle(digits: list[int], algorithm: str) -> tuple[int, bytes]:
    if (not isinstance(digits, list) or not 1 <= len(digits) <= 16
            or any(type(digit) is not int or digit not in range(16) for digit in digits)):
        return -1, b""
    value = 0
    for digit in digits:
        value = value * 16 + digit
    if value > I64_MAX:
        return -1, b""
    output = format(value, "b" if algorithm == "hexadecimal_to_binary" else "o").encode("ascii")
    return len(output), output


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        digits = case["input_values"]
        expected = oracle(digits, algorithm)
        if (case["expected_result"] != expected[0]
                or case.get("expected_output", "").encode("ascii") != expected[1]):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(digits)] = expected

    cases[()] = (-1, b"")
    for length in range(1, 4):
        for digits in product(range(16), repeat=length):
            value = 0
            for digit in digits:
                value = value * 16 + digit
            output = format(value, "b" if algorithm == "hexadecimal_to_binary" else "o").encode("ascii")
            cases[digits] = (len(output), output)
    cases[(7,) + (15,) * 15] = oracle([7] + [15] * 15, algorithm)
    cases[(4,) + (0,) * 15] = oracle([4] + [0] * 15, algorithm)
    for digits in ((16,), (-1,), (1, 16), (1, -1), (0,) * 17,
                   (8,) + (0,) * 15, (15,) * 16):
        cases[digits] = (-1, b"")
    rng = random.Random(20261014)
    for _ in range(512):
        digits = [rng.randrange(16) for _ in range(rng.randrange(1, 17))]
        cases[tuple(digits)] = oracle(digits, algorithm)

    records = sorted(cases.items())
    records.append(((1,), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for digits, (count, output) in records:
        values_text = "" if not digits else " " + " ".join(map(str, digits))
        output_hex = output.hex() if output else "-"
        lines.append(f"{len(digits)} {count} {len(output)}{values_text} {output_hex}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path,
           elisa_compiler: str | None, data: str, case_count: int,
           workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
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
        digits = case["input_values"]
        expected_count, expected_output = oracle(digits, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(digits)
                or record["workload"]["input_values"] != digits
                or record["workload"]["expected_result"] != expected_count
                or record["measurement"]["observed_result"] != expected_count
                or record["measurement"]["result_checksum"] != fnv1a(expected_output)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output")
    args = parser.parse_args()
    if (args.jobs < 1 or len(set(args.languages)) != len(args.languages)
            or len(set(args.algorithms)) != len(args.algorithms)):
        parser.error("jobs must be positive and selections must be unique")

    build_root = args.build_dir.resolve()
    build_root.mkdir(parents=True, exist_ok=True)
    jobs_to_run = []
    for algorithm in args.algorithms:
        workload = json.loads((ROOT / "benchmarks/h" / algorithm / "workload.json")
                              .read_text(encoding="utf-8"))
        data, case_count = corpus(algorithm, workload)
        algorithm_root = build_root / algorithm
        algorithm_root.mkdir(parents=True, exist_ok=True)
        (algorithm_root / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
        for language in args.languages:
            jobs_to_run.append((algorithm, language, algorithm_root / language,
                                data, case_count, workload))

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        pending = {executor.submit(verify, algorithm, language, directory, args.elisa_compiler,
                                   data, case_count, workload): (algorithm, language)
                   for algorithm, language, directory, data, case_count, workload in jobs_to_run}
        for job in as_completed(pending):
            algorithm, language = pending[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithms": list(args.algorithms), "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = build_root / "verification_hexadecimal_conversions.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
