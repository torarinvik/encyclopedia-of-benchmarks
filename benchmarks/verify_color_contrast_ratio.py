#!/usr/bin/env python3
"""Verify color-contrast ports against an independent luminance oracle."""

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
from color_contrast_ratio_oracle import INVALID_RESULT, expected_result

ALGORITHM = "color_contrast_ratio"
WORKLOAD_PATH = ROOT / "benchmarks/c/color_contrast_ratio/workload.json"
ABS_TOL = 1e-12
REL_TOL = 1e-12
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def matches(observed: float, expected: float) -> bool:
    if expected == INVALID_RESULT:
        return observed == INVALID_RESULT
    return math.isfinite(observed) and math.isclose(
        observed, expected, rel_tol=REL_TOL, abs_tol=ABS_TOL)


def corpus(workload: dict) -> list[tuple[int, ...]]:
    cases: set[tuple[int, ...]] = set()

    def add(values: tuple[int, ...]) -> None:
        cases.add(values)

    fixed = (
        (0, 0, 0, 0, 0, 0),
        (255, 255, 255, 255, 255, 255),
        (0, 0, 0, 255, 255, 255),
        (255, 255, 255, 0, 0, 0),
        (255, 0, 0, 0, 255, 0),
        (0, 255, 0, 0, 0, 255),
        (0, 0, 255, 255, 0, 255),
        (10, 10, 10, 11, 11, 11),
        (11, 11, 11, 10, 10, 10),
        (127, 127, 127, 128, 128, 128),
        (12, 34, 56, 78, 90, 123),
        (255, 0, 1, 1, 0, 255),
    )
    for values in fixed:
        add(values)

    # Exhaust each channel value as a grayscale foreground over black and white.
    for channel in range(256):
        gray = (channel, channel, channel)
        add((*gray, 0, 0, 0))
        add((*gray, 255, 255, 255))
        add((0, 0, 0, *gray))

    # Exercise channel order and asymmetry with every byte value in each slot.
    for channel in range(256):
        add((channel, 0, 0, 0, channel, 0))
        add((0, channel, 0, 0, 0, channel))
        add((0, 0, channel, channel, 0, 0))

    for values in (
        (), (0,), (0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0),
        (-1, 0, 0, 0, 0, 0), (0, -1, 0, 0, 0, 0),
        (0, 0, -1, 0, 0, 0), (0, 0, 0, 256, 0, 0),
        (0, 0, 0, 0, 256, 0), (0, 0, 0, 0, 0, 256),
        (I64_MIN, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, I64_MAX),
    ):
        add(values)

    rng = random.Random(20261016)
    for _ in range(256):
        values = tuple(rng.randrange(256) for _ in range(6))
        add(values)
        add(values[3:] + values[:3])

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        oracle_result = expected_result(list(values))
        if not matches(case["expected_result"], oracle_result):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)
    return sorted(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           values_list: list[tuple[int, ...]], workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     family="i64_array_float64")
    runner = Path(manifest["binaries"]["i64_array_float64_runner"]["path"])
    for values in values_list:
        expected = expected_result(list(values))
        command = [str(runner), str(len(values)), *map(str, values), repr(expected),
                   repr(ABS_TOL), repr(REL_TOL), "1", "0", "1"]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=30)
        if completed.returncode:
            raise RuntimeError(f"{language} result mismatch for {values}: {completed.stderr}")
        observed = float(json.loads(completed.stdout)["observed_result"])
        if not matches(observed, expected):
            raise RuntimeError(f"{language} result differs from the color-contrast oracle: {values}")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_float64.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected = expected_result(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["measurement"]["comparison_model"] != "i64_array_float64_call"
                or len(record["measurement"]["samples_ns"]) != 1
                or record["workload"]["input_values"] != values
                or record["workload"]["input_length"] != len(values)
                or not matches(record["workload"]["expected_result"], expected)
                or not matches(record["measurement"]["observed_result"], expected)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": len(values_list), "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_float64/color_contrast_ratio")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    values_list = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, args.build_dir / language,
                                   args.elisa_compiler, values_list, workload): language
                   for language in args.languages}
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda item: item["language"])
    report = {"algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": platform.platform(), "oracle_cases_per_language": len(values_list),
              "results": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
