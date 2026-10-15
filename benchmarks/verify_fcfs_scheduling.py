#!/usr/bin/env python3
"""Compile and check FCFS scheduling ports against an independent oracle."""

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

ALGORITHM = "fcfs_scheduling"


def oracle(values: list[int]) -> tuple[int, bytes]:
    if not values or len(values) > 193 or any(type(value) is not int for value in values):
        return -2, b""
    count = values[0]
    if not 0 <= count <= 64 or len(values) != 1 + 3 * count:
        return -2, b""
    processes = []
    ids = set()
    for index in range(count):
        process_id, arrival, burst = values[1 + 3 * index:4 + 3 * index]
        if (not 0 <= process_id <= 63 or process_id in ids
                or not 0 <= arrival <= 1_000_000 or not 1 <= burst <= 1_000_000):
            return -2, b""
        ids.add(process_id)
        processes.append((process_id, arrival, burst))
    processes.sort(key=lambda process: (process[1], process[0]))
    elapsed = 0
    output = bytearray()
    for process_id, arrival, burst in processes:
        elapsed = max(elapsed, arrival) + burst
        completion = elapsed
        turnaround = completion - arrival
        waiting = turnaround - burst
        for value in (process_id, arrival, burst, completion, turnaround, waiting):
            output.extend(value.to_bytes(8, "little", signed=True))
    return count, bytes(output)


def encode(values: list[int], result: int, output: bytes) -> str:
    values_text = "" if not values else " " + " ".join(map(str, values))
    encoded = output.hex() if output else "-"
    return f"{len(values)} {result} {len(output)}{values_text} {encoded}\n"


def corpus(workload: dict) -> tuple[str, int]:
    records: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        expected = oracle(values)
        if case["expected_result"] != expected[0] or case["expected_output_hex"] != expected[1].hex():
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        records[tuple(values)] = expected

    # Exhaust small schedules, including all input permutations and arrival ties.
    for count in range(4):
        if count == 0:
            values = [0]
            records[tuple(values)] = oracle(values)
            continue
        for ids in itertools.permutations(range(3), count):
            for arrivals in itertools.product(range(3), repeat=count):
                for bursts in itertools.product(range(1, 4), repeat=count):
                    values = [count]
                    for process in range(count):
                        values.extend((ids[process], arrivals[process], bursts[process]))
                    records[tuple(values)] = oracle(values)

    rng = random.Random(20261015)
    for _ in range(256):
        count = rng.randrange(0, 65)
        ids = rng.sample(range(64), count)
        values = [count]
        for process_id in ids:
            values.extend((process_id, rng.randrange(0, 1_000_001), rng.randrange(1, 1_000_001)))
        records[tuple(values)] = oracle(values)

    for values in ([], [0, 0], [-1], [65], [1, -1, 0, 1], [1, 64, 0, 1],
                   [1, 0, -1, 1], [1, 0, 0, 0], [1, 0, 0, 1_000_001],
                   [2, 1, 0, 1, 1, 2, 1], [2, 0, 0, 1], [1, 0, 0, 1, 9]):
        records[tuple(values)] = oracle(values)

    lines = [f"{len(records) + 1}\n"]
    lines.extend(encode(list(values), result, output)
                 for values, (result, output) in sorted(records.items()))
    # A valid one-process schedule must reject an output capacity of zero.
    lines.append(encode([1, 0, 0, 1], -2, b""))
    return "".join(lines), len(records) + 1


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    link_shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
                  if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output",
                     extra_link_sources=link_shims)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    checked_count = json.loads(checked.stdout)["cases_checked"]
    if checked_count != case_count:
        raise RuntimeError(f"checker consumed {checked_count} of {case_count} cases")
    return {"language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output/fcfs_scheduling")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/f/fcfs_scheduling/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} checker cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages)
              and all(item["status"] == "passed" for item in results),
              "corpus_sha256": sha256_file(corpus_path),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
