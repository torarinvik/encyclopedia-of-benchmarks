#!/usr/bin/env python3
"""Verify LCA ports against a parent-set oracle on packed binary trees."""

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
from run_i64_array_scalar import encode_case

ALGORITHM = "lowest_common_ancestor"
MAX_NODE_COUNT = 1023
VALUE_MIN, VALUE_MAX = -1_000_000_000, 1_000_000_000
MAX_INPUT_LENGTH = 4 + 3 * MAX_NODE_COUNT
WORKLOAD_PATH = ROOT / "benchmarks/l/lowest_common_ancestor/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    count, root, p, q = values[:4]
    if not 2 <= count <= MAX_NODE_COUNT or len(values) != 4 + 3 * count:
        return -1
    if any(not 0 <= index < count for index in (root, p, q)) or p == q:
        return -1

    nodes = [values[offset:offset + 3] for offset in range(4, len(values), 3)]
    parent = [-1] * count
    seen_values: set[int] = set()
    for node, (value, left, right) in enumerate(nodes):
        if not VALUE_MIN <= value <= VALUE_MAX or value in seen_values:
            return -1
        seen_values.add(value)
        for child in (left, right):
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                if parent[child] != -1:
                    return -1
                parent[child] = node
    if parent[root] != -1 or any(parent[node] == -1 for node in range(count) if node != root):
        return -1

    reached: set[int] = set()
    stack = [root]
    while stack:
        node = stack.pop()
        if node in reached:
            return -1
        reached.add(node)
        _value, left, right = nodes[node]
        if left >= 0:
            stack.append(left)
        if right >= 0:
            stack.append(right)
    if len(reached) != count:
        return -1

    p_ancestors: set[int] = set()
    node = p
    while node >= 0:
        p_ancestors.add(node)
        node = parent[node]
    node = q
    while node not in p_ancestors:
        node = parent[node]
    return node


@lru_cache(maxsize=None)
def shapes(node_count: int) -> tuple:
    if node_count == 0:
        return (None,)
    return tuple((left, right)
                 for left_count in range(node_count)
                 for left in shapes(left_count)
                 for right in shapes(node_count - 1 - left_count))


def shape_to_nodes(shape) -> list[list[int]]:
    nodes: list[list[int]] = []

    def add(node_shape) -> int:
        if node_shape is None:
            return -1
        index = len(nodes)
        nodes.append([index - 100, -1, -1])
        nodes[index][1] = add(node_shape[0])
        nodes[index][2] = add(node_shape[1])
        return index

    add(shape)
    return nodes


def pack(nodes: list[list[int]], root: int, p: int, q: int) -> list[int]:
    return [len(nodes), root, p, q, *(value for row in nodes for value in row)]


def random_tree(node_count: int, rng: random.Random) -> tuple[list[list[int]], int]:
    values = rng.sample(range(VALUE_MIN, VALUE_MAX + 1), node_count)
    nodes = [[value, -1, -1] for value in values]
    available = [(0, 1), (0, 2)]
    for child in range(1, node_count):
        slot = rng.randrange(len(available))
        parent, side = available.pop(slot)
        nodes[parent][side] = child
        available.extend(((child, 1), (child, 2)))

    permutation = list(range(node_count))
    rng.shuffle(permutation)
    old_to_new = [0] * node_count
    for new_index, old_index in enumerate(permutation):
        old_to_new[old_index] = new_index
    reordered = [[0, -1, -1] for _ in range(node_count)]
    for old_index, (value, left, right) in enumerate(nodes):
        new_index = old_to_new[old_index]
        reordered[new_index] = [value,
                                old_to_new[left] if left >= 0 else -1,
                                old_to_new[right] if right >= 0 else -1]
    return reordered, old_to_new[0]


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))

    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(values)] = expected

    for node_count in range(2, 8):
        for shape in shapes(node_count):
            nodes = shape_to_nodes(shape)
            for p in range(node_count):
                for q in range(node_count):
                    if p != q:
                        add(pack(nodes, 0, p, q))

    rng = random.Random(20261015)
    for _ in range(384):
        node_count = rng.randint(2, MAX_NODE_COUNT)
        nodes, root = random_tree(node_count, rng)
        p, q = rng.sample(range(node_count), 2)
        add(pack(nodes, root, p, q))

    small = [[10, 1, -1], [20, -1, -1]]
    for invalid in (
        [], [1, 0, 0, 1, 10, -1, -1],
        [MAX_NODE_COUNT + 1, 0, 1, 2],
        pack(small, 2, 0, 1), pack(small, 0, 2, 1), pack(small, 0, 0, 0),
        [2, 0, 0, 1, 10, 99, -1, 20, -1, -1],
        [2, 0, 0, 1, 10, 1, 1, 20, -1, -1],
        [3, 0, 1, 2, 10, -1, -1, 20, 2, -1, 30, 1, -1],
        [2, 0, 0, 1, 10, 1, -1, 20, 0, -1],
        [2, 0, 0, 1, VALUE_MIN - 1, -1, -1, 20, -1, -1],
        [2, 0, 0, 1, 10, -1, -1, 10, -1, -1],
        [2, 0, 0, 1, 10, -2, -1, 20, -1, -1],
        [2, 0, 0, 1, 10, -1, -1, 20, -1, -1, 0],
    ):
        add(invalid)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{values_text}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"i64-array C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/lowest_common_ancestor")
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
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
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
