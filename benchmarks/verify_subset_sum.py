#!/usr/bin/env python3
"""Verify signed subset-sum existence and counting ports against Python oracles."""

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

ALGORITHMS = ("subset_sum_exists", "subset_sum_count")
LIMIT = 6144
MAX_ITEMS = 24


def oracle(values: list[int], count: bool) -> int:
    if not values or len(values) > MAX_ITEMS + 1:
        return -1
    target, items = values[0], values[1:]
    if not -LIMIT <= target <= LIMIT or any(not -256 <= value <= 256 for value in items):
        return -1
    ways = {0: 1}
    for value in items:
        updated = dict(ways)
        for total, multiplicity in ways.items():
            updated[total + value] = updated.get(total + value, 0) + multiplicity
        ways = updated
    result = ways.get(target, 0)
    return result if count else int(result != 0)


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    is_count = algorithm == "subset_sum_count"
    cases: dict[tuple[int, ...], int] = {}

    def add(packed: tuple[int, ...]) -> None:
        cases[packed] = oracle(list(packed), is_count)

    for length in range(6):
        for items in product(range(-2, 3), repeat=length):
            reach = sum(abs(value) for value in items)
            for target in range(-reach, reach + 1):
                add((target, *items))
            if reach < LIMIT:
                add((LIMIT, *items))
                add((-LIMIT, *items))

    rng = random.Random(20261014)
    for _ in range(512):
        items = tuple(rng.randint(-256, 256) for _ in range(rng.randrange(0, MAX_ITEMS + 1)))
        add((rng.randint(-LIMIT, LIMIT), *items))

    for packed in ((LIMIT + 1,), (-LIMIT - 1,), (0, 257), (0, -257),
                   (0, *(1 for _ in range(MAX_ITEMS + 1)))):
        add(packed)

    for case in workload["cases"]:
        packed = tuple(encode_case(case, algorithm))
        expected = oracle(list(packed), is_count)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload oracle mismatch: {algorithm}/{case['id']}")
        cases[packed] = expected

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for packed, expected in records:
        suffix = "" if not packed else " " + " ".join(map(str, packed))
        lines.append(f"{len(packed)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path,
           elisa_compiler: str | None, data: str, case_count: int,
           workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array-scalar C ABI oracle failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {algorithm}/{case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/subset_sum")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages) or len(set(args.algorithms)) != len(args.algorithms):
        parser.error("jobs must be positive and language/algorithm selections must be unique")
    base = args.build_dir.resolve()
    base.mkdir(parents=True, exist_ok=True)
    cases_by_algorithm = {}
    for algorithm in args.algorithms:
        workload = json.loads((ROOT / "benchmarks/s" / algorithm / "workload.json").read_text(encoding="utf-8"))
        if workload.get("algorithm") != algorithm:
            parser.error(f"workload algorithm mismatch for {algorithm}")
        data, count = corpus(workload, algorithm)
        corpus_path = base / f"{algorithm}-corpus.txt"
        corpus_path.write_text(data, encoding="utf-8")
        cases_by_algorithm[algorithm] = (workload, data, count)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {}
        for algorithm in args.algorithms:
            workload, data, count = cases_by_algorithm[algorithm]
            for language in args.languages:
                directory = base / algorithm / language
                futures[executor.submit(verify, algorithm, language, directory,
                                        args.elisa_compiler, data, count, workload)] = (algorithm, language)
        for future in as_completed(futures):
            algorithm, language = futures[future]
            try:
                result = future.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle inputs",
                  flush=True)
    report = {"algorithms": list(args.algorithms),
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = base / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
