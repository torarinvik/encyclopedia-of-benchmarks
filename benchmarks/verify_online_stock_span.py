#!/usr/bin/env python3
"""Verify monotone-stack stock-span ports against a backward-scan oracle."""

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

ALGORITHM = "online_stock_span"
MAX_DAYS = 4095


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_DAYS + 1
            or any(type(value) is not int for value in values)):
        return -1, b""
    count, prices = values[0], values[1:]
    if count != len(prices) or not 1 <= count <= MAX_DAYS:
        return -1, b""
    if any(not 1 <= price <= 100_000 for price in prices):
        return -1, b""
    spans = []
    for day, price in enumerate(prices):
        span = 1
        prior = day - 1
        while prior >= 0 and prices[prior] <= price:
            span += 1
            prior -= 1
        spans.append(span)
    return count, struct.pack("<" + "q" * count, *spans)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: list[int]) -> None:
        cases[tuple(values)] = oracle(values)

    for case in workload["cases"]:
        expected = oracle(case["input_values"])
        source = expected_output(case["input_values"], ALGORITHM)
        if expected[0] != case["expected_result"] or source != expected:
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["input_values"])

    for length in range(1, 7):
        for prices in product(range(1, 5), repeat=length):
            add([length, *prices])

    add([1, 0])
    add([1, 100_001])
    add([0])
    add([3, 10, 20])
    add([2, -1, 10])

    rng = random.Random(20261015)
    for _ in range(256):
        length = rng.randint(1, 512)
        add([length, *(rng.randint(1, 100_000) for _ in range(length))])
    for prices in (
        [5] * 1024,
        list(range(100_000, 100_000 - 1024, -1)),
        [1 + ((index * 7919) % 100_000) for index in range(1024)],
    ):
        add([len(prices), *prices])

    lines = [f"{len(cases) + 1}\n"]
    for values, (expected_count, output) in cases.items():
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {expected_count} {len(output)}{values_text} {encoded}\n")

    capacity_case = [1, 100]
    lines.append(f"{len(capacity_case)} -2 0 "
                 + " ".join(map(str, capacity_case)) + " -\n")
    return "".join(lines), len(cases) + 1


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/online_stock_span")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/o/online_stock_span/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "online-stock-span-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
