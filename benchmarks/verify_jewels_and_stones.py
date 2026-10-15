#!/usr/bin/env python3
"""Verify jewels-and-stones ports against an independent set-membership oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations, product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "jewels_and_stones"
MAX_JEWELS_LENGTH = 127
MAX_STONES_LENGTH = 4096
MAX_PACKED_LENGTH = 4225
WORKLOAD_PATH = ROOT / "benchmarks/j/jewels_and_stones/workload.json"


def pack(jewels: list[int], stones: list[int]) -> list[int]:
    return [len(jewels), len(stones), *jewels, *stones]


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_PACKED_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return -1
    jewel_count, stone_count = values[:2]
    if (not 0 <= jewel_count <= MAX_JEWELS_LENGTH
            or not 0 <= stone_count <= MAX_STONES_LENGTH
            or len(values) != 2 + jewel_count + stone_count):
        return -1
    jewels = values[2:2 + jewel_count]
    stones = values[2 + jewel_count:]
    if (any(not 1 <= value <= 127 for value in (*jewels, *stones))
            or len(set(jewels)) != len(jewels)):
        return -1
    jewel_set = set(jewels)
    return sum(value in jewel_set for value in stones)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        if case.get("input_length") != len(values):
            raise ValueError(f"declared input length differs for {case['id']}")
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with set oracle: {case['id']}")
        cases[tuple(values)] = expected

    jewel_universe = (97, 98, 99)
    stone_universe = (97, 98, 99)
    for jewel_count in range(len(jewel_universe) + 1):
        for jewels_tuple in combinations(jewel_universe, jewel_count):
            jewels = list(jewels_tuple)
            for stone_length in range(7):
                for stones_tuple in product(stone_universe, repeat=stone_length):
                    stones = list(stones_tuple)
                    values = pack(jewels, stones)
                    cases[tuple(values)] = oracle(values)

    rng = random.Random(20261022)
    for _ in range(512):
        jewels = rng.sample(range(1, 128), rng.randrange(0, 32))
        stones = [rng.randrange(1, 128) for _ in range(rng.randrange(MAX_STONES_LENGTH + 1))]
        values = pack(jewels, stones)
        cases[tuple(values)] = oracle(values)

    lines = [f"{len(cases)}\n"]
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
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/jewels_and_stones")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
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
