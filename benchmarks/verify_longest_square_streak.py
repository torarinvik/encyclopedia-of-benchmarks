#!/usr/bin/env python3
"""Verify longest-square-streak implementations against a set-based oracle."""

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
from run_i64_array_bytes_output import expected_output as recorder_oracle

ALGORITHM = "longest_square_streak"
WORKSPACE_BYTES = 400004


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (len(values) < 3 or len(values) > 100001
            or any(type(value) is not int for value in values)):
        return -1, b""
    count, numbers = values[0], values[1:]
    if (not 2 <= count <= 100000 or count != len(numbers)
            or any(not 2 <= value <= 100000 for value in numbers)):
        return -1, b""
    present = set(numbers)
    longest = 0
    for start in present:
        length = 1
        square = start * start
        while square in present:
            length += 1
            square *= square
        longest = max(longest, length)
    return (longest if longest >= 2 else -1), b""


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes, int]] = {}

    def add(values: tuple[int, ...] | list[int], capacity: int = WORKSPACE_BYTES) -> None:
        key = tuple(values)
        result, output = oracle(list(key))
        cases[key] = result, output, capacity

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = oracle(list(values))
        if (expected != recorder_oracle(list(values), ALGORITHM)
                or expected[0] != case["expected_result"]):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values, case["workspace_bytes"])

    for length in range(2, 5):
        for numbers in product(range(2, 7), repeat=length):
            add((length, *numbers))

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randint(2, 24)
        add((length, *(rng.randint(2, 200) for _ in range(length))))

    malformed = (
        (), (1,), (1, 4), (2, 2), (2, 2, 4, 16), (2, 1, 4),
        (2, 2, 100001), (100001, 2, 4), (100000, 2),
    )
    for values in malformed:
        add(values)

    records = [(values, count, output, capacity)
               for values, (count, output, capacity) in sorted(cases.items())]
    # Check both a null-sized workspace and a workspace one byte below the contract.
    records.append(((2, 2, 4), -2, b"", 0))
    records.append(((2, 2, 4), -2, b"\xA5", WORKSPACE_BYTES - 1))
    lines = [f"{len(records)}\n"]
    for values, result, output, capacity in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)} {capacity}{suffix} "
                     f"{output.hex() if output else '-'}\n")
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
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected_count, expected_bytes = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_count
                or record["measurement"]["observed_result"] != expected_count
                or len(record["measurement"]["samples_ns"]) != 1
                or case["expected_output_hex"] != expected_bytes.hex()):
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/longest_square_streak")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/l/longest_square_streak/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "oracle-corpus.txt").write_text(data, encoding="utf-8")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
