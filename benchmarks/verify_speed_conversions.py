#!/usr/bin/env python3
"""Verify speed conversion ports through the float64_pair ABI."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_pair import encode_case, matches

ALGORITHM = "speed_conversions"
INVALID = -1.0
MAX_SPEED = 1_000_000.0
FACTORS = (1.0, 3.6, 1.609344, 1.852)
INVERSE_FACTORS = (1.0, 0.277777778, 0.621371192, 0.539956803)


def oracle(speed: float, route: float) -> float:
    """Apply the pinned source-unit factor and destination inverse factor."""
    if (not math.isfinite(speed) or not math.isfinite(route)
            or not 0.0 <= speed <= MAX_SPEED or not 0.0 <= route <= 15.0
            or not route.is_integer()):
        return INVALID
    source, destination = divmod(int(route), 4)
    return round(speed * FACTORS[source] * INVERSE_FACTORS[destination], 3)


def corpus(workload: dict) -> tuple[str, int]:
    relative = float(workload["measurement"].get(
        "relative_tolerance", workload["measurement"].get("input_scaled_tolerance", 0.0)))
    cases: dict[tuple[float, float], float] = {}

    def add(speed: float, route: float) -> None:
        expected = oracle(speed, route)
        cases[(speed, route)] = expected

    for case in workload["cases"]:
        speed, route, expected = encode_case(case, relative, ALGORITHM)
        oracle_result = oracle(speed, route)
        if not matches(expected, oracle_result, relative, speed, route):
            raise ValueError(f"workload disagrees with independent conversion oracle: {case['id']}")
        cases[(speed, route)] = oracle_result

    # Exercise every route at zero, ordinary, and maximum speeds, including identities.
    for route in range(16):
        for speed in (0.0, 0.001, 1.0, 123.456, MAX_SPEED):
            add(speed, float(route))

    # Cover invalid bounds and nonintegral selectors on both sides of the contract.
    for speed, route in (
        (-0.001, 0.0), (MAX_SPEED + 0.001, 0.0),
        (1.0, -1.0), (1.0, 15.001), (1.0, 1.5), (1.0, 7.999),
    ):
        add(speed, route)

    generator = random.Random(0x5EEDC0DE)
    for _ in range(128):
        add(generator.uniform(0.0, MAX_SPEED), float(generator.randrange(16)))

    lines = [f"{len(cases)}\n"]
    for (speed, route), expected in sorted(cases.items()):
        lines.append(" ".join(format(value, ".17g")
                              for value in (speed, route, expected, relative)) + "\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_pair")
    checker = manifest["binaries"]["float64_pair_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"float64_pair C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_float64_pair.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    relative = float(workload["measurement"].get(
        "relative_tolerance", workload["measurement"].get("input_scaled_tolerance", 0.0)))
    for case, record in zip(workload["cases"], records):
        speed, route, expected = encode_case(case, relative, ALGORITHM)
        observed = float(record["measurement"]["observed_result"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [speed, route]
                or record["workload"]["expected_result"] != expected
                or not matches(observed, oracle(speed, route), relative, speed, route)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_pair/speed_conversions")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/s/speed_conversions/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "speed-conversions-corpus.txt").write_text(data, encoding="utf-8")
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
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle pairs", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
