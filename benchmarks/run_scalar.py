#!/usr/bin/env python3
"""Run the portable scalar benchmark runner and append JSONL records."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import os
import platform
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
I64_MIN = -(2**63)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_expected_result(algorithm: str, input_value: int, expected_result: int) -> None:
    if algorithm == "integer_partition":
        if not 1 <= input_value <= 300:
            expected_from_source = I64_MIN
        else:
            partitions = [0] * (input_value + 1)
            partitions[0] = 1
            for part in range(1, input_value + 1):
                for total in range(part, input_value + 1):
                    partitions[total] += partitions[total - part]
            expected_from_source = partitions[input_value]
        if expected_result != expected_from_source:
            raise ValueError("integer_partition expected_result must match the bounded unordered partition count")
        return
    if algorithm == "mobius_function":
        if not 1 <= input_value <= 10_000:
            expected_from_source = I64_MIN
        else:
            remaining = input_value
            distinct_prime_factors = 0
            factor = 2
            square_factor = False
            while factor * factor <= remaining:
                if remaining % factor == 0:
                    remaining //= factor
                    if remaining % factor == 0:
                        square_factor = True
                        break
                    distinct_prime_factors += 1
                    while remaining % factor == 0:
                        remaining //= factor
                factor = 3 if factor == 2 else factor + 2
            if square_factor:
                expected_from_source = 0
            else:
                if remaining > 1:
                    distinct_prime_factors += 1
                expected_from_source = 1 if distinct_prime_factors % 2 == 0 else -1
        if expected_result != expected_from_source:
            raise ValueError("mobius_function expected_result must match the bounded distinct-prime Möbius value")
        return
    if algorithm == "fibonacci_recursive":
        if 0 <= input_value <= 30:
            previous, current = 0, 1
            for _ in range(input_value):
                previous, current = current, previous + current
            expected_from_source = previous
        else:
            expected_from_source = -1
        if expected_result != expected_from_source:
            raise ValueError("fibonacci_recursive expected_result must match the bounded Fibonacci recurrence")
        return
    if algorithm == "prime_check_naive":
        if input_value < 2:
            expected_from_source = 0
        elif input_value > 10_000:
            expected_from_source = -1
        else:
            expected_from_source = int(all(input_value % divisor != 0
                                           for divisor in range(2, input_value)))
        if expected_result != expected_from_source:
            raise ValueError("prime_check_naive expected_result must match bounded plain trial division")
        return
    if algorithm == "reverse_number":
        if not 0 <= input_value <= 1_000_000_000:
            expected_from_source = -1
        else:
            source_input = input_value
            expected_from_source = 0
            while source_input:
                expected_from_source = expected_from_source * 10 + source_input % 10
                source_input //= 10
        if expected_result != expected_from_source:
            raise ValueError("reverse_number expected_result must match repeated decimal digit reversal")
        return
    if algorithm == "hardy_ramanujanalgo":
        if not 1 <= input_value <= 2_147_483_647:
            expected_from_source = -1
        else:
            remaining = input_value
            distinct_factors = 0
            divisor = 2
            while divisor * divisor <= remaining:
                if remaining % divisor == 0:
                    distinct_factors += 1
                    while remaining % divisor == 0:
                        remaining //= divisor
                divisor = 3 if divisor == 2 else divisor + 2
            if remaining > 1:
                distinct_factors += 1
            expected_from_source = distinct_factors
        if expected_result != expected_from_source:
            raise ValueError("hardy_ramanujanalgo expected_result must match exact distinct-prime-factor counting")
        return
    if algorithm == "fast_factorial":
        expected_from_source = math.factorial(input_value) if 0 <= input_value <= 20 else -1
        if expected_result != expected_from_source:
            raise ValueError("fast_factorial expected_result must match the exact factorial on 0..20")
        return
    if algorithm == "alaw":
        if not -32768 <= input_value <= 32767:
            expected_from_source = -1
        else:
            sign = 0x80 if input_value < 0 else 0
            magnitude = -input_value - 1 if input_value < 0 else input_value
            segment, mask = 7, 0x4000
            while (magnitude & mask) == 0 and segment > 0:
                segment -= 1
                mask >>= 1
            shift = segment + 3 if segment != 0 else 4
            quantization = (magnitude >> shift) & 0x0F
            expected_from_source = (sign | (segment << 4) | quantization) ^ 0xD5
        if expected_result != expected_from_source:
            raise ValueError("alaw expected_result must match the bounded A-law encoder")
        return
    if algorithm == "alaw_decode":
        if not 0 <= input_value <= 255:
            expected_from_source = -1
        else:
            codeword = input_value ^ 0xD5
            magnitude = ((codeword & 0x0F) << 4) | 8
            segment = (codeword & 0x70) >> 4
            if segment != 0:
                magnitude += 0x100
            shift = segment - 1 if segment > 1 else 0
            magnitude <<= shift
            expected_from_source = -magnitude if codeword & 0x80 else magnitude
        if expected_result != expected_from_source:
            raise ValueError("alaw_decode expected_result must match the bounded A-law decoder")
        return
    if algorithm == "parity_check":
        if not -(2**31) <= input_value <= 2**31 - 1:
            expected_from_source = -1
        elif input_value < 0:
            expected_from_source = 1
        else:
            expected_from_source = int(input_value.bit_count() % 2 == 0)
        if expected_result != expected_from_source:
            raise ValueError("parity_check expected_result must match the pinned positive-only bit loop")
        return
    if algorithm == "minimum_steps_to_one":
        if not 1 <= input_value <= 10_000:
            expected_from_source = -1
        else:
            table = [input_value + 1] * (input_value + 1)
            table[1] = 0
            for index in range(1, input_value):
                next_value = index + 1
                table[next_value] = min(table[next_value], table[index] + 1)
                if index * 2 <= input_value:
                    table[index * 2] = min(table[index * 2], table[index] + 1)
                if index * 3 <= input_value:
                    table[index * 3] = min(table[index * 3], table[index] + 1)
            expected_from_source = table[input_value]
        if expected_result != expected_from_source:
            raise ValueError("minimum_steps_to_one expected_result must match pinned forward tabulation")
        return
    if algorithm != "fibonacci_number_golden_ration":
        return
    if not 0 <= input_value <= 70:
        expected_from_source = -1
    elif input_value <= 1:
        expected_from_source = input_value
    else:
        sqrt5 = math.sqrt(5.0)
        phi = (1.0 + sqrt5) / 2.0
        psi = (1.0 - sqrt5) / 2.0
        result = (math.pow(phi, input_value) - math.pow(psi, input_value)) / sqrt5
        expected_from_source = math.floor(result + 0.5)
    if expected_result != expected_from_source:
        raise ValueError("fibonacci_number_golden_ration expected_result must match the bounded Binet formula")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", type=Path)
    parser.add_argument("--algorithm")
    parser.add_argument("--language")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--executable", type=Path)
    parser.add_argument("--compiler")
    parser.add_argument("--compiler-version")
    parser.add_argument("--build-flags")
    parser.add_argument("--build-command")
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()

    metadata_options = (args.algorithm, args.language, args.source, args.executable,
                        args.compiler, args.compiler_version, args.build_flags, args.build_command)
    manifest = None
    if args.build_manifest is not None:
        if any(option is not None for option in metadata_options):
            parser.error("--build-manifest cannot be combined with individual build metadata options")
        manifest_path = args.build_manifest.resolve()
        if not manifest_path.is_file():
            parser.error(f"build manifest file does not exist: {manifest_path}")
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            if manifest.get("family") != "scalar":
                parser.error("build manifest must declare the scalar ABI family")
            algorithm = manifest["algorithm"]
            language = manifest["language"]
            source_path = (ROOT / manifest["source_path"]).resolve()
            binary = manifest["binaries"]["scalar_runner"]
            executable_path = Path(binary["path"]).resolve()
            compiler = manifest["compiler"]
            compiler_version = manifest["compiler_version"]
            build_flags = manifest["build_flags"]
            commands = manifest["commands"]
            build_command = " && ".join(shlex.join(command) for command in commands)
        except (AttributeError, KeyError, TypeError, ValueError) as error:
            parser.error(f"invalid scalar build manifest: {error}")
    else:
        required_options = (args.algorithm, args.language, args.source, args.executable,
                            args.compiler, args.compiler_version, args.build_command)
        if any(option is None for option in required_options):
            parser.error("supply --build-manifest or all individual build metadata options")
        algorithm, language = args.algorithm, args.language
        source_path, executable_path = args.source.resolve(), args.executable.resolve()
        compiler, compiler_version = args.compiler, args.compiler_version
        build_flags, build_command = args.build_flags or "", args.build_command

    letter = algorithm[0].lower() if algorithm and algorithm[0].isalpha() else "0-9"
    workload_path = (args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json").resolve()
    runner_source = ROOT / "benchmarks" / "harness" / "scalar_runner.c"
    output_path = (args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl").resolve()

    for path, label in (
        (workload_path, "workload"),
        (source_path, "source"),
        (executable_path, "executable"),
        (runner_source, "runner source"),
    ):
        if not path.is_file():
            parser.error(f"{label} file does not exist: {path}")
    try:
        source_relative = source_path.relative_to(ROOT).as_posix()
    except ValueError:
        parser.error("--source must be inside the encyclopedia repository")
    if manifest is not None:
        binary = manifest["binaries"]["scalar_runner"]
        if (sha256_file(source_path) != manifest.get("source_sha256")
                or sha256_file(executable_path) != binary.get("sha256")
                or sha256_file(runner_source) != binary.get("harness_sha256")):
            parser.error("build manifest no longer matches its source, binary, or scalar harness")

    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload["algorithm"] != algorithm:
        parser.error(f"workload algorithm is {workload['algorithm']!r}, not {algorithm!r}")
    timing = workload["measurement"]
    sample_count = args.samples if args.samples is not None else int(timing["sample_count"])
    warmup_rounds = args.warmups if args.warmups is not None else int(timing["warmup_rounds"])
    repetitions = (
        args.repetitions
        if args.repetitions is not None
        else int(timing["repetitions_per_sample"])
    )
    if sample_count < 1 or warmup_rounds < 0 or repetitions < 1:
        parser.error("samples and repetitions must be positive; warmups cannot be negative")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    environment = {
        "os": platform.system(),
        "os_release": platform.release(),
        "architecture": platform.machine(),
        "cpu_model": platform.processor().strip() or None,
        "logical_cpu_count": os.cpu_count(),
        "python_version": platform.python_version(),
    }
    implementation = {
        "language": language,
        "source_path": source_relative,
        "source_sha256": sha256_file(source_path),
        "runner_source_sha256": sha256_file(runner_source),
        "binary_sha256": sha256_file(executable_path),
        "compiler": compiler,
        "compiler_version": compiler_version,
        "build_flags": build_flags,
        "build_command": build_command,
    }

    spec_sha256 = sha256_file(workload_path)
    records: list[dict[str, Any]] = []
    for case in workload["cases"]:
        input_value = int(case["input_value"])
        expected_result = int(case["expected_result"])
        validate_expected_result(algorithm, input_value, expected_result)
        command = [
            str(executable_path),
            str(input_value),
            str(expected_result),
            str(sample_count),
            str(warmup_rounds),
            str(repetitions),
        ]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            sys.stderr.write(completed.stderr)
            raise SystemExit(f"scalar runner failed for case {case['id']!r}")
        try:
            raw = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            raise SystemExit(f"scalar runner emitted invalid JSON for {case['id']!r}: {error}") from error
        if int(raw["observed_result"]) != expected_result:
            raise SystemExit(f"scalar runner returned the wrong result for {case['id']!r}")
        if len(raw["samples_ns"]) != sample_count:
            raise SystemExit(f"scalar runner returned the wrong sample count for {case['id']!r}")

        records.append(
            {
                "schema_version": "1.0.0",
                "run_id": run_id,
                "algorithm": algorithm,
                "implementation": implementation,
                "environment": environment,
                "workload": {
                    "id": workload["id"],
                    "spec_sha256": spec_sha256,
                    "input_length": None,
                    "input_value": input_value,
                    "case": str(case["id"]),
                    "target": None,
                    "expected_result": expected_result,
                },
                "measurement": {
                    "timer": "C clock() process CPU time",
                    "timer_resolution_ns": float(raw["timer_resolution_ns"]),
                    "comparison_model": "scalar_call",
                    "target_comparisons_per_sample": None,
                    "warmup_rounds": warmup_rounds,
                    "repetitions_per_sample": repetitions,
                    "samples_ns": [int(sample) for sample in raw["samples_ns"]],
                    "observed_result": int(raw["observed_result"]),
                    "result_checksum": int(raw["result_checksum"]),
                },
            }
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("a", encoding="utf-8", newline="\n") as output:
        for record in records:
            output.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
