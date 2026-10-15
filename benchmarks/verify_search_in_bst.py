#!/usr/bin/env python3
"""Verify the packed indexed-tree Search in a BST implementations."""

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

ALGORITHM = "search_in_bst"
MAX_NODE_COUNT = 5000
MIN_VALUE, MAX_VALUE = 1, 10_000_000


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > 3 + 3 * MAX_NODE_COUNT
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    count, root, target = values[:3]
    if not 0 <= count <= MAX_NODE_COUNT or len(values) != 3 + 3 * count:
        return -1
    if not MIN_VALUE <= target <= MAX_VALUE:
        return -1
    if count == 0:
        return -1
    if not 0 <= root < count:
        return -1
    nodes = [values[3 + 3 * index: 6 + 3 * index] for index in range(count)]
    parents = [0] * count
    for value, left, right in nodes:
        if not MIN_VALUE <= value <= MAX_VALUE:
            return -1
        for child in (left, right):
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root] != 0 or any(parents[index] != 1 for index in range(count) if index != root):
        return -1
    by_value: dict[int, int] = {}
    stack = [(root, MIN_VALUE - 1, MAX_VALUE + 1)]
    seen: set[int] = set()
    while stack:
        node, lower, upper = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        value, left, right = nodes[node]
        if not lower < value < upper:
            return -1
        by_value[value] = node
        if left >= 0:
            stack.append((left, lower, value))
        if right >= 0:
            stack.append((right, value, upper))
    if len(seen) != count:
        return -1
    return by_value.get(target, -1)


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


def pack_shape(shape: object) -> tuple[list[list[int]], int]:
    nodes: list[list[int]] = []
    values = iter(range(1, shape_size(shape) + 1))

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

    root = add(shape)
    return nodes, root


def shape_size(shape: object) -> int:
    return 0 if shape is None else 1 + shape_size(shape[0]) + shape_size(shape[1])


def random_bst(rng: random.Random, count: int) -> tuple[list[list[int]], int]:
    keys = rng.sample(range(MIN_VALUE, MAX_VALUE + 1), count)
    nodes = [[keys[0], -1, -1]]
    for value in keys[1:]:
        node = 0
        while True:
            branch = 1 if value < nodes[node][0] else 2
            child = nodes[node][branch]
            if child == -1:
                nodes[node][branch] = len(nodes)
                nodes.append([value, -1, -1])
                break
            node = child
    return nodes, 0


def encode(nodes: list[list[int]], root: int, target: int) -> list[int]:
    return [len(nodes), root, target, *(value for row in nodes for value in row)]


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(nodes: list[list[int]], root: int, target: int) -> None:
        values = encode(nodes, root, target)
        cases[tuple(values)] = oracle(values)

    for count in range(1, 7):
        for shape in tree_shapes(count):
            nodes, root = pack_shape(shape)
            for value in [row[0] for row in nodes] + [0, count + 1]:
                add(nodes, root, value)

    rng = random.Random(20261015)
    for count in (1, 2, 3, 7, 31, 127, 511, 1023, MAX_NODE_COUNT):
        repetitions = 5 if count < 128 else 2
        for _ in range(repetitions):
            nodes, root = random_bst(rng, count)
            add(nodes, root, nodes[rng.randrange(count)][0])
            add(nodes, root, rng.choice((MIN_VALUE - 1, MAX_VALUE + 1)))
    for case in workload["cases"]:
        values = case["input_values"]
        expected = oracle(values)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[tuple(values)] = expected

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array scalar ABI check failed: {checked.stderr}")
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
        values = case["input_values"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build" / ALGORITHM)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/s/search_in_bst/workload.json").read_text(encoding="utf-8"))
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
