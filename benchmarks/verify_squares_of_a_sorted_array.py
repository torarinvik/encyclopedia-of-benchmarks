#!/usr/bin/env python3
"""Check sorted-squares ports against an independent sorting oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations_with_replacement
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "squares_of_a_sorted_array"
MAX_ARRAY_LENGTH = 10000
WORKLOAD_PATH = ROOT / "benchmarks/s/squares_of_a_sorted_array/workload.json"


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_ARRAY_LENGTH
            or any(type(value) is not int or not -10000 <= value <= 10000 for value in values)
            or any(values[index - 1] > values[index] for index in range(1, len(values)))):
        return -1, b""
    squared = sorted(value * value for value in values)
    output = struct.pack("<" + "q" * len(squared), *squared) if squared else b""
    return len(squared), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    for length in range(8):
        for values in combinations_with_replacement(range(-3, 4), length):
            cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    pool = [-10000, -9999, -3, -2, -1, 0, 0, 1, 2, 3, 9999, 10000]
    for _ in range(512):
        length = rng.randrange(0, 129)
        values = tuple(sorted(rng.choice(pool) for _ in range(length)))
        cases[values] = oracle(list(values))

    for values in (
        (), (0,), (-10000,), (10000,), (-4, -1, 0, 3, 4),
        (-8, -3, -3, 0, 3, 3, 8), (-10000, -1, 0, 1, 10000),
        (1, 0), (10001,), (-10001,), (-(2**63),), ((2**63) - 1,),
        tuple([0] * (MAX_ARRAY_LENGTH + 1)),
    ):
        cases[values] = oracle(list(values))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result = oracle(list(values))
        if result[0] != case["expected_result"]:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        if expected_output(list(values), ALGORITHM) != result:
            raise ValueError(f"recorder oracle differs from verifier oracle: {case['id']}")
        cases[values] = result

    records = sorted(cases.items())
    records.append(((0,), (-2, b"")))  # Valid input with no output capacity.
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {count} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                              text=True, timeout=180)
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
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result, _expected_bytes = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/squares_of_a_sorted_array")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

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
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
