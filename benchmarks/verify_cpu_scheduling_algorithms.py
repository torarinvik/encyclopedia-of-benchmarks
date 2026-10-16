#!/usr/bin/env python3
"""Compile and check CPU scheduling ports against an independent oracle."""

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
from cpu_scheduling_algorithms_oracle import expected_output

ALGORITHM = "cpu_scheduling_algorithms"


def encode(values: list[int], result: int, output: bytes,
           output_capacity: int = 1792, null_input: bool = False) -> str:
    values_text = "" if not values else " " + " ".join(map(str, values))
    encoded = output.hex() if output else "-"
    return (f"{len(values)} {result} {len(output)} {output_capacity} {int(null_input)}"
            f"{values_text} {encoded}\n")


def corpus(workload: dict) -> tuple[str, int]:
    records: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        expected = expected_output(values)
        if case["expected_result"] != expected[0] or case["expected_output_hex"] != expected[1].hex():
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        records[tuple(values)] = expected

    # Exhaust small arrival, burst, priority, and ID-order combinations for all modes.
    for mode in range(6):
        for count in range(3):
            for ids in itertools.permutations(range(3), count):
                for arrivals in itertools.product(range(2), repeat=count):
                    for bursts in itertools.product((1, 2), repeat=count):
                        for priorities in itertools.product((-1, 1), repeat=count):
                            for quantum in (1, 2):
                                values = [mode, count, quantum]
                                for index in range(count):
                                    values.extend((ids[index], arrivals[index], bursts[index], priorities[index]))
                                records[tuple(values)] = expected_output(values)

    rng = random.Random(20261016)
    for _ in range(768):
        mode = rng.randrange(6)
        count = rng.randrange(0, 33)
        quantum = rng.randrange(1, 33)
        identifiers = rng.sample(range(32), count)
        values = [mode, count, quantum]
        for process_id in identifiers:
            values.extend((process_id, rng.randrange(257), rng.randrange(1, 33), rng.randrange(-32, 33)))
        records[tuple(values)] = expected_output(values)

    for values in ([], [0, 0], [6, 0, 1], [0, -1, 1], [0, 33, 1], [5, 0, 0],
                   [0, 1, 2], [0, 2, 2, 1, 0, 1, 0, 1],
                   [0, 1, 2, -1, 0, 1, 0], [0, 1, 2, 32, 0, 1, 0],
                   [0, 1, 2, 0, -1, 1, 0], [0, 1, 2, 0, 257, 1, 0],
                   [0, 1, 2, 0, 0, 0, 0], [0, 1, 2, 0, 0, 33, 0],
                   [3, 1, 2, 0, 0, 1, 33]):
        records[tuple(values)] = expected_output(values)

    lines = [f"{len(records) + 1}\n"]
    lines.extend(encode(list(values), result, output)
                 for values, (result, output) in sorted(records.items()))
    capacity_input = [0, 1, 2, 0, 0, 1, 0]
    capacity_result = expected_output(capacity_input, output_capacity=0)
    lines.append(encode(capacity_input, *capacity_result, output_capacity=0))
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
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/cpu_scheduling_algorithms")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/c/cpu_scheduling_algorithms/workload.json")
                          .read_text(encoding="utf-8"))
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
                print(f"PASS {ALGORITHM}/{language}: {case_count} oracle cases", flush=True)
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
