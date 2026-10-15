#!/usr/bin/env python3
"""Record a scalar-result benchmark over an indexed binary tree."""

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

MAX_NODE_COUNT = 1023
VALUE_MIN, VALUE_MAX = -100_000, 100_000
MASK64 = 2**64 - 1


def max_ancestor_diff_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 1 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3 or type(row[0]) is not int
                or not VALUE_MIN <= row[0] <= VALUE_MAX):
            return -1
        for child in row[1:]:
            if type(child) is not int or child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1
    stack = [(root_index, nodes[root_index][0], nodes[root_index][0])]
    seen: set[int] = set()
    best = 0
    while stack:
        node, low, high = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        value, left, right = nodes[node]
        best = max(best, abs(value - low), abs(value - high))
        low, high = min(low, value), max(high, value)
        if left >= 0:
            stack.append((left, low, high))
        if right >= 0:
            stack.append((right, low, high))
    return best if len(seen) == count else -1


def max_depth_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 0 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row):
            return -1
        for child in row[1:]:
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1
    stack = [(root_index, 1)]
    seen: set[int] = set()
    maximum_depth = 0
    while stack:
        node, node_depth = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        maximum_depth = max(maximum_depth, node_depth)
        for child in nodes[node][1:]:
            if child >= 0:
                stack.append((child, node_depth + 1))
    return maximum_depth if len(seen) == count else -1


def balanced_binary_tree_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 1 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row):
            return -1
        for child in row[1:]:
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1

    stack = [(root_index, False)]
    seen: set[int] = set()
    heights: dict[int, int] = {}
    balanced: dict[int, bool] = {}
    while stack:
        node, expanded = stack.pop()
        if not expanded:
            if node in seen:
                return -1
            seen.add(node)
            stack.append((node, True))
            for child in reversed(nodes[node][1:]):
                if child >= 0:
                    stack.append((child, False))
            continue
        left, right = nodes[node][1:]
        left_height = heights.get(left, 0)
        right_height = heights.get(right, 0)
        heights[node] = 1 + max(left_height, right_height)
        balanced[node] = (abs(left_height - right_height) <= 1
                          and (left < 0 or balanced[left])
                          and (right < 0 or balanced[right]))
    return int(balanced[root_index]) if len(seen) == count else -1


def sum_of_left_leaves_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 0 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row)
                or not -1000 <= row[0] <= 1000):
            return -1
        for child in row[1:]:
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1
    stack = [(root_index, False)]
    seen: set[int] = set()
    total = 0
    while stack:
        node, is_left = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        value, left, right = nodes[node]
        if left == -1 and right == -1 and is_left:
            total += value
        if right >= 0:
            stack.append((right, False))
        if left >= 0:
            stack.append((left, True))
    return total if len(seen) == count else -1


def univalued_binary_tree_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 1 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row):
            return -1
        for child in row[1:]:
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1
    root_value = nodes[root_index][0]
    stack = [root_index]
    seen: set[int] = set()
    univalued = True
    while stack:
        node = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        value, left, right = nodes[node]
        if value != root_value:
            univalued = False
        if right >= 0:
            stack.append(right)
        if left >= 0:
            stack.append(left)
    if len(seen) != count:
        return -1
    return int(univalued)


def binary_tree_maximum_path_sum_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 1 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row)
                or not -1000 <= row[0] <= 1000):
            return -1
        for child in row[1:]:
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                       if index != root_index):
        return -1
    stack = [(root_index, False)]
    seen: set[int] = set()
    gains: dict[int, int] = {}
    best_path: int | None = None
    while stack:
        node, expanded = stack.pop()
        if not expanded:
            if node in seen:
                return -1
            seen.add(node)
            stack.append((node, True))
            for child in reversed(nodes[node][1:]):
                if child >= 0:
                    stack.append((child, False))
            continue
        value, left, right = nodes[node]
        left_gain = max(gains.get(left, 0), 0)
        right_gain = max(gains.get(right, 0), 0)
        through_node = value + left_gain + right_gain
        best_path = through_node if best_path is None else max(best_path, through_node)
        gains[node] = value + max(left_gain, right_gain)
    return best_path if len(seen) == count and best_path is not None else -1


def bst_iterator_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 0 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row)
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
    if len(seen) != count or any(ordered[index - 1] >= ordered[index]
                                 for index in range(1, count)):
        return -1
    return sum((index + 1) * (value + 100_001) for index, value in enumerate(ordered))


