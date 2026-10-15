#!/usr/bin/env python3
"""Check Trim BST ports against a recursive tree-trimming oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import permutations
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_tree_trim import encode_case, oracle

ALGORITHM = "trim_bst"
MAX_NODE_COUNT = 100
MAX_OUTPUT_VALUES = 1 + 3 * MAX_NODE_COUNT
WORKLOAD_PATH = ROOT / "benchmarks/t/trim_bst/workload.json"


def bst_from_insertion(values: tuple[int, ...] | list[int]) -> tuple[list[list[int]], int]:
    if not values:
        return [], -1
    nodes = [[value, -1, -1] for value in values]
    root = 0
    for new_index in range(1, len(values)):
        current = root
        while True:
            side = 1 if values[new_index] < nodes[current][0] else 2
            child = nodes[current][side]
            if child == -1:
                nodes[current][side] = new_index
                break
            current = child
    return nodes, root


def case_key(nodes: list[list[int]], root: int, low: int, high: int, capacity: int) -> tuple:
    return (tuple(value for row in nodes for value in row), root, low, high, capacity)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple, tuple[int, tuple[int, ...]]] = {}

    def add(nodes: list[list[int]], root: int, low: int, high: int,
            capacity: int | None = None) -> None:
        if capacity is None:
            capacity = 1 + 3 * len(nodes)
        result, output = oracle(nodes, root, low, high, capacity)
        cases[case_key(nodes, root, low, high, capacity)] = (result, tuple(output))

    for item in workload["cases"]:
        flattened, expected_output, _ = encode_case(item)
        expected_result, oracle_output = oracle(item["nodes"], item["root_index"],
                                                item["low"], item["high"],
                                                item["output_capacity"])
        if (item["expected_result"] != expected_result or expected_output != oracle_output):
            raise ValueError(f"workload oracle mismatch: {item['id']}")
        cases[case_key(item["nodes"], item["root_index"], item["low"], item["high"],
                        item["output_capacity"])] = (expected_result, tuple(expected_output))

    for size in range(1, 6):
        for order in permutations(range(1, size + 1)):
            nodes, root = bst_from_insertion(order)
            for low in range(1, size + 1):
                for high in range(low, size + 1):
                    add(nodes, root, low, high)
            add(nodes, root, 1, 10000)
            add(nodes, root, 1, 10000, 0)

    malformed: list[tuple[list[list[int]], int, int, int]] = [
        ([], 0, 1, 10000),
        ([[5, 1, -1]], 0, 1, 10000),
        ([[5, -1, -1]], -1, 1, 10),
        ([[5, 1, -1], [8, -1, -1]], 0, 1, 10),
        ([[5, 1, -1], [5, -1, -1]], 0, 1, 10),
        ([[5, 1, -1], [3, -1, -1], [7, -1, -1]], 0, 10001, 10001),
        ([[5, 1, -1], [3, -1, -1]], 0, 9, 2),
        ([[0, -1, -1]], 0, 1, 10000),
        ([[10001, -1, -1]], 0, 1, 10000),
        ([[5, 2, -1], [3, -1, -1]], 0, 1, 10),
    ]
    for nodes, root, low, high in malformed:
        add(nodes, root, low, high)

    rng = random.Random(20261015)
    for _ in range(256):
        size = rng.randint(1, MAX_NODE_COUNT)
        values = rng.sample(range(1, 10001), size)
        nodes, root = bst_from_insertion(values)
        first, second = sorted((rng.randint(1, 10000), rng.randint(1, 10000)))
        add(nodes, root, first, second)
    for size in (1, 10, 50, 100):
        nodes, root = bst_from_insertion(list(range(1, size + 1)))
        add(nodes, root, 1, size)
        add(nodes, root, max(1, size // 2), size, 1)

    lines = [str(len(cases)) + "\n"]
    for (flattened, root, low, high, capacity), (result, output) in sorted(cases.items()):
        node_count = len(flattened) // 3
        header = [node_count, root, low, high, result, len(output), capacity]
        lines.append(" ".join(map(str, [*header, *flattened, *output])) + "\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_trim")
    checker = manifest["binaries"]["tree_trim_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"tree-trim C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_tree_trim.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                               text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"tree-trim workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        flattened = [value for row in case["nodes"] for value in row]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(case["nodes"])
                or record["workload"]["input_values"] != flattened
                or record["workload"]["root_index"] != case["root_index"]
                or record["workload"]["low"] != case["low"]
                or record["workload"]["high"] != case["high"]
                or record["workload"]["expected_output_values"] != case["expected_output_values"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/trim_bst")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "trim_bst-corpus.txt").write_text(data, encoding="utf-8")

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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle trees, "
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
