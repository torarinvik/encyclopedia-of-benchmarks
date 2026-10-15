#!/usr/bin/env python3
"""Verify all caller-buffered indexed-tree inorder traversal implementations."""

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

ALGORITHM = "binary_tree_inorder_traversal"
MAX_NODE_COUNT = 100
MIN_VALUE, MAX_VALUE = -100, 100
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(nodes: list[list[int]], root: int, capacity: int | None = None) -> tuple[int, list[int]]:
    if not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT or type(root) is not int:
        return -1, []
    count = len(nodes)
    output_capacity = count if capacity is None else capacity
    if type(output_capacity) is not int or output_capacity < count or output_capacity > MAX_NODE_COUNT:
        return -1, []
    if count == 0:
        return (0, []) if root == -1 else (-1, [])
    if not 0 <= root < count:
        return -1, []
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in row)):
            return -1, []
        value, left, right = row
        if not MIN_VALUE <= value <= MAX_VALUE:
            return -1, []
        for child in (left, right):
            if child < -1 or child >= count:
                return -1, []
            if child >= 0:
                parents[child] += 1
    if parents[root] != 0 or any(parents[index] != 1 for index in range(count) if index != root):
        return -1, []
    result: list[int] = []
    stack: list[int] = []
    current = root
    seen: set[int] = set()
    while current != -1 or stack:
        while current != -1:
            if current in seen:
                return -1, []
            seen.add(current)
            stack.append(current)
            current = nodes[current][1]
        current = stack.pop()
        value, _, right = nodes[current]
        result.append(value)
        current = right
    if len(seen) != count:
        return -1, []
    return len(result), result


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
    nodes: list[list[int]] = []

    def add(item: object) -> int:
        if item is None:
            return -1
        index = len(nodes)
        nodes.append([index - 50, -1, -1])
        left, right = item
        nodes[index][1] = add(left)
        nodes[index][2] = add(right)
        return index

    add(shape)
    return nodes


def random_tree(rng: random.Random, count: int, *, chain: bool = False) -> tuple[list[list[int]], int]:
    if count == 0:
        return [], -1
    nodes = [[rng.randint(MIN_VALUE, MAX_VALUE), -1, -1] for _ in range(count)]
    available = [(0, 1), (0, 2)]
    for node in range(1, count):
        if chain:
            parent, side = node - 1, 1
            available.remove((parent, side))
        else:
            position = rng.randrange(len(available))
            parent, side = available.pop(position)
        nodes[parent][side] = node
        available.extend(((node, 1), (node, 2)))
    order = list(range(count))
    rng.shuffle(order)
    new_index = {old: new for new, old in enumerate(order)}
    reordered = [[nodes[old][0], -1 if nodes[old][1] < 0 else new_index[nodes[old][1]],
                  -1 if nodes[old][2] < 0 else new_index[nodes[old][2]]] for old in order]
    return reordered, new_index[0]


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[tuple[int, ...], ...], int, int], tuple[int, list[int]]] = {}

    def add(nodes: list[list[int]], root: int, capacity: int | None = None) -> None:
        actual_capacity = len(nodes) if capacity is None else capacity
        key = (tuple(tuple(row) for row in nodes), root, actual_capacity)
        cases[key] = oracle(nodes, root, actual_capacity)

    for count in range(8):
        for shape in tree_shapes(count):
            nodes = pack_shape(shape)
            add(nodes, -1 if count == 0 else 0)

    rng = random.Random(20261015)
    for count in (1, 2, 3, 7, 31, 63, MAX_NODE_COUNT):
        for _ in range(8 if count < 64 else 3):
            nodes, root = random_tree(rng, count)
            add(nodes, root)
    maximum, root = random_tree(rng, MAX_NODE_COUNT)
    add(maximum, root)
    chain, chain_root = random_tree(rng, MAX_NODE_COUNT, chain=True)
    add(chain, chain_root)

    for case in workload["cases"]:
        capacity = case.get("output_capacity", len(case["nodes"]))
        expected = oracle(case["nodes"], case["root_index"], capacity)
        if (case["expected_result"] != expected[0]
                or case["expected_output_values"] != expected[1]):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(case["nodes"], case["root_index"], capacity)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for (nodes, root, capacity), (expected_result, expected_values) in records:
        flat = [value for row in nodes for value in row]
        suffix = "" if not flat else " " + " ".join(map(str, flat))
        outputs = "" if not expected_values else " " + " ".join(map(str, expected_values))
        lines.append(f"{len(nodes)} {root} {expected_result} {len(expected_values)} {capacity}"
                     f"{suffix}{outputs}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_value_output")
    checker = manifest["binaries"]["tree_value_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"tree output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_tree_value_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        flattened = [value for row in case["nodes"] for value in row]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != flattened
                or record["workload"]["root_index"] != case["root_index"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["measurement"]["observed_output_values"] != case["expected_output_values"]
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
    workload = json.loads((ROOT / "benchmarks/b/binary_tree_inorder_traversal/workload.json").read_text(encoding="utf-8"))
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
