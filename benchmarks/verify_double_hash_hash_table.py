#!/usr/bin/env python3
"""Verify all nine bounded double-hashing table ports against an independent oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from double_hash_hash_table_oracle import oracle

ALGORITHM = "double_hash_hash_table"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            raise ValueError(f"workload/oracle disagreement: {case['id']}")
        cases[values] = expected
    # Exhaust short state traces on a three-slot table, including duplicate inserts and deletes.
    actions = tuple((op, key) for op in (1, 2, 3) for key in (0, 1, 3))
    for size in range(5):
        for trace in itertools.product(actions, repeat=size):
            values = (3, size, *(part for pair in trace for part in pair))
            cases[values] = oracle(list(values))
    rng = random.Random(20261016)
    edge_keys = [-(2**63), -(2**63) + 1, -101, -1, 0, 1, 101, 2**63 - 2, 2**63 - 1]
    for _ in range(512):
        capacity = rng.choice((3, 5, 7, 11, 97, 101))
        count = rng.randrange(0, 65)
        values = [capacity, count]
        for _index in range(count):
            values.extend((rng.randrange(1, 4), rng.choice(edge_keys) if rng.randrange(4) == 0
                           else rng.randint(-1000, 1000)))
        frozen = tuple(values)
        cases[frozen] = oracle(values)
    for values in ((), (3,), (2, 0), (4, 0), (103, 0), (3, -1), (3, 513),
                   (3, 1, 4, 9), (3, 1, 1), (3, 0, 1), (3, 1, 2, 7, 99)):
        cases[values] = oracle(list(values))
    lines = [f"{len(cases)}\n"]
    for values, result in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, compiler: str | None, data: str,
           case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = subprocess.run([manifest["binaries"]["i64_array_scalar_check"]["path"]],
                             input=data, capture_output=True, text=True, timeout=120)
    if checker.returncode:
        raise RuntimeError(f"oracle corpus check failed: {checker.stderr}")
    if json.loads(checker.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full corpus")
    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"), "--samples", "1",
                               "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
                              cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text().splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected record count")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"workload record mismatch: {case['id']}")
    return {"language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/double_hash_hash_table")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/d/double_hash_hash_table/workload.json").read_text())
    data, count = corpus(workload)
    (directory / "double-hash-corpus.txt").write_text(data)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, count, workload): language for language in args.languages}
        for future in as_completed(jobs):
            language = jobs[future]
            try:
                result = future.result()
                results.append(result)
                print(f"PASS {ALGORITHM}/{language}: {count} cases", flush=True)
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda x: x["language"]),
              "all_passed": not failures and len(results) == len(args.languages)}
    (directory / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {directory / 'verification.json'}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
