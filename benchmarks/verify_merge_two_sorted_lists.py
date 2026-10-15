#!/usr/bin/env python3
"""Check merge-two-sorted-lists ports against an independent merge oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations_with_replacement, product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "merge_two_sorted_lists"
MAX_TOTAL_LENGTH = 1024
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
WORKLOAD_PATH = ROOT / "benchmarks/m/merge_two_sorted_lists/workload.json"


def oracle(values: tuple[int, ...]) -> tuple[int, bytes]:
    return expected_output(list(values), ALGORITHM)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = oracle(values)

    small_lists = [()]
    alphabet = (-1, 0, 1, 2)
    for length in range(1, 5):
        small_lists.extend(combinations_with_replacement(alphabet, length))
    for first, second in product(small_lists, repeat=2):
        add((len(first), len(second), *first, *second))

    rng = random.Random(20261016)
    pool = [I32_MIN, I32_MIN + 1, -1000, -1, 0, 1, 1000, I32_MAX - 1, I32_MAX]
    for _ in range(768):
        total = rng.randrange(MAX_TOTAL_LENGTH + 1)
        first_length = rng.randrange(total + 1)
        first = tuple(sorted(rng.choice(pool) for _ in range(first_length)))
        second = tuple(sorted(rng.choice(pool) for _ in range(total - first_length)))
        add((first_length, len(second), *first, *second))

    invalid = (
        (), (0,), (-1, 0), (1025, 0), (0, 1025), (1, 1, 1),
        (2, 1, 1, 0, 1), (1, 2, 1, 0, -1),
        (1, 0, I32_MIN - 1), (0, 1, I32_MAX + 1),
        (1, 1, I32_MIN, 0), (1, 1, I32_MAX, 0),
        (512, 513, *(0 for _ in range(1025))),
    )
    for values in invalid:
        add(values)

    add((512, 512, *range(-512, 0), *range(0, 512)))
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, _output = oracle(values)
        if result != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)

    records = sorted(cases.items())
    # Capacity zero must reject a valid two-element output before writing bytes.
    records.append(((1, 1, 7, 8), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
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
        result, _expected_bytes = oracle(tuple(values))
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/merge_two_sorted_lists")
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
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
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
