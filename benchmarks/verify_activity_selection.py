#!/usr/bin/env python3
"""Check activity-selection ports against weighted interval scheduling DP."""

from __future__ import annotations

import argparse
from bisect import bisect_right
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

ALGORITHM = "activity_selection"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: list[int]) -> int:
    if not isinstance(values, list) or not values or len(values) > 129:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    count = values[0]
    if type(count) is not int or not 0 <= count <= 64 or len(values) != 1 + 2 * count:
        return -1
    activities = [(values[1 + 2 * index], values[2 + 2 * index]) for index in range(count)]
    if any(start > finish for start, finish in activities):
        return -1
    activities.sort(key=lambda interval: (interval[1], interval[0]))
    finishes = [finish for _, finish in activities]
    best = [0] * (count + 1)
    for index, (start, _finish) in enumerate(activities, start=1):
        compatible = bisect_right(finishes, start, hi=index - 1)
        best[index] = max(best[index - 1], best[compatible] + 1)
    return best[count]


def pack(activities: tuple[tuple[int, int], ...] | list[tuple[int, int]]) -> tuple[int, ...]:
    return (len(activities), *(value for interval in activities for value in interval))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for values, expected in ((tuple(encode_case(case, algorithm=ALGORITHM)), case["expected_result"])
                             for case in workload["cases"]):
        if oracle(list(values)) != expected:
            raise ValueError("published workload disagrees with weighted interval oracle")
        cases[values] = expected

    interval_set = [(start, finish) for start in range(4) for finish in range(start, 4)]
    for length in range(5):
        for schedule in product(interval_set, repeat=length):
            values = pack(schedule)
            cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    edge_times = [I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX]
    for _ in range(512):
        size = rng.randrange(0, 21)
        activities = []
        for _index in range(size):
            if rng.randrange(3) == 0:
                left = rng.choice(edge_times)
                right = rng.choice(edge_times)
            else:
                left = rng.randint(-1000, 1000)
                right = rng.randint(-1000, 1000)
            activities.append((min(left, right), max(left, right)))
        values = pack(activities)
        cases[values] = oracle(list(values))

    largest = pack([(2 * index, 2 * index + 1) for index in range(64)])
    cases[largest] = oracle(list(largest))
    for values in ((), (-1,), (65,), (2, 0, 1), (1, 0, 1, 2), (1, 2, 1), (0, 7)):
        cases[values] = oracle(list(values))

    special_records = ["NULL 1 -1\n"]
    lines = [str(len(cases) + len(special_records)) + "\n", *special_records]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases) + len(special_records)


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

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(records_path)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
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
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/activity_selection")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/a/activity_selection/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
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
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"]),
              "all_passed": not failures and len(results) == len(args.languages)}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
