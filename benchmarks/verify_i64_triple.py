#!/usr/bin/env python3
"""Check three-input signed 64-bit ports against independent exact oracles."""

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
from run_i64_triple import encode_case

ALGORITHM = "problem188"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(base: int, height: int, digits: int) -> int:
    """Use built-in modular exponentiation rather than the source recursion."""
    if (not 1 <= base <= 1_000_000_000 or base % 10 == 0
            or not 1 <= height <= 10_000 or not 1 <= digits <= 8):
        return -1
    modulus = 10**digits
    result = base
    for _ in range(height - 1):
        # The pinned helper's exponent==1 base case deliberately skips reduction.
        result = base if result == 1 else pow(base, result, modulus)
    return result


def corpus(workload: dict) -> tuple[str, int]:
    triples = {tuple(case["input_values"]) for case in workload["cases"]}
    bases = [1, 2, 3, 9, 10, 11, 25, 123, 999_999_999, 1_000_000_000]
    heights = [1, 2, 3, 4, 10, 100, 10_000]
    digits = [1, 2, 4, 8]
    triples.update((base, height, precision)
                   for base in bases for height in heights for precision in digits)
    rng = random.Random(20261015)
    for _ in range(96):
        base = rng.randint(1, 1_000_000_000)
        height = rng.randint(1, 10_000)
        precision = rng.randint(1, 8)
        triples.add((base, height, precision))
    triples.update(((I64_MIN, 2, 8), (I64_MAX, I64_MAX, 8), (3, 0, 8),
                    (3, 10_001, 8), (3, 3, 0), (3, 3, 9), (10, 3, 8)))

    for case in workload["cases"]:
        first, second, third, expected = encode_case(case, ALGORITHM)
        if expected != oracle(first, second, third):
            raise ValueError(f"published workload disagrees with independent oracle: {case['id']}")
    lines = [f"{len(triples)}\n"]
    for base, height, precision in sorted(triples):
        result = oracle(base, height, precision)
        lines.append(f"{base} {height} {precision} {result}\n")
    return "".join(lines), len(triples)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_triple")
    checker = manifest["binaries"]["i64_triple_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"i64 triple C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_triple.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                               text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        first, second, third, expected = encode_case(case, ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [first, second, third]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "i64_triple_call"
                or record["measurement"]["observed_result"] != expected
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_triple/problem188")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must not repeat")
    workload = json.loads((ROOT / "benchmarks/p/problem188/workload.json").read_text(encoding="utf-8"))
    if workload.get("algorithm") != ALGORITHM or workload.get("measurement", {}).get("comparison_model") != "i64_triple_call":
        parser.error("Problem 188 workload does not declare the i64 triple contract")
    data, case_count = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=min(args.jobs, len(args.languages))) as pool:
        futures = {pool.submit(verify, language, args.build_dir / language,
                               args.elisa_compiler if language == "elisa" else None,
                               data, case_count, workload): language
                   for language in args.languages}
        for future in as_completed(futures):
            language = futures[future]
            try:
                results.append(future.result())
            except Exception as error:
                failures.append({"algorithm": ALGORITHM, "language": language,
                                 "status": "failed", "error": str(error)})
    results.extend(failures)
    results.sort(key=lambda result: result["language"])
    report = {"schema_version": 1, "algorithm": ALGORITHM, "oracle_cases": case_count,
              "results": results, "failures": len(failures)}
    report_path = args.build_dir / "verification-report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
