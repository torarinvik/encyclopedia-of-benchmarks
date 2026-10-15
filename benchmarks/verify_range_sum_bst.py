#!/usr/bin/env python3
"""Verify all indexed-tree Range Sum of BST implementations."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from functools import lru_cache
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "range_sum_bst"
MAX_NODE_COUNT = 1023
MIN_VALUE, MAX_VALUE = 1, 100000


def oracle(nodes: list[list[int]], root_index: int, low: int, high: int) -> int:
    if not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT:
        return -1
    if type(root_index) is not int or type(low) is not int or type(high) is not int:
        return -1
    if not MIN_VALUE <= low <= high <= MAX_VALUE:
        return -1
    count = len(nodes)
    if count == 0:
        return 0 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or any(type(value) is not int for value in row)):
            return -1
        value, left, right = row
        if not MIN_VALUE <= value <= MAX_VALUE:
            return -1
        for child in (left, right):
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1

    seen: set[int] = set()
    total = 0
    stack = [(root_index, MIN_VALUE - 1, MAX_VALUE + 1)]
    while stack:
        node, lower, upper = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        value, left, right = nodes[node]
        if not lower < value < upper:
            return -1
        if low <= value <= high:
            total += value
        if left >= 0:
            stack.append((left, lower, value))
        if right >= 0:
            stack.append((right, value, upper))
    return total if len(seen) == count else -1


@lru_cache(maxsize=None)
def tree_shapes(node_count: int) -> tuple[object, ...]:
    if node_count == 0:
        return (None,)
    shapes = []
    for left_count in range(node_count):
        right_count = node_count - left_count - 1
        for left, right in product(tree_shapes(left_count), tree_shapes(right_count)):
            shapes.append((left, right))
    return tuple(shapes)


def pack_shape(shape: object) -> list[list[int]]:
    if shape is None:
        return []
    nodes: list[list[int]] = []
    inorder_values = iter(range(1, count_shape(shape) + 1))

    def insert(item: object) -> tuple[int, int]:
        if item is None:
            return -1, 0
        left_shape, right_shape = item
        index = len(nodes)
        nodes.append([0, -1, -1])
        left, _ = insert(left_shape)
        value = next(inorder_values)
        right, _ = insert(right_shape)
        nodes[index] = [value, left, right]
        return index, value

    insert(shape)
    return nodes


def count_shape(shape: object) -> int:
    if shape is None:
        return 0
    return 1 + count_shape(shape[0]) + count_shape(shape[1])


def random_bst(rng: random.Random, count: int) -> list[list[int]]:
    keys = rng.sample(range(1, MAX_VALUE + 1), count)
    nodes = [[keys[0], -1, -1]]
    for value in keys[1:]:
        node = 0
        while True:
            branch = 1 if value < nodes[node][0] else 2
            child = nodes[node][branch]
            if child < 0:
                nodes[node][branch] = len(nodes)
                nodes.append([value, -1, -1])
                break
            node = child
    return nodes


def balanced_bst(count: int) -> list[list[int]]:
    nodes: list[list[int]] = []

    def add(first: int, last: int) -> int:
        if first >= last:
            return -1
        middle = (first + last) // 2
        index = len(nodes)
        nodes.append([middle, -1, -1])
        left = add(first, middle)
        right = add(middle + 1, last)
        nodes[index] = [middle, left, right]
        return index

    add(1, count + 1)
    return nodes


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[tuple[int, ...], ...], int, int, int], int] = {}

    def add(nodes: list[list[int]], root: int, low: int, high: int) -> None:
        key = (tuple(tuple(row) for row in nodes), root, low, high)
        cases[key] = oracle(nodes, root, low, high)

    for count in range(8):
        for shape in tree_shapes(count):
            add(pack_shape(shape), -1 if count == 0 else 0, 1, MAX_VALUE)

    rng = random.Random(20261015)
    for count in (1, 2, 3, 7, 31, 127, 255, MAX_NODE_COUNT):
        for _ in range(12 if count < 128 else 3):
            nodes = random_bst(rng, count)
            add(nodes, 0, 1, MAX_VALUE)
            low = rng.randrange(1, MAX_VALUE + 1)
            high = rng.randrange(low, MAX_VALUE + 1)
            add(nodes, 0, low, high)
    add(balanced_bst(MAX_NODE_COUNT), 0, 1, MAX_VALUE)
    add(balanced_bst(MAX_NODE_COUNT), 0, 500, 520)

    for case in workload["cases"]:
        nodes = case["nodes"]
        root, low, high = case["root_index"], case["low"], case["high"]
        expected = oracle(nodes, root, low, high)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(nodes, root, low, high)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for (nodes, root, low, high), expected in records:
        flat = [value for row in nodes for value in row]
        suffix = "" if not flat else " " + " ".join(map(str, flat))
        lines.append(f"{len(nodes)} {root} {low} {high} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_range_sum")
    checker = manifest["binaries"]["tree_range_sum_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"tree range-sum C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_tree_range_sum.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        flat = [value for row in case["nodes"] for value in row]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != flat
                or record["workload"]["root_index"] != case["root_index"]
                or record["workload"]["bounds"] != [case["low"], case["high"]]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build" / ALGORITHM)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/r/range_sum_bst/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
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
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
