#!/usr/bin/env python3
"""Verify both pinned triplet_sum implementations across the target languages."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import permutations, product
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output, fnv1a

ALGORITHMS = ("triplet_sum", "triplet_sum_two_pointer")
MAX_ITEMS = {"triplet_sum": 10, "triplet_sum_two_pointer": 1024}
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def validate(values: tuple[int, ...] | list[int], algorithm: str) -> tuple[int, list[int], int] | None:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_ITEMS[algorithm] + 1
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None
    target, items = values[0], list(values[1:])
    if not -3_000_000 <= target <= 3_000_000:
        return None
    if any(not -1_000_000 <= value <= 1_000_000 for value in items):
        return None
    return target, items, len(items)


def permutation_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    import struct

    parsed = validate(values, "triplet_sum")
    if parsed is None:
        return -1, b""
    target, items, _ = parsed
    answer = (0, 0, 0)
    for triplet in permutations(items, 3):
        if sum(triplet) == target:
            answer = tuple(sorted(triplet))
            break
    return 3, struct.pack("<qqq", *answer)


def two_pointer_oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    parsed = validate(values, "triplet_sum_two_pointer")
    if parsed is None:
        return -1, b""
    target, items, _ = parsed
    ordered = sorted(items)
    answer = (0, 0, 0)
    found = False
    for first in range(len(ordered) - 1):
        left, right = first + 1, len(ordered) - 1
        while left < right:
            total = ordered[first] + ordered[left] + ordered[right]
            if total == target:
                answer = (ordered[first], ordered[left], ordered[right])
                found = True
                break
            if total < target:
                left += 1
            else:
                right -= 1
        if found:
            break
    return 3, struct.pack("<qqq", *answer)


ORACLES = {"triplet_sum": permutation_oracle,
           "triplet_sum_two_pointer": two_pointer_oracle}


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    oracle = ORACLES[algorithm]
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...] | list[int], capacity: int = 24) -> None:
        packed = tuple(values)
        result, output = oracle(packed)
        runner_result = expected_output(list(packed), algorithm)
        if runner_result != (result, output):
            raise ValueError(f"independent and recorder oracles disagree for {algorithm}: {packed[:12]}")
        if result >= 0 and capacity < 24:
            result, output = -2, b""
        cases[(packed, capacity)] = (result, output)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = oracle(values)
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != result
                or case.get("expected_output_hex") != output.hex()):
            raise ValueError(f"published workload disagrees with independent oracle: {case['id']}")
        add(values)

    values_range = range(-2, 3)
    target_range = range(-5, 6)
    for item_count in range(6):
        for items in product(values_range, repeat=item_count):
            for target in target_range:
                add((target, *items))

    rng = random.Random(20261015 if algorithm == "triplet_sum" else 20261016)
    random_cases = 512 if algorithm == "triplet_sum" else 384
    random_max = MAX_ITEMS[algorithm] if algorithm == "triplet_sum" else 120
    for _ in range(random_cases):
        item_count = rng.randrange(random_max + 1)
        items = [rng.randrange(-100, 101) for _ in range(item_count)]
        if items and rng.randrange(2):
            target = sum(rng.sample(items, min(3, item_count))) if item_count >= 3 else rng.randrange(-250, 251)
        else:
            target = rng.randrange(-250, 251)
        add((target, *items))

    if algorithm == "triplet_sum_two_pointer":
        add((-3, *([1] * 1024)))  # maximal input with no match
        add((3, *([1] * 1024)))  # maximal input with an immediate match

    invalid_cases = [
        (),
        (I64_MIN,), (I64_MAX,), (-3_000_001,), (3_000_001,),
        (0, -1_000_001), (0, 1_000_001),
        (0, *([0] * (MAX_ITEMS[algorithm] + 1))),
    ]
    for values in invalid_cases:
        add(values)
    add((1, 2, 3), capacity=23)

    records = sorted(cases.items(), key=lambda item: (len(item[0][0]), item[0][0], item[0][1]))
    lines = [f"{len(records)}\n"]
    for (values, capacity), (result, output) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)} {capacity}{suffix} {encoded}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=240)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full independent oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=240)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    oracle = ORACLES[algorithm]
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected, output_bytes = oracle(values)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or record["measurement"]["result_checksum"] != fnv1a(output_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result or provenance mismatch: {case['id']}")
    return {
        "algorithm": algorithm, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "workload_records": len(records), "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output), "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/triplet_sum")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    results = []
    for algorithm in ALGORITHMS:
        workload_path = ROOT / "benchmarks/t" / algorithm / "workload.json"
        workload = json.loads(workload_path.read_text(encoding="utf-8"))
        data, case_count = corpus(algorithm, workload)
        group_dir = args.build_dir.resolve() / algorithm
        group_dir.mkdir(parents=True, exist_ok=True)
        (group_dir / "corpus.txt").write_text(data, encoding="utf-8")
        with ThreadPoolExecutor(max_workers=args.jobs) as executor:
            jobs = {
                executor.submit(verify, algorithm, language, group_dir / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages
            }
            for job in as_completed(jobs):
                language = jobs[job]
                try:
                    result = job.result()
                except Exception as error:
                    results.append({"algorithm": algorithm, "language": language,
                                    "status": "failed", "error": str(error)})
                    print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                else:
                    results.append(result)
                    print(f"PASS {algorithm}/{language}: {case_count} oracle inputs, "
                          f"{result['workload_records']} workload records", flush=True)

    report = {
        "algorithms": list(ALGORITHMS),
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(ALGORITHMS) * len(args.languages)
                      and all(item["status"] == "passed" for item in results),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda item: (item["algorithm"], item["language"])),
    }
    report_path = args.build_dir.resolve() / "verification.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
