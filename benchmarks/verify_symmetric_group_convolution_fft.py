#!/usr/bin/env python3
"""Draft verifier for an existing symmetric-group byte-output build.

Uses only an already-built manifest and checker; it never starts a build. Do not
run while compiler profiling requires a quiet machine.
"""
import argparse
import json
from math import factorial
from pathlib import Path
import subprocess
import sys
import tempfile

from build_abi import ROOT, sha256_file
from s.symmetric_group_convolution_fft.abi_reference import (
    bounded_sparse, coordinate_structured, expected, parity_structured,
)
from s.symmetric_group_convolution_fft.structured_cases import cases as structured_cases
from s.symmetric_group_convolution_fft.target_oracle import convolve as target_convolve

ALGORITHM = "symmetric_group_convolution_fft"
WORKLOAD = ROOT / "benchmarks/s/symmetric_group_convolution_fft/workload.json"


def write_case(stream, values, length, result, output, capacity, input_null, output_null):
    stream.write(f"{length} {result} {len(output)} {capacity} {int(input_null)} {int(output_null)} ")
    # A null pointer with nonzero length still needs placeholder words in the
    # checker's stream, although the ABI receives a null pointer.
    words = values if not input_null else [0] * length
    for start in range(0, len(words), 4096):
        stream.write(" ".join(map(str, words[start:start + 4096])))
        stream.write(" ")
    if output:
        for start in range(0, len(output), 65536):
            stream.write(output[start:start + 65536].hex())
        stream.write("\n")
    else:
        stream.write("-\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", type=Path, required=True)
    parser.add_argument("--full-range", action="store_true",
                        help="Include structured cases through degree nine")
    parser.add_argument("--timeout", type=float, default=3600)
    args = parser.parse_args()
    if not 0 < args.timeout < float("inf"):
        parser.error("timeout must be positive and finite")
    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("algorithm") != ALGORITHM or manifest.get("family") != "i64_array_bytes_output":
        raise ValueError("manifest describes a different algorithm or ABI")
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]
    checker_path = Path(checker["path"])
    harness = ROOT / "benchmarks/harness/i64_array_bytes_output_check.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(checker_path) != checker["sha256"]
            or sha256_file(harness) != checker["harness_sha256"]):
        raise ValueError("checker, source, or checker harness changed since build")
    language = manifest["language"]
    dependencies = manifest.get("source_dependencies", [])
    if language in {"c", "cpp", "rust", "nim", "zig", "elisa"}:
        suffix = {"c": "h", "cpp": "hpp", "rust": "rs", "nim": "nim", "zig": "zig", "elisa": "elisa"}[language]
        parts = ("plan", "forward", "inverse", "kernel") if language == "elisa" else ("plan", "forward", "inverse")
        required = {f"{language}/s/{ALGORITHM}_{part}.{suffix}"
                    for part in parts}
        if (not isinstance(dependencies, list) or len(dependencies) != len(required)
                or any(not isinstance(item, dict) or not isinstance(item.get("path"), str)
                       or not isinstance(item.get("sha256"), str) for item in dependencies)
                or {item["path"] for item in dependencies} != required):
            raise ValueError("manifest does not record all required source dependencies")
    for dependency in dependencies:
        path = (ROOT / dependency["path"]).resolve()
        path.relative_to(ROOT)
        if sha256_file(path) != dependency["sha256"]:
            raise ValueError("source dependency changed since build")
    workload = json.loads(WORKLOAD.read_text(encoding="utf-8"))
    # A temporary file prevents the degree-nine corpus from being sent as a
    # command argument or held as one additional large string.
    with tempfile.TemporaryFile(mode="w+t", encoding="ascii") as corpus:
        corpus.write("0000000000 bytes_with_capacity\n")
        count = 0
        for case in workload["cases"]:
            values = case["input_values"]
            length = case["input_length"]
            capacity = case.get("output_capacity", workload["workspace"]["bytes"])
            input_null = case.get("input_is_null", False)
            output_null = case.get("output_is_null", False)
            result, output = expected(values, capacity, input_is_null=input_null,
                                      output_is_null=output_null, input_length=length)
            if result != case["expected_result"] or output.hex() != case["expected_output_hex"]:
                raise ValueError(f"fixture disagrees with oracle: {case['id']}")
            write_case(corpus, values, length, result, output, capacity, input_null, output_null)
            count += 1
        for name, values, result, output in structured_cases():
            if not args.full_range and values[0] > 5:
                break
            reference_result, reference_output = expected(values, len(output), input_length=len(values))
            if (result, output) != (reference_result, reference_output):
                raise ValueError(f"structured fixture disagrees with oracle: {name}")
            if result >= 0 and values[0] <= 5:
                size = factorial(values[0])
                coefficients = target_convolve(values[0], values[1:1 + size], values[1 + size:])
                target_output = b"".join(value.to_bytes(4, "little") for value in coefficients)
                if output != target_output:
                    raise ValueError(f"structured fixture disagrees with target oracle: {name}")
                # Exercise the large-degree shortcuts directly at small degrees,
                # where both independent quadratic references are available.
                shortcut = None
                a, b = values[1:1 + size], values[1 + size:]
                if name.startswith("coordinate_"):
                    shortcut = coordinate_structured(values[0], a, b)
                elif name.startswith(("sign_character_", "even_subgroup_")):
                    shortcut = parity_structured(values[0], a, b)
                elif name.startswith(("two_support_", "three_support_")):
                    shortcut = bounded_sparse(values[0], a, b)
                if name.startswith(("coordinate_", "sign_character_", "even_subgroup_", "two_support_", "three_support_")):
                    if shortcut != coefficients:
                        raise ValueError(f"structured shortcut disagrees with target oracle: {name}")
            write_case(corpus, values, len(values), result, output, len(output), False, False)
            count += 1
        corpus.seek(0)
        corpus.write(f"{count:010d}")
        corpus.flush()
        corpus.seek(0)
        checked = subprocess.run([str(checker_path)], stdin=corpus, capture_output=True,
                                 text=True, timeout=args.timeout, check=False)
    if checked.returncode or json.loads(checked.stdout).get("cases_checked") != count:
        raise RuntimeError(f"checker failed: {checked.stderr}")
    with tempfile.TemporaryDirectory() as directory:
        records_path = Path(directory) / "records.jsonl"
        recorder = subprocess.run([
            sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
            "--build-manifest", str(args.build_manifest.resolve()), "--samples", "1",
            "--warmups", "0", "--repetitions", "1", "--output", str(records_path),
        ], cwd=ROOT, capture_output=True, text=True, timeout=args.timeout, check=False)
        if recorder.returncode:
            raise RuntimeError(f"recorder failed: {recorder.stderr}")
        records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise ValueError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        implementation = record["implementation"]
        if (record["algorithm"] != ALGORITHM
                or implementation["language"] != manifest["language"]
                or implementation["source_sha256"] != manifest["source_sha256"]
                or implementation.get("source_dependencies") != manifest.get("source_dependencies")
                or record["workload"]["case"] != case["id"]
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["input_length"] != case["input_length"]
                or record["workload"].get("input_is_null", False) != case.get("input_is_null", False)
                or record["workload"].get("output_is_null", False) != case.get("output_is_null", False)
                or record["workload"]["output_capacity"] != case.get(
                    "output_capacity", workload["workspace"]["bytes"])
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise ValueError(f"recorder provenance or result mismatch: {case['id']}")
    print(json.dumps({"algorithm": ALGORITHM, "language": manifest["language"],
                      "checker_cases": count, "workload_records": len(records),
                      "full_range": args.full_range}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"verification failed: {error}", file=sys.stderr)
        raise SystemExit(1)
