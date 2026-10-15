#!/usr/bin/env python3
"""Check Max Increase to Keep City Skyline ports against a direct grid oracle."""

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

ALGORITHM = "max_increase_keeping_skyline"
MAX_GRID_SIZE = 50
MAX_INPUT_LENGTH = 1 + MAX_GRID_SIZE * MAX_GRID_SIZE
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
WORKLOAD_PATH = ROOT / "benchmarks/m/max_increase_keeping_skyline/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    size = values[0]
    if size < 2 or size > MAX_GRID_SIZE or len(values) != 1 + size * size:
        return -1
    cells = values[1:]
    if any(height < 0 or height > 100 for height in cells):
        return -1
    row_maxima = [max(cells[row * size:(row + 1) * size]) for row in range(size)]
    column_maxima = [max(cells[row * size + column] for row in range(size))
                     for column in range(size)]
    return sum(min(row_maxima[row], column_maxima[column]) - cells[row * size + column]
               for row in range(size) for column in range(size))


def corpus(workload: dict) -> tuple[str, int]:
    cases = {tuple(encode_case(case)): case["expected_result"] for case in workload["cases"]}
    for case in workload["cases"]:
        if oracle(case["input_values"]) != case["expected_result"]:
            raise ValueError(f"published workload disagrees with grid oracle: {case['id']}")

    for size in (2, 3):
        for cells in product((0, 1, 2), repeat=size * size):
            values = [size, *cells]
            cases[tuple(values)] = oracle(values)

    for value in (-1, 0, 2, 50, 51, I64_MIN, I64_MAX):
        cases[(value,)] = oracle([value])
    cases[(2, 0, 1, 2)] = -1
    cases[(2, 0, 1, 2, 3, 4)] = -1
    cases[(2, -1, 0, 0, 0)] = -1
    cases[(2, 101, 0, 0, 0)] = -1
    cases[(2, I64_MIN, 0, 0, 0)] = -1
    cases[(2, I64_MAX, 0, 0, 0)] = -1
    cases[(50, *([0] * 2500))] = 0
    cases[(50, *([100] * 2500))] = 0
    cases[(51,)] = -1
    cases[(2,) * (MAX_INPUT_LENGTH + 1)] = -1

    rng = random.Random(20261015)
    heights = [0, 1, 2, 50, 99, 100]
    for _ in range(512):
        size = rng.randint(2, 10)
        cells = [rng.choice(heights) if rng.random() < 0.7 else rng.randint(0, 100)
                 for _ in range(size * size)]
        values = [size, *cells]
        cases[tuple(values)] = oracle(values)
    for size in (2, 7, 50):
        cells = [100 if row in (0, size - 1) or column in (0, size - 1) else 0
                 for row in range(size) for column in range(size)]
        values = [size, *cells]
        cases[tuple(values)] = oracle(values)

    lines = [str(len(cases)) + "\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


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
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                               text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/max_increase_keeping_skyline")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "max_increase_keeping_skyline-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle grids, "
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
