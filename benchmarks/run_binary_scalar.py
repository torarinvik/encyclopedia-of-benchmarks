#!/usr/bin/env python3
"""Record a built two-input scalar benchmark using its build manifest."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess

from build_abi import ROOT, sha256_file

U64_MAX = 2**64 - 1
I64_MIN = -(2**63)


def encode_values(case: dict, algorithm: str) -> tuple[int, int, int]:
    values = case.get("input_values")
    expected = case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= U64_MAX for value in values)
            or type(expected) is not int):
        raise ValueError("binary scalar cases require two 64-bit inputs and an integer result")
    if algorithm == "count_number_of_one_bits":
        number, method = values
        valid = 0 <= number <= 0xFFFFFFFF and 0 <= method <= 2
        expected_from_source = number.bit_count() if valid else -1
        if expected != expected_from_source:
            raise ValueError("count_number_of_one_bits expected_result does not match its selected source variant")
    elif algorithm == "bitwise_addition_recursive":
        first, second = values
        valid = 0 <= first <= 2**31 - 1 and 0 <= second <= 2**31 - 1
        expected_from_source = first + second if valid else -1
        if expected != expected_from_source:
            raise ValueError("bitwise_addition_recursive expected_result must equal the bounded nonnegative sum")
    elif algorithm == "recursive_digit_sum":
        number, repetitions = values
        valid = 0 <= number <= 2**63 - 1 and 0 <= repetitions <= 1_000_000
        if valid:
            total = sum(int(digit) for digit in str(number)) * repetitions
            while total >= 10:
                total = sum(int(digit) for digit in str(total))
            expected_from_source = total
        else:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("recursive_digit_sum expected_result does not match the pinned super-digit definition")
    elif algorithm == "xor_swap_two_integers":
        first, second = values
        valid = -32768 <= first <= 32767 and -32768 <= second <= 32767
        expected_from_source = (second + 32768) * 65536 + (first + 32768) if valid else -1
        if expected != expected_from_source:
            raise ValueError("xor_swap_two_integers expected_result must encode the swapped pair")
    return values[0], values[1], expected


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
    if manifest.get("family") != "binary_scalar":
        parser.error("build manifest must declare the binary_scalar ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["binary_scalar_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/binary_scalar_runner.c"
    if (sha256_file(source) != manifest["source_sha256"] or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "binary_scalar_call"):
        parser.error("workload does not match the built binary scalar algorithm")
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
        left, right, expected = encode_values(case, algorithm)
        abi_left = left if left >= 0 else left + (1 << 64)
        abi_right = right if right >= 0 else right + (1 << 64)
        command = [str(executable), str(abi_left), str(abi_right), str(expected),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"binary scalar runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        if raw["observed_result"] != expected or len(raw["samples_ns"]) != samples:
            raise ValueError(f"binary scalar runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [left, right],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "binary_scalar_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups,
                                        "repetitions_per_sample": repetitions,
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
