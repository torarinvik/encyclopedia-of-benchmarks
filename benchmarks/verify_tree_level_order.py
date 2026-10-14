#!/usr/bin/env python3
"""Verify indexed binary-tree level-order ports against an independent BFS oracle."""

from __future__ import annotations

import argparse
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_tree_level_order import encode_input, oracle

ALGORITHM = "level_order_traversal"
MAX_NODES = 4096


@lru_cache(maxsize=None)
def shapes(size: int):
    if size == 0:
        return (None,)
    return tuple((left, right) for left_size in range(size)
                 for left in shapes(left_size)
                 for right in shapes(size - left_size - 1))


def indexed_shape(shape, values: list[int]) -> list[list[int]]:
    nodes: list[list[int]] = []

    def visit(current) -> int:
        if current is None:
            return -1
        index = len(nodes)
        nodes.append([values[index], -1, -1])
        left = visit(current[0])
        right = visit(current[1])
        nodes[index][1] = left
        nodes[index][2] = right
        return index

    visit(shape)
    return nodes


def random_tree(rng: random.Random, size: int) -> list[list[int]]:
    if size == 0:
        return []
    nodes = [[rng.choice([-(2**63), -1, 0, 1, 2**63 - 1, rng.randrange(-1000, 1001)]), -1, -1]]
    open_slots = [(0, 1), (0, 2)]
    for _ in range(1, size):
        slot = rng.randrange(len(open_slots))
        parent, side = open_slots.pop(slot)
        child = len(nodes)
        nodes[parent][side] = child
        nodes.append([rng.choice([-(2**63), -1, 0, 1, 2**63 - 1, rng.randrange(-1000, 1001)]), -1, -1])
        open_slots.extend(((child, 1), (child, 2)))
    return nodes


def corpus(workload: dict) -> tuple[str, int]:
    cases: list[tuple[list[list[int]], int, int, list[int], list[int], int, int, int]] = []

    def add(nodes: list[list[int]], root: int, *, result: int | None = None,
            output_capacity: int | None = None, offset_capacity: int | None = None,
            queue_capacity: int | None = None) -> None:
        if result == -1:
            values, offsets = [], []
            observed_result = -1
        else:
            oracle_values, oracle_offsets = oracle(nodes, root)
            observed_result = len(oracle_offsets) - 1 if result is None else result
            values = oracle_values if observed_result >= 0 else []
            offsets = oracle_offsets if observed_result >= 0 else []
        expected_values = values
        expected_offsets = offsets
        cases.append((nodes, root, observed_result, expected_values, expected_offsets,
                      len(nodes) if output_capacity is None else output_capacity,
                      len(nodes) + 1 if offset_capacity is None else offset_capacity,
                      len(nodes) if queue_capacity is None else queue_capacity))

    for size in range(8):
        for shape in shapes(size):
            values = [((index * 13 + size) % 17) - 8 for index in range(size)]
            nodes = indexed_shape(shape, values)
            add(nodes, 0 if nodes else -1)
    rng = random.Random(20261014)
    for _ in range(256):
        size = rng.randrange(0, 257)
        nodes = random_tree(rng, size)
        add(nodes, 0 if size else -1)
    for size in (1024, 2047):
        nodes = [[index - size // 2, index + 1 if index + 1 < size else -1, -1]
                 for index in range(size)]
        add(nodes, 0)
    oversized = [[index, index + 1 if index + 1 < 4097 else -1, -1] for index in range(4097)]
    add(oversized, 0, result=-1)
    for case in workload["cases"]:
        flattened, _ = encode_input(case)
        nodes = [flattened[index:index + 3] for index in range(0, len(flattened), 3)]
        add(nodes, case["root_index"])

    nonempty = next(case for case in cases if case[0])
    nodes, root, _, _, offsets, out_cap, off_cap, q_cap = nonempty
    add(nodes, len(nodes), result=-1)
    add(nodes, -2, result=-1)
    add(nodes, root, result=-2, output_capacity=max(0, len(nodes) - 1))
    add(nodes, root, result=-2, offset_capacity=len(nodes))
    add(nodes, root, result=-2, queue_capacity=max(0, len(nodes) - 1))
    add([], 0, result=-1)
    add([], -1, result=-2, offset_capacity=0)

    lines = [str(len(cases)) + "\n"]
    for nodes, root, expected, values, offsets, output_capacity, offset_capacity, queue_capacity in cases:
        lines.append(f"{len(nodes)} {root} {expected} {len(values)} {len(offsets)} "
                     f"{output_capacity} {offset_capacity} {queue_capacity}\n")
        for row in nodes:
            lines.append(" ".join(map(str, row)) + "\n")
        if values:
            lines.append(" ".join(map(str, values)) + "\n")
        if offsets:
            lines.append(" ".join(map(str, offsets)) + "\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="tree_level_order")
    checker = manifest["binaries"]["tree_level_order_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"tree level-order C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete tree oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_tree_level_order.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of tree records")
    for case, record in zip(workload["cases"], records):
        flattened = [value for row in case["nodes"] for value in row]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(case["nodes"])
                or record["workload"]["input_values"] != flattened
                or record["workload"]["root_index"] != case["root_index"]
                or record["workload"]["expected_output_values"] != case["expected_output_values"]
                or record["workload"]["expected_level_offsets"] != case["expected_level_offsets"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded tree output/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/tree_level_order")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/l/level_order_traversal/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
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
