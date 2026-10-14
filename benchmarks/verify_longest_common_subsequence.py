#!/usr/bin/env python3
"""Check longest-common-subsequence ports against an independent table oracle."""

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

ALGORITHM = "longest_common_subsequence"
MAX_SEQUENCE_LENGTH = 255
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(packed: list[int]) -> int:
    if not isinstance(packed, list) or any(type(value) is not int for value in packed):
        raise ValueError("LCS oracle requires an integer list")
    if any(value < I64_MIN or value > I64_MAX for value in packed):
        raise ValueError("LCS inputs must fit signed 64-bit integers")
    if len(packed) < 2 or len(packed) > 2 + 2 * MAX_SEQUENCE_LENGTH:
        return -1
    left_length, right_length = packed[:2]
    if not 0 <= left_length <= MAX_SEQUENCE_LENGTH or not 0 <= right_length <= MAX_SEQUENCE_LENGTH:
        return -1
    if len(packed) != 2 + left_length + right_length:
        return -1
    left = packed[2:2 + left_length]
    right = packed[2 + left_length:]
    if any(not 0 <= value <= 127 for value in left + right):
        return -1

    table = [[0] * (right_length + 1) for _ in range(left_length + 1)]
    for i, left_value in enumerate(left, start=1):
        for j, right_value in enumerate(right, start=1):
            if left_value == right_value:
                table[i][j] = table[i - 1][j - 1] + 1
            else:
                table[i][j] = max(table[i - 1][j], table[i][j - 1])
    return table[left_length][right_length]


def pack(left: tuple[int, ...], right: tuple[int, ...]) -> tuple[int, ...]:
    return (len(left), len(right), *left, *right)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with table oracle: {case['id']}")
        cases[tuple(values)] = expected

    alphabet = (65, 66)
    sequences = [sequence for length in range(6)
                 for sequence in product(alphabet, repeat=length)]
    for left in sequences:
        for right in sequences:
            packed = pack(left, right)
            cases[packed] = oracle(list(packed))

    cases[pack((0,) * MAX_SEQUENCE_LENGTH, (0,) * MAX_SEQUENCE_LENGTH)] = MAX_SEQUENCE_LENGTH
    cases[pack((0,) * MAX_SEQUENCE_LENGTH, (1,) * MAX_SEQUENCE_LENGTH)] = 0
    cases[pack(tuple(range(128)) * 1 + tuple(range(127)), tuple(range(127)) + tuple(range(128)))] = oracle(
        list(pack(tuple(range(128)) + tuple(range(127)), tuple(range(127)) + tuple(range(128))))
    )

    invalid = [
        (), (0,), (-1, 0), (256, 0), (0, -1), (0, 256),
        (1, 1, 128, 65), (2, 2, 65, 66, 67), (1, 1, 65, 66),
        (0, 0, 65), (255, 255),
    ]
    for packed in invalid:
        cases[packed] = oracle(list(packed))

    rng = random.Random(20261014)
    for _ in range(256):
        left_length = rng.randrange(0, 129)
        right_length = rng.randrange(0, 129)
        left = tuple(rng.randrange(0, 128) for _ in range(left_length))
        right = tuple(rng.randrange(0, 128) for _ in range(right_length))
        packed = pack(left, right)
        cases[packed] = oracle(list(packed))

    lines = [f"{len(cases)}\n"]
    for packed, expected in sorted(cases.items()):
        suffix = "" if not packed else " " + " ".join(map(str, packed))
        lines.append(f"{len(packed)} {expected}{suffix}\n")
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
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/longest_common_subsequence")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/l/longest_common_subsequence/workload.json")
                          .read_text(encoding="utf-8"))
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
