#!/usr/bin/env python3
"""Verify the Celsius conversion ports against exact rational arithmetic."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from fractions import Fraction
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "celsius_to_fahrenheit"
MIN_INPUT, MAX_INPUT = -1e100, 1e100
WORKLOAD_PATH = ROOT / "benchmarks/c/celsius_to_fahrenheit/workload.json"


def oracle(celsius: float) -> float:
    """Round the exact Celsius-to-Fahrenheit rational value to binary64."""
    return float(Fraction.from_float(celsius) * 9 / 5 + 32)


def matches(observed: float, expected: float, relative_tolerance: float,
            absolute_tolerance: float) -> bool:
    if not math.isfinite(observed):
        return False
    return abs(observed - expected) <= absolute_tolerance + relative_tolerance * abs(expected)


def corpus(workload: dict) -> tuple[str, int]:
    relative_tolerance = float(workload["measurement"]["relative_tolerance"])
    absolute_tolerance = float(workload["measurement"]["absolute_tolerance"])
    cases: dict[float, float] = {}

    def add(value: float) -> None:
        if not math.isfinite(value) or not MIN_INPUT <= value <= MAX_INPUT:
            raise ValueError(f"corpus input is outside the finite contract: {value!r}")
        cases[value] = oracle(value)

    for case in workload["cases"]:
        if len(case.get("input_values", [])) != 1:
            raise ValueError(f"workload case is not unary: {case['id']}")
        value = float(case["input_values"][0])
        expected = float(case["expected_result"])
        if not matches(expected, oracle(value), relative_tolerance, absolute_tolerance):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(value)

    for tick in range(-400, 401):
        add(tick / 4.0)

    rng = random.Random(20261015)
    for _ in range(512):
        add(rng.uniform(-1_000_000.0, 1_000_000.0))
    for exponent in range(-99, 101):
        magnitude = 10.0 ** exponent
        add(magnitude)
        add(-magnitude)
        if exponent < 100:
            add(3.141592653589793 * magnitude)
            add(-2.718281828459045 * magnitude)

    lines = [f"{len(cases)}\n"]
    for value, expected in sorted(cases.items()):
        lines.append(f"{value:.17g} {expected:.17g} {relative_tolerance:.17g} "
                     f"{absolute_tolerance:.17g}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_unary")
    checker = manifest["binaries"]["float64_unary_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"binary64 C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_float64_unary.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    relative_tolerance = float(workload["measurement"]["relative_tolerance"])
    absolute_tolerance = float(workload["measurement"]["absolute_tolerance"])
    for case, record in zip(workload["cases"], records):
        value = float(case["input_values"][0])
        expected = float(case["expected_result"])
        observed = float(record["measurement"]["observed_result"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [value]
                or record["workload"]["expected_result"] != expected
                or not matches(observed, oracle(value), relative_tolerance, absolute_tolerance)
                or record["measurement"]["result_relative_tolerance"] != relative_tolerance
                or record["measurement"]["result_absolute_tolerance"] != absolute_tolerance
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/celsius_to_fahrenheit")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
