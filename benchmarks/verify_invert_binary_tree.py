#!/usr/bin/env python3
"""Check recursive binary-tree inversion and its portable byte serialization."""

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
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "invert_binary_tree"
MAX_NODE_COUNT = 1023
MAX_TREE_HEIGHT = 512


def oracle(values: tuple[int, ...]) -> tuple[int, bytes]:
    if (not 1 <= len(values) <= 1 + 3 * MAX_NODE_COUNT
            or any(type(value) is not int for value in values)
            or (len(values) - 1) % 3 != 0):
        return -1, b""
    node_count = (len(values) - 1) // 3
    root = values[0]
    if node_count == 0:
        return (0, b"") if root == -1 else (-1, b"")
    if not 0 <= root < node_count:
        return -1, b""
    nodes = [list(values[offset:offset + 3]) for offset in range(1, len(values), 3)]
    visited: set[int] = set()

    def validate(index: int, depth: int) -> bool:
        if index == -1:
            return True
        if not 0 <= index < node_count or depth > MAX_TREE_HEIGHT or index in visited:
            return False
        visited.add(index)
        value, left, right = nodes[index]
        if (not -(2**31) <= value < 2**31 or left < -1 or right < -1
                or left >= node_count or right >= node_count):
            return False
        return validate(left, depth + 1) and validate(right, depth + 1)

    if not validate(root, 1) or len(visited) != node_count:
        return -1, b""

    transformed = [node[:] for node in nodes]
    stack = [root]
    while stack:
        index = stack.pop()
        left, right = transformed[index][1], transformed[index][2]
        transformed[index][1], transformed[index][2] = right, left
        if right != -1:
            stack.append(right)
        if left != -1:
            stack.append(left)
    flat = [value for node in transformed for value in node]
    return node_count, struct.pack("<" + "q" * len(flat), *flat)


@lru_cache(maxsize=None)
def tree_shapes(node_count: int) -> tuple[object, ...]:
    if node_count == 0:
        return (None,)
    result = []
    for left_count in range(node_count):
        right_count = node_count - left_count - 1
        for left, right in product(tree_shapes(left_count), tree_shapes(right_count)):
            result.append((left, right))
    return tuple(result)


def pack_shape(shape: object) -> tuple[int, ...]:
    if shape is None:
        return (-1,)
    nodes: list[list[int]] = []

    def insert(item: object) -> int:
        index = len(nodes)
        nodes.append([index - 50, -1, -1])
        left, right = item
        nodes[index][1] = insert(left) if left is not None else -1
        nodes[index][2] = insert(right) if right is not None else -1
        return index

    root = insert(shape)
    packed = [root]
    for node in nodes:
        packed.extend(node)
    return tuple(packed)


def random_tree(rng: random.Random, node_count: int, *, chain: bool = False) -> tuple[int, ...]:
    nodes = [[rng.choice((-2**31, -100, -1, 0, 1, 100, 2**31 - 1)), -1, -1]
             for _ in range(node_count)]
    if node_count == 0:
        return (-1,)
    available = [(0, 1), (0, 2)]
    for node in range(1, node_count):
        if chain:
            parent, side = node - 1, 1
            available.remove((parent, side))
        else:
            position = rng.randrange(len(available))
            parent, side = available.pop(position)
        nodes[parent][side] = node
        available.extend(((node, 1), (node, 2)))
    order = list(range(node_count))
    rng.shuffle(order)
    new_index = {old: new for new, old in enumerate(order)}
    reordered = []
    for old in order:
        value, left, right = nodes[old]
        reordered.append([value, -1 if left == -1 else new_index[left],
                          -1 if right == -1 else new_index[right]])
    packed = [new_index[0]]
    for node in reordered:
        packed.extend(node)
    return tuple(packed)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = oracle(values)

    for node_count in range(8):
        for shape in tree_shapes(node_count):
            add(pack_shape(shape))

    rng = random.Random(20261015)
    for node_count in (1, 2, 3, 7, 31, 127, 255, 1023):
        for _ in range(12 if node_count < 128 else 3):
            add(random_tree(rng, node_count))
    add(random_tree(rng, MAX_TREE_HEIGHT, chain=True))
    add(random_tree(rng, MAX_TREE_HEIGHT + 1, chain=True))

    invalid = [
        (), (0,), (0, 1), (0, 1, -1, -1, 2),
        (-1, 1, -1, -1), (0, 1, 1, -1),
        (0, 1, 0, -1, -1, -1, -1),
        (0, 1, 1, 2, 2, -1, -1, 3, -1, -1),
        (0, 2**31, -1, -1), (0, 1, -2, -1),
        (0, 1, 1, -1, 2, -1, -1),
    ]
    for values in invalid:
        add(values)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = oracle(values)
        if (case["expected_result"] != expected[0]
                or case["expected_output_hex"] != expected[1].hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[values] = expected

    records = sorted(cases.items())
    capacity_input = (0, 42, -1, -1)
    records.append((capacity_input, (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {count} {len(output)}{values_text} "
                     f"{output.hex() if output else '-'}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/invert_binary_tree")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/i/invert_binary_tree/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle cases, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
