#!/usr/bin/env python3
"""Check rectangle-union ports against an independent clipping oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "rectangle_union_area"
COORDINATE_LIMIT = 1_000_000_000


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) != 8
            or any(type(value) is not int or abs(value) > COORDINATE_LIMIT for value in values)):
        return -1
    ax1, ay1, ax2, ay2, bx1, by1, bx2, by2 = values
    if ax1 >= ax2 or ay1 >= ay2 or bx1 >= bx2 or by1 >= by2:
        return -1
    area_a = (ax2 - ax1) * (ay2 - ay1)
    area_b = (bx2 - bx1) * (by2 - by1)
    clipped_left, clipped_right = max(ax1, bx1), min(ax2, bx2)
    clipped_bottom, clipped_top = max(ay1, by1), min(ay2, by2)
    overlap = (clipped_right - clipped_left) * (clipped_top - clipped_bottom)
    if clipped_right <= clipped_left or clipped_top <= clipped_bottom:
        overlap = 0
    return area_a + area_b - overlap


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[tuple(values)] = expected

    intervals = [(left, right) for left, right in combinations(range(-2, 3), 2)]
    rectangles = [(x1, y1, x2, y2)
                  for x1, x2 in intervals for y1, y2 in intervals]
    for first in rectangles:
        for second in rectangles:
            values = (*first, *second)
            cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    for _ in range(512):
        rectangle = []
        for _axis in range(2):
            low = rng.randint(-COORDINATE_LIMIT, COORDINATE_LIMIT - 1)
            high = rng.randint(low + 1, COORDINATE_LIMIT)
            rectangle.extend((low, high))
        first_x1, first_x2, first_y1, first_y2 = rectangle
        rectangle = []
        for _axis in range(2):
            low = rng.randint(-COORDINATE_LIMIT, COORDINATE_LIMIT - 1)
            high = rng.randint(low + 1, COORDINATE_LIMIT)
            rectangle.extend((low, high))
        second_x1, second_x2, second_y1, second_y2 = rectangle
        values = (first_x1, first_y1, first_x2, first_y2,
                  second_x1, second_y1, second_x2, second_y2)
        cases[values] = oracle(list(values))

    invalid = [
        (), (0,), (0, 0, 1, 1, 0, 0, 1),
        (0, 0, 0, 1, 0, 0, 1, 1),
        (0, 1, 1, 0, 0, 0, 1, 1),
        (0, 0, 1, 1, 0, 0, 1, COORDINATE_LIMIT + 1),
    ]
    for values in invalid:
        cases[values] = -1

    lines = [str(len(cases)) + "\n"]
    for values, expected in sorted(cases.items()):
        lines.append(f"{len(values)} {expected} " + " ".join(map(str, values)) + "\n")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/rectangle_union_area")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/r/rectangle_union_area/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle cases, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
