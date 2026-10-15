#!/usr/bin/env python3
"""Check all symmetry ports against an independent iterative pair oracle."""

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

ALGORITHM = "symmetric_tree"
MAX_NODE_COUNT = 1023
I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if count > MAX_NODE_COUNT or type(root_index) is not int:
        raise ValueError("invalid tree size or root type")
    if count == 0:
        return 1 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or type(row[0]) is not int or not I32_MIN <= row[0] <= I32_MAX):
            raise ValueError("invalid node row")
        for child in row[1:]:
            if type(child) is not int or child < -1 or child >= count:
                return -1
            if child != -1:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                        if index != root_index):
        return -1
    queue = [root_index]
    seen = set()
    while queue:
        node = queue.pop()
        if node in seen:
            return -1
        seen.add(node)
        queue.extend(child for child in nodes[node][1:] if child != -1)
    if len(seen) != count:
        return -1

    # Iterative mirror-pair traversal keeps this oracle independent of the recursive ports.
    pairs = [(nodes[root_index][1], nodes[root_index][2])]
    while pairs:
        left, right = pairs.pop()
        if left == -1 or right == -1:
            if left != right:
                return 0
            continue
        if nodes[left][0] != nodes[right][0]:
            return 0
        pairs.append((nodes[left][1], nodes[right][2]))
        pairs.append((nodes[left][2], nodes[right][1]))
    return 1


@lru_cache(maxsize=None)
def shapes(node_count: int) -> tuple:
    if node_count == 0:
        return (None,)
    return tuple((left, right)
                 for left_count in range(node_count)
                 for left in shapes(left_count)
                 for right in shapes(node_count - 1 - left_count))


def shape_to_rows(shape, value_for_index) -> list[list[int]]:
    rows: list[list[int]] = []

    def add(node_shape) -> int:
        if node_shape is None:
            return -1
        index = len(rows)
        rows.append([value_for_index(index), -1, -1])
        left = add(node_shape[0])
        right = add(node_shape[1])
        rows[index][1] = left
        rows[index][2] = right
        return index

    add(shape)
    return rows


def nested_to_rows(tree) -> list[list[int]]:
    rows: list[list[int]] = []

    def add(node) -> int:
        if node is None:
            return -1
        index = len(rows)
        rows.append([node[0], -1, -1])
        rows[index][1] = add(node[1])
        rows[index][2] = add(node[2])
        return index

    add(tree)
    return rows


def random_tree(node_count: int, rng: random.Random) -> list[list[int]]:
    nodes = [[rng.randint(I32_MIN, I32_MAX), -1, -1]]
    slots = [(0, 1), (0, 2)]
    for _ in range(node_count - 1):
        slot_index = rng.randrange(len(slots))
        parent, side = slots.pop(slot_index)
        child = len(nodes)
        nodes[parent][side] = child
        nodes.append([rng.randint(I32_MIN, I32_MAX), -1, -1])
        slots.extend(((child, 1), (child, 2)))
    return nodes


def mirrored_tree(shape, rng: random.Random):
    def make(node_shape):
        if node_shape is None:
            return None
        return [rng.randint(I32_MIN, I32_MAX), make(node_shape[0]), make(node_shape[1])]

    def mirror(node):
        if node is None:
            return None
        return [node[0], mirror(node[2]), mirror(node[1])]

    left = make(shape)
    return [rng.randint(I32_MIN, I32_MAX), left, mirror(left)]


def corpus(workload: dict) -> tuple[str, int]:
    cases: list[tuple[list[list[int]], int, int]] = []
    seen: set[tuple] = set()

    def add(nodes: list[list[int]], root: int) -> None:
        expected = oracle(nodes, root)
        key = (root, tuple(tuple(row) for row in nodes), expected)
        if key not in seen:
            seen.add(key)
            cases.append((nodes, root, expected))

    for case in workload["cases"]:
        expected = oracle(case["nodes"], case["root_index"])
        if expected != case["expected_result"]:
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["nodes"], case["root_index"])

    for node_count in range(8):
        for shape in shapes(node_count):
            add(shape_to_rows(shape, lambda index: 0), 0 if node_count else -1)
            add(shape_to_rows(shape, lambda index: ((index * 37 + 5) % 17) - 8),
                0 if node_count else -1)

    rng = random.Random(20261014)
    for _ in range(512):
        add(random_tree(rng.randrange(1, 129), rng), 0)
    for _ in range(256):
        node_count = rng.randrange(0, 13)
        shape = rng.choice(shapes(node_count))
        add(nested_to_rows(mirrored_tree(shape, rng)), 0)

    lines = [f"{len(cases)}\n"]
    for nodes, root, expected in cases:
        flattened = [value for row in nodes for value in row]
        values_text = "" if not flattened else " " + " ".join(map(str, flattened))
        lines.append(f"{len(nodes)} {root} {expected}{values_text}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_symmetric")
    checker = manifest["binaries"]["tree_symmetric_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"tree symmetry C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_tree_symmetric.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        expected_values = [value for row in case["nodes"] for value in row]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != expected_values
                or record["workload"]["root_index"] != case["root_index"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record provenance/result mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/symmetric_tree")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/s/symmetric_tree/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "symmetric-tree-corpus.txt").write_text(data, encoding="utf-8")
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