def validate_bst_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if not 0 <= count <= MAX_NODE_COUNT or type(root_index) is not int:
        return -1
    if count == 0:
        return 1 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3 or any(type(value) is not int for value in row)
                or not -(2**31) <= row[0] < 2**31):
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


def distribute_coins_oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if count > 100 or type(root_index) is not int:
        return -1
    if count == 0:
        return 0 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1

    parents = [-1] * count
    coin_total = 0
    for node, row in enumerate(nodes):
        if (not isinstance(row, list) or len(row) != 3
                or any(type(value) is not int for value in row)):
            return -1
        coins, left, right = row
        if not 0 <= coins <= 100:
            return -1
        coin_total += coins
        for child in (left, right):
            if child < -1 or child >= count:
                return -1
            if child >= 0:
                if parents[child] != -1:
                    return -1
                parents[child] = node
    if coin_total != count or parents[root_index] != -1:
        return -1
    if any(node != root_index and parents[node] == -1 for node in range(count)):
        return -1

    order = []
    stack = [root_index]
    seen: set[int] = set()
    while stack:
        node = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        order.append(node)
        _coins, left, right = nodes[node]
        if left >= 0:
            stack.append(left)
        if right >= 0:
            stack.append(right)
    if len(order) != count:
        return -1

    excesses = [0] * count
    moves = 0
    for node in reversed(order):
        coins, left, right = nodes[node]
        left_excess = 1 if left == -1 else excesses[left]
        right_excess = 1 if right == -1 else excesses[right]
        moves += abs(1 - left_excess) + abs(1 - right_excess)
        excesses[node] = coins + left_excess + right_excess - 2
    return moves if excesses[root_index] == 1 else -1


def oracle(nodes: list[list[int]], root_index: int, algorithm: str) -> int:
    if algorithm == "max_ancestor_diff":
        return max_ancestor_diff_oracle(nodes, root_index)
    if algorithm == "max_depth":
        return max_depth_oracle(nodes, root_index)
    if algorithm == "balanced_binary_tree":
        return balanced_binary_tree_oracle(nodes, root_index)
    if algorithm == "sum_of_left_leaves":
        return sum_of_left_leaves_oracle(nodes, root_index)
    if algorithm == "univalued_binary_tree":
        return univalued_binary_tree_oracle(nodes, root_index)
    if algorithm == "binary_tree_maximum_path_sum":
        return binary_tree_maximum_path_sum_oracle(nodes, root_index)
    if algorithm == "bst_iterator":
        return bst_iterator_oracle(nodes, root_index)
    if algorithm == "validate_bst":
        return validate_bst_oracle(nodes, root_index)
    if algorithm == "distribute_coins":
        return distribute_coins_oracle(nodes, root_index)
    raise ValueError(f"no tree scalar oracle for {algorithm}")


def encode_case(case: dict, algorithm: str) -> tuple[list[int], str]:
    nodes, root_index = case.get("nodes"), case.get("root_index")
    if not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT:
        raise ValueError(f"invalid tree node table: {case.get('id')}")
    expected = oracle(nodes, root_index, algorithm)
    if case.get("expected_result") != expected:
        raise ValueError(f"workload oracle mismatch: {case['id']}")
    flattened = [value for row in nodes for value in row]
    payload = [str(len(nodes)), str(root_index), *map(str, flattened)]
    return flattened, " ".join(payload) + "\n"


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
    if manifest.get("family") != "tree_scalar":
        parser.error("build manifest must declare the tree_scalar ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["tree_scalar_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/tree_scalar_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    timing = workload.get("measurement", {})
    if workload.get("algorithm") != algorithm or timing.get("comparison_model") != "tree_scalar_call":
        parser.error("workload does not match the indexed-tree scalar benchmark")
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
        flattened, payload = encode_case(case, algorithm)
        expected = case["expected_result"]
        completed = subprocess.run([str(executable), str(expected), str(samples),
                                    str(warmups), str(repetitions)], input=payload,
                                   capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"tree scalar runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = ((expected & MASK64) * repetitions * samples) & MASK64
        if (raw["observed_result"] != expected or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"tree runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(case["nodes"]), "input_values": flattened,
                                     "root_index": case["root_index"], "case": case["id"],
                                     "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "tree_scalar_call",
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
