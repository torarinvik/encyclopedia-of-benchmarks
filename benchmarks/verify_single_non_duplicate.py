#!/usr/bin/env python3
"""Check the unique-among-pairs binary search against a frequency oracle."""

from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "single_non_duplicate"
MAX_VALUES = 1025
INVALID_RESULT = -2_147_483_649
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
WORKLOAD_PATH = ROOT / "benchmarks/s/single_non_duplicate/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not values or len(values) > MAX_VALUES or len(values) % 2 == 0
            or any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values)
            or values != sorted(values)):
        return INVALID_RESULT
    counts = Counter(values)
    singles = [value for value, count in counts.items() if count == 1]
    if len(singles) != 1 or any(count not in (1, 2) for count in counts.values()):
        return INVALID_RESULT
    return singles[0]


def corpus(workload: dict) -> tuple[str, int]:
    cases = {tuple(encode_case(case, algorithm=ALGORITHM)): case["expected_result"] for case in workload["cases"]}
    for case in workload["cases"]:
        if oracle(case["input_values"]) != case["expected_result"]:
            raise ValueError(f"published workload disagrees with frequency oracle: {case['id']}")
    domain = (-3, -2, -1, 0, 1, 2, 3)
    for pair_count in range(7):
        for unique in domain:
            pair_values = tuple(value for value in domain if value != unique)
            for pairs in combinations(pair_values, pair_count):
                values = tuple(sorted((*pairs, *pairs, unique)))
                cases[values] = oracle(list(values))
    cases[()] = INVALID_RESULT
    cases[(0, 0)] = INVALID_RESULT
    cases[tuple([0] * (MAX_VALUES + 1))] = INVALID_RESULT
    rng = random.Random(20261015)
    special = [I32_MIN, I32_MIN + 1, -1, 0, 1, I32_MAX - 1, I32_MAX]
    for _ in range(512):
        unique = rng.choice(special) if rng.randrange(2) else rng.randint(I32_MIN, I32_MAX)
        pool = [value for value in range(-4096, 4097) if value != unique]
        pair_count = rng.randrange(0, 513)
        chosen = rng.sample(pool, pair_count)
        values = tuple(sorted((*chosen, *chosen, unique)))
        cases[values] = oracle(list(values))
    max_pair_values = list(range(-256, 256))
    for unique in (I32_MIN, 256, I32_MAX):
        values = tuple(sorted((*max_pair_values, *max_pair_values, unique)))
        cases[values] = oracle(list(values))
    lines = [str(len(cases)) + "\n"]
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
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/single_non_duplicate")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
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
