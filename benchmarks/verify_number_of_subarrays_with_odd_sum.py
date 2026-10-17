#!/usr/bin/env python3
"""Check odd-sum subarray counts against a direct interval oracle."""

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

ALGORITHM = "number_of_subarrays_with_odd_sum"
MAX_LENGTH = 100000
MODULUS = 1_000_000_007
MIN_VALUE = -(2**31)
MAX_VALUE = 2**31 - 1


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE for value in values)):
        return -1
    if len(values) <= 256:
        odd_count = 0
        for start in range(len(values)):
            total = 0
            for end in range(start, len(values)):
                total += values[end]
                if total % 2 != 0:
                    odd_count += 1
        return odd_count % MODULUS
    even_prefixes = 1
    odd_prefixes = 0
    parity = 0
    result = 0
    for value in values:
        if value % 2 != 0:
            parity = 1 - parity
        if parity == 0:
            result += odd_prefixes
            even_prefixes += 1
        else:
            result += even_prefixes
            odd_prefixes += 1
    return result % MODULUS


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
        cases[tuple(values)] = expected

    alphabet = (-1, 0, 2)
    for length in range(9):
        for values in product(alphabet, repeat=length):
            cases[values] = oracle(list(values))

    cases[(1,) * MAX_LENGTH] = oracle([1] * MAX_LENGTH)
    cases[(MIN_VALUE, 1, MAX_VALUE)] = oracle([MIN_VALUE, 1, MAX_VALUE])
    malformed = [
        (MIN_VALUE - 1,),
        (MAX_VALUE + 1,),
    ]
    cases.update({values: oracle(list(values)) for values in malformed})

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randrange(65)
        values = tuple(rng.randrange(MIN_VALUE, MAX_VALUE + 1) for _ in range(length))
        cases[values] = oracle(list(values))

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(
        ALGORITHM,
        language,
        directory,
        compiler=elisa_compiler if language == "elisa" else None,
        with_checker=True,
        family="i64_array_scalar",
    )
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run(
        [checker], input=data, capture_output=True, text=True, timeout=120
    )
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [
            sys.executable,
            str(ROOT / "benchmarks/run_i64_array_scalar.py"),
            "--build-manifest", str(directory / "build.json"),
            "--samples", "1",
            "--warmups", "0",
            "--repetitions", "1",
            "--output", str(output),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=120,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")

    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/number_of_subarrays_with_odd_sum")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(
        (ROOT / "benchmarks/n/number_of_subarrays_with_odd_sum/workload.json")
        .read_text(encoding="utf-8")
    )
    data, case_count = corpus(workload)
    (directory / "oracle-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(
                verify,
                language,
                directory / ALGORITHM / language,
                args.elisa_compiler,
                data,
                case_count,
                workload,
            ): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(
                f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                f"{result['workload_records']} workload records",
                flush=True,
            )

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "results": sorted(results, key=lambda item: item["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
