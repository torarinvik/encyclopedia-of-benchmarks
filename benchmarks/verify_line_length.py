#!/usr/bin/env python3
"""Verify line_length ports against a repeated-step polyline oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_triple import encode_case, matches

ALGORITHM = "line_length"
INVALID_RESULT = -1e300


def oracle(start: float, end: float, steps: float) -> float:
    if (not all(math.isfinite(value) for value in (start, end, steps))
            or not -10.0 <= start <= end <= 10.0
            or not steps.is_integer() or not 1.0 <= steps <= 10_000.0):
        return INVALID_RESULT

    step_count = int(steps)
    step_width = (end - start) / step_count
    previous_x = start
    previous_y = math.sin(10.0 * previous_x)
    total = 0.0
    for _ in range(step_count):
        current_x = step_width + previous_x
        current_y = math.sin(10.0 * current_x)
        total += math.hypot(current_x - previous_x, current_y - previous_y)
        previous_x = current_x
        previous_y = current_y
    return total


def corpus(workload: dict) -> tuple[str, int]:
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    triples: set[tuple[float, float, float]] = set()
    for case in workload["cases"]:
        start, end, steps, expected = encode_case(case, tolerance, ALGORITHM)
        exact = oracle(start, end, steps)
        if not matches(expected, exact, tolerance, start, end):
            raise ValueError(f"published workload disagrees with the polyline oracle: {case['id']}")
        triples.add((start, end, steps))

    endpoints = (-10.0, -8.0, -5.5, -math.pi, -1.0, 0.0,
                 1.0, math.pi, 5.5, 8.0, 10.0)
    step_choices = (1, 7, 100, 1_000, 10_000)
    for left_index, start in enumerate(endpoints):
        for end in endpoints[left_index:]:
            for steps in step_choices:
                triples.add((start, end, float(steps)))

    rng = random.Random(20261015)
    random_step_choices = (1, 2, 3, 10, 37, 100, 257, 1_000, 10_000)
    for _ in range(128):
        start = rng.uniform(-10.0, 10.0)
        end = rng.uniform(start, 10.0)
        steps = float(rng.choice(random_step_choices))
        triples.add((start, end, steps))

    lines = [str(len(triples)) + "\n"]
    for start, end, steps in sorted(triples):
        expected = oracle(start, end, steps)
        lines.append(" ".join(format(value, ".17g") for value in
                              (start, end, steps, expected, tolerance)) + "\n")
    return "".join(lines), len(triples)


def verify(language: str, build_dir: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, build_dir,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_triple")
    checker = manifest["binaries"]["float64_triple_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64 C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = build_dir / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_float64_triple.py"),
         "--build-manifest", str(build_dir / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    for case, record in zip(workload["cases"], records):
        start, end, steps, expected = encode_case(case, tolerance, ALGORITHM)
        observed = record["measurement"]["observed_result"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] is not None
                or record["workload"]["input_values"] != [start, end, steps]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "float64_triple_call"
                or not matches(observed, expected, tolerance, start, end)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "build_manifest": str(build_dir / "build.json"),
        "build_manifest_sha256": sha256_file(build_dir / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/float64_triple/line_length")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    workload_path = ROOT / "benchmarks/l/line_length/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    build_dir = args.build_dir.resolve()
    build_dir.mkdir(parents=True, exist_ok=True)
    corpus_path = build_dir / "line_length-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, build_dir / language,
                            args.elisa_compiler, data, case_count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle triples, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "workload_sha256": sha256_file(workload_path),
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda item: item["language"]),
    }
    report_path = build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
