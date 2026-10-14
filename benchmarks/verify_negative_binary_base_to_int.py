#!/usr/bin/env python3
"""Verify negative-binary-to-integer ports against arbitrary-precision folding."""

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

ALGORITHM = "negative_binary_base_to_int"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(bits: list[int]) -> int:
    if (not isinstance(bits, list) or not 1 <= len(bits) <= 63
            or any(type(bit) is not int or bit not in (0, 1) for bit in bits)):
        return -1
    value = 0
    for bit in bits:
        value = value * -2 + bit
        if not I64_MIN <= value <= I64_MAX:
            return -1
    return value


def encode_neg2(value: int) -> list[int]:
    if value == 0:
        return [0]
    digits = []
    while value:
        digit = value % 2
        digits.append(digit)
        value = (value - digit) // -2
    return digits[::-1]


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        bits = encode_case(case)
        expected = oracle(bits)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(bits)] = expected

    for length in range(13):
        for bits in product((0, 1), repeat=length):
            cases[bits] = oracle(list(bits))
    for value in (-2 * (4**31 - 1) // 3, -2 * (4**31 - 1) // 3 + 1,
                  -1, 0, 1, 2, (4**32 - 1) // 3, (4**32 - 1) // 3 - 1):
        bits = encode_neg2(value)
        if oracle(bits) != value:
            raise ValueError(f"negabinary encoder failed to round-trip {value}")
        cases[tuple(bits)] = value
    for bits in ((), (2,), (-1, 0), (0,) * 64):
        cases[bits] = oracle(list(bits))
    rng = random.Random(20261014)
    for _ in range(1024):
        bits = [rng.randrange(2) for _ in range(rng.randrange(1, 64))]
        cases[tuple(bits)] = oracle(bits)
        if rng.randrange(2):
            invalid = list(bits)
            invalid[rng.randrange(len(invalid))] = 2
            cases[tuple(invalid)] = -1

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for bits, expected in records:
        suffix = "" if not bits else " " + " ".join(map(str, bits))
        lines.append(f"{len(bits)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        bits = encode_case(case)
        expected = oracle(bits)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(bits)
                or record["workload"]["input_values"] != bits
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/negative_binary_base_to_int")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selections must be unique")
    root = args.build_dir.resolve()
    root.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/n/negative_binary_base_to_int/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (root / "negative_binary_base_to_int-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, root / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = root / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
