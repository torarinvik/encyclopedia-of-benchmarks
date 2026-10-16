#!/usr/bin/env python3
"""Verify bandwidth-allocation ports against the pinned Java greedy semantics."""

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

ALGORITHM = "bandwidth_allocation"
WORKLOAD_PATH = ROOT / "benchmarks/b/bandwidth_allocation/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    bandwidth, count = values[:2]
    if (not 0 <= bandwidth <= 100_000 or not 0 <= count <= 64
            or len(values) != 2 + 2 * count):
        return -1
    demands = values[2:2 + count]
    gains = values[2 + count:]
    if (any(not 1 <= demand <= 1_000 for demand in demands)
            or any(not 0 <= gain <= 10_000 for gain in gains)):
        return -1
    order = sorted(range(count), key=lambda index: gains[index] / demands[index], reverse=True)
    remaining, total = bandwidth, 0
    for index in order:
        if remaining >= demands[index]:
            total += gains[index]
            remaining -= demands[index]
        else:
            total += int((gains[index] / demands[index]) * remaining)
            break
    return total


def pack(bandwidth: int, users: tuple[tuple[int, int], ...]) -> tuple[int, ...]:
    return (bandwidth, len(users), *(demand for demand, _ in users),
            *(value for _, value in users))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = tuple(encode_case(case, ALGORITHM))
        expected = case["expected_result"]
        if oracle(list(values)) != expected:
            raise ValueError(f"published workload disagrees with the greedy oracle: {case['id']}")
        cases[values] = expected

    item_types = tuple((demand, value) for demand in range(1, 4) for value in range(5))
    for size in range(4):
        for users in product(item_types, repeat=size):
            for bandwidth in range(9):
                values = pack(bandwidth, users)
                cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    for _ in range(512):
        count = rng.randrange(65)
        users = tuple((rng.randrange(1, 1_001), rng.randrange(10_001)) for _ in range(count))
        values = pack(rng.randrange(100_001), users)
        cases[values] = oracle(list(values))

    for values in ((), (0,), (-1, 0), (100_001, 0), (0, -1), (0, 65),
                   (1, 1, 0, 1), (1, 1, -1, 1), (1, 1, 1, -1),
                   (0, 0, 2), (0, 1, 1), (1, 1, 1, 1, 7),
                   (0, 1, 1 << 63, 0)):
        cases[values] = oracle(list(values))

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
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"scalar-array ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete greedy-allocation corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of allocation records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_scalar/b/bandwidth_allocation")
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language, args.build_dir / language,
                            args.elisa_compiler, data, case_count, workload): language
            for language in args.languages
        }
        for future in as_completed(futures):
            language = futures[future]
            try:
                results.append(future.result())
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
    results.sort(key=lambda item: item["language"])
    report = {"algorithm": ALGORITHM,
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures and len(results) == len(args.languages),
              "oracle_cases_per_language": case_count,
              "results": results, "failures": failures}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "passed" if report["all_passed"] else "failed",
                      "oracle_cases_per_language": case_count,
                      "languages": [entry["language"] for entry in results],
                      "report": str(report_path)}, indent=2))
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
