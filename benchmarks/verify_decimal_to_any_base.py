#!/usr/bin/env python3
"""Verify decimal-to-base ports against independent repeated division."""

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
from run_i64_array_bytes_output import fnv1a

ALGORITHMS = ("decimal_to_any_base", "decimal_to_any_using_stack", "any_base_to_any_base",
              "base_neg2_conversion")
DEFAULT_ALGORITHM = "decimal_to_any_base"
I64_MAX = 2**63 - 1
ALPHABET = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def oracle(values: list[int], algorithm: str) -> tuple[int, bytes]:
    if algorithm == "base_neg2_conversion":
        if (not isinstance(values, list) or len(values) != 1 or type(values[0]) is not int
                or not -(2**63) <= values[0] < 2**63):
            return -1, b""
        number = values[0]
        result = bytearray()
        while number:
            digit = number % 2
            result.append(ord("0") + digit)
            number = (number - digit) // -2
        if not result:
            result.append(ord("0"))
        result.reverse()
        encoded = bytes(result)
        return len(encoded), encoded
    if algorithm == "any_base_to_any_base":
        if (not isinstance(values, list) or not 3 <= len(values) <= 65
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        source_base, target_base = values[:2]
        if not 2 <= source_base <= 36 or not 2 <= target_base <= 36:
            return -1, b""
        number = 0
        for digit in values[2:]:
            if not 0 <= digit < source_base:
                return -1, b""
            number = number * source_base + digit
            if number > I64_MAX:
                return -1, b""
        result = bytearray()
        while number:
            number, digit = divmod(number, target_base)
            result.append(ALPHABET[digit])
        if not result:
            result.append(ord("0"))
        result.reverse()
        encoded = bytes(result)
        return len(encoded), encoded
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int for value in values)):
        return -1, b""
    number, base = values
    maximum_base = 16 if algorithm == "decimal_to_any_using_stack" else 36
    if not 0 <= number <= I64_MAX or not 2 <= base <= maximum_base:
        return -1, b""
    result = bytearray()
    while number:
        number, digit = divmod(number, base)
        result.append(ALPHABET[digit])
    if not result:
        result.append(ord("0"))
    result.reverse()
    encoded = bytes(result)
    return len(encoded), encoded


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        expected = oracle(values, algorithm)
        if (case["expected_result"] != expected[0]
                or case.get("expected_output", "").encode("ascii") != expected[1]):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(values)] = expected

    if algorithm == "any_base_to_any_base":
        for source_base in range(2, 37):
            for target_base in range(2, 37):
                for digit in {0, 1, source_base - 1}:
                    values = (source_base, target_base, digit)
                    cases[values] = oracle(list(values), algorithm)
        for source_base in range(2, 9):
            for target_base in range(2, 17):
                from itertools import product
                for digits in product(range(source_base), repeat=2):
                    values = (source_base, target_base, *digits)
                    cases[values] = oracle(list(values), algorithm)
        for target_base in range(2, 37):
            values = (2, target_base, *([1] * 63))
            cases[values] = oracle(list(values), algorithm)
        for values in ((1, 2, 0), (2, 1, 0), (2, 37, 0), (2, 2),
                       (2, 2, 2), (10, 10, -1), (2, 2, *([1] * 64))):
            cases[values] = oracle(list(values), algorithm)
        rng = random.Random(20261014)
        for _ in range(1024):
            source_base, target_base = rng.randrange(2, 37), rng.randrange(2, 37)
            digits = [rng.randrange(source_base) for _ in range(rng.randrange(1, 25))]
            values = (source_base, target_base, *digits)
            cases[values] = oracle(list(values), algorithm)
            if rng.randrange(2):
                cases[(source_base, target_base, *digits, source_base)] = (-1, b"")
        cases[(2, 2, 1, 0)] = (-2, b"")
    elif algorithm == "base_neg2_conversion":
        for number in range(-512, 513):
            cases[(number,)] = oracle([number], algorithm)
        boundaries = (-(2**63), -(2**63) + 1, -(2**62), -4611686018427387904,
                      -1, 0, 1, 2, 2**62, I64_MAX - 1, I64_MAX)
        for number in boundaries:
            cases[(number,)] = oracle([number], algorithm)
        for values in ((), (1, 2)):
            cases[values] = oracle(list(values), algorithm)
        rng = random.Random(20261014)
        for _ in range(1024):
            values = [rng.randrange(-(2**63), 2**63)]
            cases[tuple(values)] = oracle(values, algorithm)
        cases[(2,)] = (-2, b"")
    else:
        maximum_base = 16 if algorithm == "decimal_to_any_using_stack" else 36
        for base in range(2, maximum_base + 1):
            for number in range(129):
                cases[(number, base)] = oracle([number, base], algorithm)
            for number in (I64_MAX, I64_MAX - 1, 2**31 - 1, 2**32, 0):
                cases[(number, base)] = oracle([number, base], algorithm)
        for values in ((-1, 10), (1, 1), (1, maximum_base + 1), (0, 0), (), (1,), (1, 2, 3)):
            cases[values] = oracle(list(values), algorithm)
        rng = random.Random(20261014)
        for _ in range(1024):
            values = [rng.randrange(0, I64_MAX + 1), rng.randrange(2, maximum_base + 1)]
            cases[tuple(values)] = oracle(values, algorithm)
    # Deliberately request a zero-byte buffer for an output that needs multiple bytes.
    if algorithm in {"decimal_to_any_base", "decimal_to_any_using_stack"}:
        cases[(2, 2)] = (-2, b"")

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {count} {len(output)}{suffix} {output.hex() if output else '-'}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
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
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected_count, expected_output = oracle(values, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
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
    parser.add_argument("--algorithm", choices=ALGORITHMS, default=DEFAULT_ALGORITHM)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    algorithm = args.algorithm
    root = (args.build_dir or ROOT / "build/i64_array_bytes_output" / algorithm).resolve()
    root.mkdir(parents=True, exist_ok=True)
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload = json.loads((ROOT / "benchmarks" / letter / algorithm / "workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload, algorithm)
    (root / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language, root / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = root / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
