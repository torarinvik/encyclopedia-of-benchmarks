#!/usr/bin/env python3
"""Verify indexed BST iterator ports against an independent in-order oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from functools import lru_cache
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "bst_iterator"
MAX_NODE_COUNT = 1023
VALUE_MIN, VALUE_MAX = -100_000, 100_000


def oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if count > MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 0 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row):
            return -1
        value, left, right = row
        if not VALUE_MIN <= value <= VALUE_MAX:
            return -1
        for child in (left, right):
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1

    stack: list[int] = []
    current = root_index
    seen: set[int] = set()
    ordered: list[int] = []
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
    if len(seen) != count or any(ordered[index - 1] >= ordered[index]
                                 for index in range(1, count)):
        return -1
    return sum((index + 1) * (value + 100_001) for index, value in enumerate(ordered))


@lru_cache(maxsize=None)
def shapes(node_count: int) -> tuple:
    if node_count == 0:
        return (None,)
    return tuple((left, right)
                 for left_count in range(node_count)
                 for left in shapes(left_count)
                 for right in shapes(node_count - 1 - left_count))


def shape_to_rows(shape) -> list[list[int]]:
    nodes: list[list[int]] = []

    def visit(current) -> int:
        if current is None:
            return -1
        index = len(nodes)
        nodes.append([0, -1, -1])
        nodes[index][1] = visit(current[0])
        nodes[index][2] = visit(current[1])
        return index

    root = visit(shape)
    next_value = 0

    def assign(node: int) -> None:
        nonlocal next_value
        if node < 0:
            return
        assign(nodes[node][1])
        nodes[node][0] = next_value - 100
        next_value += 1
        assign(nodes[node][2])

    assign(root)
    return nodes


def random_bst(rng: random.Random, size: int) -> list[list[int]]:
    values = rng.sample(range(VALUE_MIN, VALUE_MAX + 1), size)
    if not values:
        return []
    nodes = [[values[0], -1, -1]]
    for value in values[1:]:
        node = 0
        while True:
            side = 1 if value < nodes[node][0] else 2
            child = nodes[node][side]
            if child == -1:
                child = len(nodes)
                nodes[node][side] = child
                nodes.append([value, -1, -1])
                break
            node = child
    return nodes


def permute_ids(nodes: list[list[int]], root: int, rng: random.Random) -> tuple[list[list[int]], int]:
    permutation = list(range(len(nodes)))
    rng.shuffle(permutation)
    remapped: list[list[int] | None] = [None] * len(nodes)
    for old, (value, left, right) in enumerate(nodes):
        remapped[permutation[old]] = [value,
                                      permutation[left] if left >= 0 else -1,
                                      permutation[right] if right >= 0 else -1]
    return [row for row in remapped if row is not None], permutation[root] if root >= 0 else -1


def corpus(workload: dict) -> tuple[str, int]:
    cases: list[tuple[list[list[int]], int, int]] = []
    seen: set[tuple] = set()

    def add(nodes: list[list[int]], root: int, expected: int | None = None) -> None:
        result = oracle(nodes, root) if expected is None else expected
        key = (root, tuple(tuple(row) for row in nodes), result)
        if key not in seen:
            seen.add(key)
            cases.append((nodes, root, result))

    for case in workload["cases"]:
        expected = oracle(case["nodes"], case["root_index"])
        if expected != case["expected_result"]:
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["nodes"], case["root_index"], expected)

    add([], -1)
    add([], 0)
    for node_count in range(1, 9):
        for shape in shapes(node_count):
            add(shape_to_rows(shape), 0)

    rng = random.Random(20261015)
    for _ in range(384):
        size = rng.randrange(1, 257)
        nodes = random_bst(rng, size)
        add(nodes, 0)
        if size > 1 and _ % 3 == 0:
            shuffled, root = permute_ids(nodes, 0, rng)
            add(shuffled, root)

    for values in (list(range(-511, 512)), list(range(511, -512, -1))):
        nodes = [[value, -1, -1] for value in values]
        for index in range(len(nodes) - 1):
            nodes[index][2 if values[index] < values[index + 1] else 1] = index + 1
        add(nodes, 0)

    one = [[5, -1, -1]]
    add(one, 1)
    add([[5, -2, -1]], 0)
    add([[5, 1, -1]], 0)
    add([[5, -1, -1], [4, -1, -1]], 0)
    add([[5, -1, -1], [5, -1, -1]], 0)
    add([[5, -1, -1], [6, -1, -1]], 0)
    add([[5, 1, -1], [4, 0, -1]], 0)

    lines = [f"{len(cases)}\n"]
    for nodes, root, expected in cases:
        flattened = [value for row in nodes for value in row]
        payload = "" if not flattened else " " + " ".join(map(str, flattened))
        lines.append(f"{len(nodes)} {root} {expected}{payload}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_scalar")
    checker = manifest["binaries"]["tree_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"tree scalar checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete BST iterator corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_tree_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/bst_iterator")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/b/bst_iterator/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "bst_iterator-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
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
