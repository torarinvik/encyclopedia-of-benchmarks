#!/usr/bin/env python3
"""Verify strict-BST ports against an independent iterative in-order oracle."""

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

ALGORITHM = "validate_bst"
MAX_NODE_COUNT = 1023
VALUE_MIN, VALUE_MAX = -(2**31), 2**31 - 1


def oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 1 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or any(type(value) is not int for value in row)
                or not VALUE_MIN <= row[0] <= VALUE_MAX):
            return -1
        for child in row[1:]:
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
        ordered.append(nodes[current][0])
        current = nodes[current][2]
    if len(seen) != count:
        return -1
    return int(all(ordered[index - 1] < ordered[index] for index in range(1, count)))


@lru_cache(maxsize=None)
def tree_shapes(node_count: int) -> tuple[object, ...]:
    if node_count == 0:
        return (None,)
    return tuple((left, right)
                 for left_count in range(node_count)
                 for left, right in product(tree_shapes(left_count),
                                            tree_shapes(node_count - 1 - left_count)))


def shape_to_rows(shape: object, inorder_values: list[int]) -> list[list[int]]:
    nodes: list[list[int]] = []
    value_index = 0

    def add(item: object) -> int:
        nonlocal value_index
        if item is None:
            return -1
        left_shape, right_shape = item
        index = len(nodes)
        nodes.append([0, -1, -1])
        left = add(left_shape)
        value = inorder_values[value_index]
        value_index += 1
        right = add(right_shape)
        nodes[index] = [value, left, right]
        return index

    add(shape)
    if value_index != len(inorder_values):
        raise ValueError("shape and key list have different sizes")
    return nodes


def permute_indices(nodes: list[list[int]], root: int, rng: random.Random) -> tuple[list[list[int]], int]:
    permutation = rng.sample(range(len(nodes)), len(nodes))
    moved = [[0, -1, -1] for _ in nodes]
    for old_index, (value, left, right) in enumerate(nodes):
        moved[permutation[old_index]] = [
            value,
            -1 if left == -1 else permutation[left],
            -1 if right == -1 else permutation[right],
        ]
    return moved, permutation[root]


def random_tree(node_count: int, rng: random.Random) -> list[list[int]]:
    nodes = [[rng.randint(-100_000, 100_000), -1, -1]]
    available = [(0, 1), (0, 2)]
    for _ in range(node_count - 1):
        slot = rng.randrange(len(available))
        parent, side = available.pop(slot)
        child = len(nodes)
        nodes[parent][side] = child
        nodes.append([rng.randint(-100_000, 100_000), -1, -1])
        available.extend(((child, 1), (child, 2)))
    return nodes


def random_bst(node_count: int, rng: random.Random) -> list[list[int]]:
    values = rng.sample(range(-100_000, 100_001), node_count)
    nodes = [[values[0], -1, -1]]
    for value in values[1:]:
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


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[tuple[int, ...], ...], int], int] = {}

    def add(nodes: list[list[int]], root: int) -> None:
        expected = oracle(nodes, root)
        key = (tuple(tuple(row) for row in nodes), root)
        cases[key] = expected

    for case in workload["cases"]:
        expected = oracle(case["nodes"], case["root_index"])
        if expected != case["expected_result"]:
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["nodes"], case["root_index"])

    add([], -1)
    rng = random.Random(20261015)
    for node_count in range(1, 8):
        for shape in tree_shapes(node_count):
            add(shape_to_rows(shape, list(range(-node_count // 2, -node_count // 2 + node_count))), 0)
            add(shape_to_rows(shape, [7] * node_count), 0)
            add(shape_to_rows(shape, list(range(node_count, 0, -1))), 0)
            add(shape_to_rows(shape, [rng.randint(-5, 5) for _ in range(node_count)]), 0)
        representative = tree_shapes(node_count)[-1]
        moved, moved_root = permute_indices(
            shape_to_rows(representative, list(range(node_count))), 0, rng)
        add(moved, moved_root)

    for node_count in (1, 2, 3, 7, 31, 127, 255, 511, MAX_NODE_COUNT):
        iterations = 16 if node_count <= 127 else 4
        for _ in range(iterations):
            bst = random_bst(node_count, rng)
            add(bst, 0)
            moved, moved_root = permute_indices(bst, 0, rng)
            add(moved, moved_root)
            arbitrary = random_tree(node_count, rng)
            add(arbitrary, 0)

    right_chain = [[index - MAX_NODE_COUNT // 2, -1,
                    index + 1 if index + 1 < MAX_NODE_COUNT else -1]
                   for index in range(MAX_NODE_COUNT)]
    add(right_chain, 0)
    left_chain = [[MAX_NODE_COUNT // 2 - index,
                   index + 1 if index + 1 < MAX_NODE_COUNT else -1, -1]
                  for index in range(MAX_NODE_COUNT)]
    add(left_chain, 0)

    lines = [f"{len(cases)}\n"]
    for (rows, root), expected in cases.items():
        flattened = [value for row in rows for value in row]
        values_text = "" if not flattened else " " + " ".join(map(str, flattened))
        lines.append(f"{len(rows)} {root} {expected}{values_text}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_scalar")
    checker = manifest["binaries"]["tree_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"tree scalar checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_tree_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    rows = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(rows) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, row in zip(workload["cases"], rows):
        flattened = [value for node in case["nodes"] for value in node]
        if (row["algorithm"] != ALGORITHM
                or row["implementation"]["language"] != language
                or row["implementation"]["source_sha256"] != manifest["source_sha256"]
                or row["workload"]["input_values"] != flattened
                or row["workload"]["root_index"] != case["root_index"]
                or row["workload"]["expected_result"] != case["expected_result"]
                or row["measurement"]["observed_result"] != case["expected_result"]
                or len(row["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(rows), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/validate_bst")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/v/validate_bst/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "validate-bst-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, directory / language,
                                   args.elisa_compiler, data, case_count, workload): language
                   for language in args.languages}
        for future in as_completed(futures):
            language = futures[future]
            try:
                result = future.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
