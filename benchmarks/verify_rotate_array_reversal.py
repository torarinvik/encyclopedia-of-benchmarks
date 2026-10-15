#!/usr/bin/env python3
"""Verify three-reversal rotation ports against a slicing oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "rotate_array_reversal"
MAX_ARRAY_LENGTH = 1024
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 1
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
WORKLOAD_PATH = ROOT / "benchmarks/r/rotate_array_reversal/workload.json"


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""
    steps, items = values[0], values[1:]
    if not I32_MIN <= steps <= I32_MAX or len(items) > MAX_ARRAY_LENGTH:
        return -1, b""
    if any(not I32_MIN <= value <= I32_MAX for value in items):
        return -1, b""
    shift = steps % len(items) if items else 0
    rotated = items[-shift:] + items[:-shift] if shift else items[:]
    output = struct.pack("<" + "i" * len(rotated), *rotated) if rotated else b""
    return len(rotated), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = oracle(list(values))

    for array_length in range(7):
        for items in product((-1, 0, 1), repeat=array_length):
            for steps in range(-array_length - 2, array_length + 3):
                add((steps, *items))

    rng = random.Random(20261015)
    pool = [I32_MIN, I32_MIN + 1, -1000, -1, 0, 1, 1000, I32_MAX - 1, I32_MAX]
    step_pool = [I32_MIN, I32_MIN + 1, -1025, -1, 0, 1, 1025, I32_MAX - 1, I32_MAX]
    for _ in range(256):
        items = tuple(rng.choice(pool) for _ in range(rng.randrange(0, 65)))
        add((rng.choice(step_pool), *items))

    add((I32_MIN, *range(MAX_ARRAY_LENGTH)))
    add((I32_MAX, *((-11,) * MAX_ARRAY_LENGTH)))
    for values in (
        (), (I32_MIN - 1, 1), (I32_MAX + 1, 1),
        (0, I32_MIN - 1), (0, I32_MAX + 1),
        (0, *range(MAX_ARRAY_LENGTH + 1)),
    ):
        add(tuple(values))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        if case.get("input_length") != len(values):
            raise ValueError(f"declared input length differs for {case['id']}")
        result, _output = oracle(list(values))
        if result != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)

    records = sorted(cases.items())
    records.append(((0, 1), (-2, b"")))
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/rotate_array_reversal")
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
