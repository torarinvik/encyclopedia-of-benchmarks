#!/usr/bin/env python3
"""Record recursive binary-tree symmetry benchmark samples."""

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
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
MASK64 = 2**64 - 1


def oracle(nodes: list[list[int]], root_index: int) -> int:
    count = len(nodes)
    if count > MAX_NODE_COUNT or type(root_index) is not int:
        raise ValueError("invalid tree size or root")
    if count == 0:
        return 1 if root_index == -1 else -1
    if not 0 <= root_index < count:
        return -1
    parents = [0] * count
    for row in nodes:
        if (not isinstance(row, list) or len(row) != 3
                or type(row[0]) is not int or not I32_MIN <= row[0] <= I32_MAX):
            raise ValueError("each node must contain a signed 32-bit value and two child indexes")
        for child in row[1:]:
            if type(child) is not int or child < -1 or child >= count:
                return -1
            if child != -1:
                parents[child] += 1
    if parents[root_index] != 0 or any(parents[index] != 1 for index in range(count)
                                        if index != root_index):
        raise ValueError("nonempty input is not a rooted binary tree")
    queue = [root_index]
    seen = set()
    while queue:
        node = queue.pop()
        if node in seen:
            raise ValueError("tree contains a cycle")
        seen.add(node)
        queue.extend(child for child in nodes[node][1:] if child != -1)
    if len(seen) != count:
        raise ValueError("tree contains unreachable nodes")

    # This iterative pair walk is separate from the recursive implementations.
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


def encode_case(case: dict) -> tuple[list[int], str]:
    nodes, root_index = case.get("nodes"), case.get("root_index")
    if not isinstance(nodes, list) or len(nodes) > MAX_NODE_COUNT:
        raise ValueError(f"invalid tree node table: {case.get('id')}")
    expected = oracle(nodes, root_index)
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
    if manifest.get("family") != "tree_symmetric":
        parser.error("build manifest must declare the tree_symmetric ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["tree_symmetric_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/tree_symmetric_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "tree_symmetric_call"):
        parser.error("workload does not match the tree symmetry benchmark")
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
        flattened, payload = encode_case(case)
        expected = case["expected_result"]
        completed = subprocess.run([str(executable), str(expected), str(samples),
                                    str(warmups), str(repetitions)], input=payload,
                                   capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"tree symmetry runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = ((expected & MASK64) * repetitions * samples) & MASK64
        if (raw["observed_result"] != expected or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"tree symmetry runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(case["nodes"]), "input_values": flattened,
                                     "root_index": case["root_index"], "case": case["id"],
                                     "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "tree_symmetric_call",
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
