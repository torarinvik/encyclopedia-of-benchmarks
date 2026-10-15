#!/usr/bin/env python3
"""Verify all indexed-tree Kth Smallest in BST implementations."""

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

ALGORITHM = "kth_smallest_bst"
MAX_NODE_COUNT = 1023
MIN_VALUE, MAX_VALUE = 0, 10000


def oracle(nodes: list[list[int]], root_index: int, k: int) -> int:
    if not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT:
        return -1
    if type(root_index) is not int or type(k) is not int:
        return -1
    count = len(nodes)
    if count == 0 or not 1 <= k <= count or not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row):
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
    ordered: list[int] = []
    stack: list[int] = []
    current = root_index
    seen: set[int] = set()
    while current != -1 or stack:
        while current != -1:
            if current in seen:
                return -1
            seen.add(current)
            stack.append(current)
            current = nodes[current][1]
        current = stack.pop()
        value, _, right = nodes[current]
        ordered.append(value)
        current = right
    if len(seen) != count or any(ordered[index - 1] >= ordered[index]
                                 for index in range(1, count)):
        return -1
    return ordered[k - 1]


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


def shape_size(shape: object) -> int:
    return 0 if shape is None else 1 + shape_size(shape[0]) + shape_size(shape[1])


def pack_shape(shape: object) -> list[list[int]]:
    nodes: list[list[int]] = []
    values = iter(range(shape_size(shape)))

    def add(item: object) -> int:
        if item is None:
            return -1
        left_shape, right_shape = item
        index = len(nodes)
        nodes.append([0, -1, -1])
        left = add(left_shape)
        value = next(values)
        right = add(right_shape)
        nodes[index] = [value, left, right]
        return index

    add(shape)
    return nodes


def random_bst(rng: random.Random, count: int) -> list[list[int]]:
    keys = rng.sample(range(MIN_VALUE, MAX_VALUE + 1), count)
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

    add(0, count)
    return nodes


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[tuple[int, ...], ...], int, int], int] = {}

    def add(nodes: list[list[int]], root: int, k: int) -> None:
        key = (tuple(tuple(row) for row in nodes), root, k)
        cases[key] = oracle(nodes, root, k)

    for count in range(8):
        for shape in tree_shapes(count):
            nodes = pack_shape(shape)
            for k in range(1, count + 1):
                add(nodes, 0, k)

    rng = random.Random(20261015)
    for count in (1, 2, 3, 7, 31, 127, 255, MAX_NODE_COUNT):
        for _ in range(10 if count < 128 else 3):
            nodes = random_bst(rng, count)
            for k in {1, (count + 1) // 2, count, rng.randrange(1, count + 1)}:
                add(nodes, 0, k)
    maximum = balanced_bst(MAX_NODE_COUNT)
    for k in (1, MAX_NODE_COUNT // 2, MAX_NODE_COUNT):
        add(maximum, 0, k)
    left_chain = [[MAX_NODE_COUNT - index - 1,
                   index + 1 if index + 1 < MAX_NODE_COUNT else -1, -1]
                  for index in range(MAX_NODE_COUNT)]
    add(left_chain, 0, 1)
    add(left_chain, 0, MAX_NODE_COUNT)

    for case in workload["cases"]:
        expected = oracle(case["nodes"], case["root_index"], case["k"])
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(case["nodes"], case["root_index"], case["k"])

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for (nodes, root, k), expected in records:
        flat = [value for row in nodes for value in row]
        suffix = "" if not flat else " " + " ".join(map(str, flat))
        lines.append(f"{len(nodes)} {root} {k} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_rank")
    checker = manifest["binaries"]["tree_rank_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"tree-rank C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_tree_rank.py"),
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
                or record["workload"]["k"] != case["k"]
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
    workload = json.loads((ROOT / "benchmarks/k/kth_smallest_bst/workload.json").read_text(encoding="utf-8"))
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
