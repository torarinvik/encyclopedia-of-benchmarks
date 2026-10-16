#!/usr/bin/env python3
"""Verify blob-detection ports against a scalar color/morphology oracle."""

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

from blob_detection_oracle import MAX_INPUT_LENGTH, blob_detection_count
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "blob_detection"
MAX_SIDE = 128


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: tuple[int, ...] | list[int]) -> None:
        packed = tuple(values)
        if len(packed) > 100001:
            raise ValueError("generated array case exceeds the ABI checker limit")
        cases[packed] = blob_detection_count(packed)

    for case in workload["cases"]:
        values = tuple(encode_case(case, ALGORITHM))
        expected = blob_detection_count(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[values] = expected

    rng = random.Random(20261015)
    palette = ((0, 0, 0), (0, 255, 128), (255, 0, 0), (0, 255, 70),
               (0, 255, 69), (0, 255, 248), (0, 255, 249),
               (141, 250, 196), (142, 250, 196), (255, 255, 255))
    for _ in range(96):
        height, width = rng.randrange(1, 49), rng.randrange(1, 49)
        profile = rng.randrange(2)
        pixels = [rng.choice(palette) for _ in range(height * width)]
        add((height, width, profile, *(channel for pixel in pixels for channel in pixel)))

    for _ in range(32):
        height, width = rng.randrange(16, MAX_SIDE + 1), rng.randrange(16, MAX_SIDE + 1)
        profile = rng.randrange(2)
        pixels = [(0, 0, 0)] * (height * width)
        for _rectangle in range(rng.randrange(1, 8)):
            rectangle_height = rng.randrange(5, min(36, height) + 1)
            rectangle_width = rng.randrange(5, min(36, width) + 1)
            top = rng.randrange(height - rectangle_height + 1)
            left = rng.randrange(width - rectangle_width + 1)
            color = rng.choice(palette[1:])
            for row in range(top, top + rectangle_height):
                start = row * width + left
                pixels[start:start + rectangle_width] = [color] * rectangle_width
        add((height, width, profile, *(channel for pixel in pixels for channel in pixel)))

    for values in ((), (-1,), (1,), (1, 1), (1, 1, 0), (1, 1, 0, 0, 0),
                   (MAX_SIDE + 1, 1), (1, MAX_SIDE + 1),
                   (1, 1, -1, 0, 0, 0), (1, 1, 2, 0, 0, 0),
                   (1, 1, 0, 0, 256, 0),
                   tuple([1, 1] + [0] * MAX_INPUT_LENGTH)):
        add(values)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array-scalar ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded output/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path),
            "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS,
                        default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_scalar/b/blob_detection")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/b/blob_detection/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM,
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "all_passed": not failures and len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
