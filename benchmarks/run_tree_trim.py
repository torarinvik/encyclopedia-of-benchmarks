#!/usr/bin/env python3
"""Record a caller-buffered BST trim benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess
import sys

from build_abi import ROOT, sha256_file

MAX_NODE_COUNT = 100
MAX_OUTPUT_VALUES = 1 + 3 * MAX_NODE_COUNT
MAX_VALUE = 10000
MASK64 = (1 << 64) - 1
OUTPUT_CANARY = 0x5A5A5A5A5A5A5A5A


def oracle(nodes: list[list[int]], root_index: int, low: int, high: int,
           output_capacity: int) -> tuple[int, list[int]]:
    if (not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT
            or type(root_index) is not int or type(low) is not int or type(high) is not int
            or type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_VALUES
            or low < 1 or high > MAX_VALUE or low > high):
        return -1, []
    node_count = len(nodes)
    if node_count == 0:
        if root_index != -1:
            return -1, []
        if output_capacity < 1:
            return -2, []
        return 1, [-1]
    if not 0 <= root_index < node_count:
        return -1, []

    parents = [0] * node_count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or any(type(value) is not int for value in row)):
            return -1, []
        value, left, right = row
        if not 1 <= value <= MAX_VALUE:
            return -1, []
        for child in (left, right):
            if child < -1 or child >= node_count:
                return -1, []
            if child >= 0:
                parents[child] += 1
                if parents[child] > 1:
                    return -1, []
    if (parents[root_index] != 0
            or any(parents[index] != 1 for index in range(node_count) if index != root_index)):
        return -1, []

    seen: set[int] = set()
    stack = [(root_index, 0, MAX_VALUE + 1)]
    while stack:
        node, lower, upper = stack.pop()
        if node in seen:
            return -1, []
        seen.add(node)
        value, left, right = nodes[node]
        if not lower < value < upper:
            return -1, []
        if right >= 0:
            stack.append((right, value, upper))
        if left >= 0:
            stack.append((left, lower, value))
    if len(seen) != node_count:
        return -1, []
    if output_capacity < 1 + 3 * node_count:
        return -2, []

    serialized_nodes: list[list[int]] = []

    def trim(node: int) -> int:
        if node == -1:
            return -1
        value, left, right = nodes[node]
        if value < low:
            return trim(right)
        if value > high:
            return trim(left)
        new_index = len(serialized_nodes)
        serialized_nodes.append([value, -1, -1])
        serialized_nodes[new_index][1] = trim(left)
        serialized_nodes[new_index][2] = trim(right)
        return new_index

    new_root = trim(root_index)
    flattened = [value for row in serialized_nodes for value in row]
    output = [new_root, *flattened]
    return len(output), output


def encode_case(case: dict) -> tuple[list[int], list[int], str]:
    nodes, root_index = case.get("nodes"), case.get("root_index")
    low, high = case.get("low"), case.get("high")
    capacity = case.get("output_capacity", 1 + 3 * len(nodes) if isinstance(nodes, list) else 0)
    if not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT:
        raise ValueError(f"invalid node table: {case.get('id')}")
    expected_result, expected_output = oracle(nodes, root_index, low, high, capacity)
    if (case.get("expected_result") != expected_result
            or case.get("expected_output_values") != expected_output):
        raise ValueError(f"workload oracle mismatch: {case.get('id')}")
    flattened = [value for row in nodes for value in row]
    header = [len(nodes), root_index, low, high, expected_result, len(expected_output), capacity]
    payload = [*header, *flattened, *expected_output]
    return flattened, expected_output, " ".join(map(str, payload)) + "\n"


def checksum(values: list[int]) -> int:
    result = 14695981039346656037
    for value in values:
        result = ((result ^ (value & MASK64)) * 1099511628211) & MASK64
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", required=True, type=Path)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()
    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("family") != "tree_trim":
        parser.error("build manifest must declare the tree_trim ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["tree_trim_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/tree_trim_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "tree_trim_call"):
        parser.error("workload does not match the tree_trim ABI")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed runner limits")
    if len({case["id"] for case in workload["cases"]}) != len(workload["cases"]):
        parser.error("workload case IDs must be unique")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": binary["harness_sha256"],
                           "binary_sha256": binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case in workload["cases"]:
        flattened, expected_output, payload = encode_case(case)
        completed = subprocess.run([str(executable), str(samples), str(warmups), str(repetitions)],
                                   input=payload, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"tree-trim runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = (checksum(expected_output) * repetitions * samples) & MASK64
        if case["expected_result"] < 0:
            expected_checksum = 0
        if (raw["observed_result"] != case["expected_result"]
                or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"tree-trim runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(case["nodes"]), "input_values": flattened,
                                     "root_index": case["root_index"], "low": case["low"],
                                     "high": case["high"], "output_capacity": case.get("output_capacity"),
                                     "expected_output_values": expected_output, "case": case["id"],
                                     "target": None, "expected_result": case["expected_result"]},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "tree_trim_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"],
                                        "observed_result": raw["observed_result"],
                                        "result_checksum": raw["result_checksum"]}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
