#!/usr/bin/env python3
"""Verify distribute-coins ports against an independent indexed-tree oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from functools import lru_cache
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_tree_scalar import distribute_coins_oracle

ALGORITHM = "distribute_coins"
MAX_NODE_COUNT = 100


@lru_cache(maxsize=None)
def shapes(node_count: int) -> tuple:
    if node_count == 0:
        return (None,)
    return tuple((left, right)
                 for left_count in range(node_count)
                 for left in shapes(left_count)
                 for right in shapes(node_count - 1 - left_count))


def shape_to_rows(shape, coin_values: list[int]) -> list[list[int]]:
    nodes: list[list[int]] = []

    def add(node_shape) -> int:
        if node_shape is None:
            return -1
        index = len(nodes)
        nodes.append([coin_values[index], -1, -1])
        nodes[index][1] = add(node_shape[0])
        nodes[index][2] = add(node_shape[1])
        return index

    add(shape)
    return nodes


def random_tree(node_count: int, rng: random.Random) -> list[list[int]]:
    nodes = [[0, -1, -1]]
    available = [(0, 1), (0, 2)]
    for _ in range(node_count - 1):
        slot = rng.randrange(len(available))
        parent, side = available.pop(slot)
        child = len(nodes)
        nodes[parent][side] = child
        nodes.append([0, -1, -1])
        available.extend(((child, 1), (child, 2)))
    return nodes


def corpus(workload: dict) -> tuple[str, int]:
    cases: list[tuple[list[list[int]], int, int]] = []
    seen: set[tuple] = set()

    def add(nodes: list[list[int]], root: int) -> None:
        expected = distribute_coins_oracle(nodes, root)
        key = (root, tuple(tuple(row) for row in nodes), expected)
        if key not in seen:
            seen.add(key)
            cases.append((nodes, root, expected))

    for case in workload["cases"]:
        expected = distribute_coins_oracle(case["nodes"], case["root_index"])
        if expected != case["expected_result"]:
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["nodes"], case["root_index"])

    add([], -1)
    for node_count in range(1, 8):
        for shape in shapes(node_count):
            add(shape_to_rows(shape, [1] * node_count), 0)
            add(shape_to_rows(shape, [node_count] + [0] * (node_count - 1)), 0)
            for coin_node in range(node_count):
                values = [0] * node_count
                values[coin_node] = node_count
                add(shape_to_rows(shape, values), 0)

    rng = random.Random(20261015)
    for _ in range(512):
        node_count = rng.randrange(1, MAX_NODE_COUNT + 1)
        nodes = random_tree(node_count, rng)
        for _coin in range(node_count):
            nodes[rng.randrange(node_count)][0] += 1
        add(nodes, 0)

    # Exercise invalid roots, coin totals, references, multiple parents and disconnected cycles.
    add([[1, -1, -1]], 1)
    add([[0, -1, -1]], 0)
    add([[101, -1, -1]], 0)
    add([[1, 1, -1]], 0)
    add([[2, 1, 1], [0, -1, -1]], 0)
    add([[1, -1, -1], [1, 2, -1], [0, 1, -1]], 0)
    add([[1, -1, -1], [0, 2, -1], [0, 1, -1]], 0)

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
                     with_checker=True, family="tree_scalar")
    checker = manifest["binaries"]["tree_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
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
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    rows = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(rows) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, row in zip(workload["cases"], rows):
        flattened = [value for node in case["nodes"] for value in node]
        expected = case["expected_result"]
        if (row["algorithm"] != ALGORITHM
                or row["implementation"]["language"] != language
                or row["implementation"]["source_sha256"] != manifest["source_sha256"]
                or row["workload"]["input_values"] != flattened
                or row["workload"]["root_index"] != case["root_index"]
                or row["workload"]["expected_result"] != expected
                or row["measurement"]["observed_result"] != expected
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/distribute_coins")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/d/distribute_coins/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "distribute-coins-corpus.txt").write_text(data, encoding="utf-8")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle trees", flush=True)

    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
