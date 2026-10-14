#!/usr/bin/env python3
"""Record a built shortest-path implementation after checking the complete output."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess
import sys

from build_abi import ROOT, sha256_file

I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def encode_case(case: dict) -> str:
    vertices, source, edges = case["vertices"], case["source"], case["edges"]
    status, expected = case["expected_status"], case["expected_distances"]
    if (type(vertices) is not int or not 0 <= vertices <= 100000 or
            type(source) is not int or not 0 <= source < 2 ** (8 * struct.calcsize("P")) or
            len(edges) > 1000000 or type(status) is not int or not I64_MIN <= status <= 0):
        raise ValueError("graph size, source, or status is outside the harness range")
    lines = [f"{vertices} {len(edges)} {source} {status}\n"]
    for edge in edges:
        if len(edge) != 3 or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in edge):
            raise ValueError("each edge must be a signed 64-bit origin/destination/weight triple")
        lines.append(" ".join(str(value) for value in edge) + "\n")
    if status == 0:
        if not isinstance(expected, list) or len(expected) != vertices:
            raise ValueError("successful cases require one expected distance per vertex")
        for value in expected:
            if value is None:
                lines.append("0 0\n")
            elif type(value) is int and I64_MIN <= value <= I64_MAX:
                lines.append(f"1 {value}\n")
            else:
                raise ValueError("expected distances must be signed 64-bit integers or null")
    elif expected is not None:
        raise ValueError("failed cases must not specify distances")
    return "".join(lines)


def observed_distances(raw: dict, case: dict) -> list[int | None] | None:
    if raw["observed_result"] != case["expected_status"]:
        raise ValueError("wrong shortest-path status")
    if raw["observed_result"] != 0:
        if raw["distances"] is not None or raw["reachable"] is not None:
            raise ValueError("failed calls must not publish distance vectors")
        return None
    distances, reachable = raw["distances"], raw["reachable"]
    if len(distances) != case["vertices"] or len(reachable) != case["vertices"]:
        raise ValueError("wrong output vector length")
    if any(flag not in (0, 1) for flag in reachable):
        raise ValueError("invalid reachability flag")
    if any(flag == 0 and distance != 0 for flag, distance in zip(reachable, distances)):
        raise ValueError("unreachable vertices must have canonical zero distance storage")
    result = [distance if flag else None for flag, distance in zip(reachable, distances)]
    if result != case["expected_distances"]:
        raise ValueError("shortest-path vector differs from the expected output")
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
    if manifest.get("family") != "shortest_path":
        parser.error("build manifest must declare the shortest_path ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["shortest_path_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/shortest_path_runner.c"
    if (sha256_file(source) != manifest["source_sha256"] or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload["algorithm"] != algorithm or
            workload["measurement"]["comparison_model"] != "shortest_path_call"):
        parser.error("workload does not match the built graph algorithm and ABI")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000:
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
        completed = subprocess.run([str(executable), str(samples), str(warmups), str(repetitions)],
                                   input=encode_case(case), capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"graph runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        distances = observed_distances(raw, case)
        if len(raw["samples_ns"]) != samples:
            raise ValueError("runner returned the wrong number of samples")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": case["vertices"], "edge_count": len(case["edges"]),
                                     "source_vertex": case["source"], "case": case["id"], "target": None,
                                     "expected_result": case["expected_status"],
                                     "expected_distances": case["expected_distances"]},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "shortest_path_call",
                                        "target_comparisons_per_sample": None, "warmup_rounds": warmups,
                                        "repetitions_per_sample": repetitions, "samples_ns": raw["samples_ns"],
                                        "observed_result": raw["observed_result"], "observed_distances": distances,
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
