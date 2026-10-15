#!/usr/bin/env python3
"""Check two-tree merging ports against an independent heap-slot oracle."""

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

ALGORITHM = "merge_two_binary_trees"
MAX_TREE_SLOTS = 255
MAX_INPUT_LENGTH = 512
NULL_SLOT = -1_000_001
WORKLOAD_PATH = ROOT / "benchmarks/m/merge_two_binary_trees/workload.json"


def valid_tree(values: tuple[int, ...]) -> bool:
    return (len(values) <= MAX_TREE_SLOTS
            and all(value == NULL_SLOT or -100_000 <= value <= 100_000 for value in values)
            and all(index == 0 or values[(index - 1) // 2] != NULL_SLOT or value == NULL_SLOT
                    for index, value in enumerate(values)))


def oracle(values: tuple[int, ...]) -> tuple[int, bytes]:
    import struct

    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""
    first_count = values[0]
    if not 0 <= first_count <= MAX_TREE_SLOTS:
        return -1, b""
    second_count_position = first_count + 1
    if second_count_position >= len(values):
        return -1, b""
    second_count = values[second_count_position]
    second_start = second_count_position + 1
    if not 0 <= second_count <= MAX_TREE_SLOTS or len(values) != second_start + second_count:
        return -1, b""
    first, second = values[1:second_count_position], values[second_start:]
    if not valid_tree(first) or not valid_tree(second):
        return -1, b""

    merged = []
    for index in range(max(first_count, second_count)):
        left = first[index] if index < first_count else NULL_SLOT
        right = second[index] if index < second_count else NULL_SLOT
        if left == NULL_SLOT and right == NULL_SLOT:
            merged.append(NULL_SLOT)
        else:
            merged.append((0 if left == NULL_SLOT else left) + (0 if right == NULL_SLOT else right))
    while merged and merged[-1] == NULL_SLOT:
        merged.pop()
    node_count = sum(value != NULL_SLOT for value in merged)
    output = struct.pack("<" + "i" * len(merged), *merged) if merged else b""
    return node_count, output


def encode(first: tuple[int, ...], second: tuple[int, ...]) -> tuple[int, ...]:
    return (len(first), *first, len(second), *second)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = oracle(values)

    trees: list[tuple[int, ...]] = [()]
    for length in range(1, 4):
        for slots in product((NULL_SLOT, -1, 0, 1), repeat=length):
            if valid_tree(slots):
                trees.append(tuple(slots))
    for first in trees:
        for second in trees:
            add(encode(first, second))

    rng = random.Random(20261015)
    for _ in range(768):
        first_length = rng.randrange(MAX_TREE_SLOTS + 1)
        second_length = rng.randrange(MAX_TREE_SLOTS + 1)

        def random_tree(length: int) -> tuple[int, ...]:
            slots = []
            for index in range(length):
                if index > 0 and slots[(index - 1) // 2] == NULL_SLOT:
                    slots.append(NULL_SLOT)
                else:
                    slots.append(NULL_SLOT if rng.randrange(4) == 0 else rng.randrange(-100_000, 100_001))
            return tuple(slots)

        add(encode(random_tree(first_length), random_tree(second_length)))

    add(encode(tuple([0] * MAX_TREE_SLOTS), tuple([1] * MAX_TREE_SLOTS)))
    for invalid in (
        (-1, 0), (MAX_TREE_SLOTS + 1, 0), (1, 100_001, 0),
        (4, 1, NULL_SLOT, NULL_SLOT, 2, 0), (1, 5, 0, 99),
    ):
        add(invalid)
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, _output = oracle(values)
        if result != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)

    records = sorted(cases.items())
    records.append((encode((1,), ()), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        result, _output = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/merge_two_binary_trees")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
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
