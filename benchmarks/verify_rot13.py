#!/usr/bin/env python3
"""Verify ROT13 ports against the case-preserving ASCII mapping."""

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
from run_i64_array_bytes_output import expected_output

ALGORITHMS = ("rot13", "theoretical_rot13")
MAX_INPUT_LENGTH = 66


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for length in range(3):
        for values in product(range(1, 128), repeat=length):
            key = tuple(values)
            cases[key] = expected_output(list(key), algorithm)

    rng = random.Random(20261014)
    for _ in range(512):
        length = rng.randrange(MAX_INPUT_LENGTH + 1)
        values = tuple(rng.randrange(1, 128) for _ in range(length))
        cases[values] = expected_output(list(values), algorithm)
    for values in (
        (0,), (-1,), (128,), (127, 128),
    ):
        cases[values] = expected_output(list(values), algorithm)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = expected_output(list(values), algorithm)
        if case["expected_result"] != expected[0]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = expected

    records = sorted(cases.items())
    # A valid one-byte input with zero output capacity must fail without writing.
    records.append(((65,), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected = expected_output(values, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected[0]
                or record["measurement"]["observed_result"] != expected[0]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    if len(set(args.algorithms)) != len(args.algorithms):
        parser.error("algorithm selections must be unique")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
            data, case_count = corpus(workload, algorithm)
            (directory / algorithm / f"{algorithm}-corpus.txt").parent.mkdir(
                parents=True, exist_ok=True)
            (directory / algorithm / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
            for language in args.languages:
                target = directory / algorithm / language
                job = executor.submit(verify, algorithm, language, target,
                                      args.elisa_compiler, data, case_count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithms": list(args.algorithms),
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"])),
              "failures": failures}
    report_path = directory / "rot13-suite-verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
