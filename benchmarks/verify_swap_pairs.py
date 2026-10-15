#!/usr/bin/env python3
"""Check adjacent-pair list swapping against an independent array oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "swap_pairs"
MAX_LENGTH = 1024
I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def oracle(values: tuple[int, ...]) -> tuple[int, bytes]:
    if len(values) > MAX_LENGTH or any(type(value) is not int or not I32_MIN <= value <= I32_MAX
                                       for value in values):
        return -1, b""
    swapped = []
    for index in range(0, len(values), 2):
        if index + 1 < len(values):
            swapped.extend((values[index + 1], values[index]))
        else:
            swapped.append(values[index])
    encoded = struct.pack("<" + "i" * len(swapped), *swapped) if swapped else b""
    return len(swapped), encoded


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        expected = oracle(values)
        if expected != expected_output(list(values), ALGORITHM):
            raise ValueError("independent pair-swap oracle disagrees with recorder oracle")
        cases[values] = expected

    for length in range(7):
        for values in product((-2, -1, 0, 1, 2), repeat=length):
            add(tuple(values))

    rng = random.Random(20261020)
    pool = (I32_MIN, I32_MIN + 1, -1000, -1, 0, 1, 1000, I32_MAX - 1, I32_MAX)
    for _ in range(768):
        length = rng.randrange(0, MAX_LENGTH + 1)
        add(tuple(rng.choice(pool) for _ in range(length)))
    add(tuple(rng.choice(pool) for _ in range(MAX_LENGTH)))
    for values in ((I32_MIN - 1,), (I32_MAX + 1,), (0,) * (MAX_LENGTH + 1)):
        add(values)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, _output = oracle(values)
        if result != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)

    records = sorted(cases.items())
    records.append(((1, 2), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(records_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected, _expected_bytes = oracle(tuple(values))
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"result/provenance mismatch in {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path),
            "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/swap_pairs")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload_path = ROOT / "benchmarks/s/swap_pairs/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "swap-pairs-corpus.txt").write_text(data, encoding="utf-8")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
