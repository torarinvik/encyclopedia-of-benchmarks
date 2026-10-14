#!/usr/bin/env python3
"""Record a caller-buffered indexed binary-tree level-order benchmark."""

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

MAX_NODES = 4096
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(nodes: list[list[int]], root: int) -> tuple[list[int], list[int]]:
    count = len(nodes)
    if count == 0:
        if root != -1:
            raise ValueError("empty tree root must be -1")
        return [], [0]
    if not 0 <= root < count:
        raise ValueError("root index is outside the node table")
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in row)):
            raise ValueError("each node must be [signed 64-bit value, left index, right index]")
        for child in row[1:]:
            if child == -1:
                continue
            if not 0 <= child < count:
                raise ValueError("child index is outside the node table")
            parents[child] += 1
    if parents[root] != 0 or any(parents[index] != 1 for index in range(count) if index != root):
        raise ValueError("input is not a rooted binary tree")
    queue = [root]
    head = 0
    values, offsets = [], [0]
    while head < len(queue):
        level_end = len(queue)
        while head < level_end:
            _, left, right = nodes[queue[head]]
            values.append(nodes[queue[head]][0])
            head += 1
            if left != -1:
                queue.append(left)
            if right != -1:
                queue.append(right)
        offsets.append(len(values))
    if len(values) != count:
        raise ValueError("tree contains unreachable nodes or a cycle")
    return values, offsets


def encode_input(case: dict) -> tuple[list[int], str]:
    nodes, root = case.get("nodes"), case.get("root_index")
    if not isinstance(nodes, list) or len(nodes) > MAX_NODES or type(root) is not int:
        raise ValueError(f"invalid tree case: {case.get('id')}")
    values, offsets = oracle(nodes, root)
    if (case.get("expected_result") != len(offsets) - 1
            or case.get("expected_output_values") != values
            or case.get("expected_level_offsets") != offsets):
        raise ValueError(f"workload oracle mismatch: {case['id']}")
    flattened = [value for row in nodes for value in row]
    payload = [str(len(nodes)), str(root)]
    payload.extend(map(str, flattened))
    payload.extend(map(str, values))
    payload.append(str(len(offsets)))
    payload.extend(map(str, offsets))
    return flattened, " ".join(payload) + "\n"


def checksum(values: list[int], offsets: list[int]) -> int:
    value = 14695981039346656037
    for item in [*values, *offsets]:
        value = ((value ^ (item & ((1 << 64) - 1))) * 1099511628211) & ((1 << 64) - 1)
    return value


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
    if manifest.get("family") != "tree_level_order":
        parser.error("build manifest must declare the tree_level_order ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["tree_level_order_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/tree_level_order_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "tree_level_order_call"):
        parser.error("workload does not match the indexed-tree traversal benchmark")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed the runner limits")
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
        flattened, payload = encode_input(case)
        expected_levels = case["expected_result"]
        completed = subprocess.run([str(executable), str(expected_levels), str(samples),
                                    str(warmups), str(repetitions)], input=payload,
                                   capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"tree traversal runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = checksum(case["expected_output_values"],
                                     case["expected_level_offsets"])
        expected_checksum = (expected_checksum * repetitions * samples) & ((1 << 64) - 1)
        if (raw["observed_result"] != expected_levels or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"tree runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(case["nodes"]), "input_values": flattened,
                                     "root_index": case["root_index"],
                                     "expected_output_values": case["expected_output_values"],
                                     "expected_level_offsets": case["expected_level_offsets"],
                                     "case": case["id"], "target": None,
                                     "expected_result": expected_levels},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "tree_level_order_call",
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
