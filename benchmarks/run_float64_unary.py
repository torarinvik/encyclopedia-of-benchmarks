#!/usr/bin/env python3
"""Record a built one-input binary64 benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess

from build_abi import ROOT, sha256_file
from gauss_legendre_oracle import INVALID_RESULT as GAUSS_LEGENDRE_INVALID_RESULT
from gauss_legendre_oracle import expected_result as gauss_legendre_expected
from fast_inverse_sqrt_cpp_oracle import INVALID_RESULT as FAST_INVERSE_SQRT_CPP_INVALID_RESULT
from fast_inverse_sqrt_cpp_oracle import expected_result as fast_inverse_sqrt_cpp_expected


def problem207_source_result(max_proportion: float) -> float:
    if not math.isfinite(max_proportion) or not 1e-5 <= max_proportion <= 1.0:
        return -1e300
    partitions = 0
    perfect_partitions = 0
    while partitions < 5_000_000:
        partitions += 1
        candidate = partitions * (partitions + 1)
        if (partitions + 1) & partitions == 0:
            perfect_partitions += 1
        if perfect_partitions / partitions < max_proportion:
            return float(candidate)
    return -1e300


def problem587_circle_bottom_arc_integral(point: float) -> float:
    return ((1 - 2 * point) * math.sqrt(point - point**2)
            + 2 * point + math.asin(math.sqrt(1 - point))) / 4


def problem587_concave_triangle_area(circles_number: int) -> float:
    intersection_y = (circles_number + 1 - math.sqrt(2 * circles_number)) / (
        2 * (circles_number**2 + 1))
    intersection_x = circles_number * intersection_y
    triangle_area = intersection_x * intersection_y / 2
    concave_region_area = (problem587_circle_bottom_arc_integral(1 / 2)
                           - problem587_circle_bottom_arc_integral(intersection_x))
    return triangle_area + concave_region_area


def problem587_source_result(fraction: float) -> float:
    if not math.isfinite(fraction) or not 0.001 <= fraction <= 0.1:
        return -1e300
    l_section_area = (1 - math.pi / 4) / 4
    for circles_number in range(1, 100_001):
        if problem587_concave_triangle_area(circles_number) / l_section_area < fraction:
            return float(circles_number)
    return -1e300


def gamma_source_result(value: float) -> float:
    if (not math.isfinite(value) or not 0.5 <= value <= 20.0
            or not (value * 2.0).is_integer()):
        return -1e300
    if value.is_integer():
        result, current = 1.0, 1.0
    else:
        result, current = math.sqrt(math.pi), 0.5
    while current < value:
        current += 1.0
        result *= current - 1.0
    return result


def encode_case(case: dict, algorithm: str, absolute_tolerance: float,
                relative_tolerance: float) -> tuple[float, float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 1
            or type(values[0]) not in (int, float) or not math.isfinite(float(values[0]))
            or type(expected) not in (int, float) or not math.isfinite(float(expected))):
        raise ValueError("float64 unary cases require one finite input and one finite expected result")
    value, expected_value = float(values[0]), float(expected)
    if algorithm == "radians":
        valid = -1_000_000.0 <= value <= 1_000_000.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid radians inputs must use the -1e300 result sentinel")
        else:
            source_result = value / (180.0 / math.pi)
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("radians expected result must preserve degree / (180 / pi)")
    elif algorithm == "relu":
        valid = (value.is_integer() and -16_777_216.0 <= value <= 16_777_216.0)
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid relu inputs must use the -1e300 result sentinel")
        elif expected_value != max(0.0, value):
            raise ValueError("relu expected result must match max(0, x)")
    elif algorithm == "binary_step":
        valid = -1_000_000.0 <= value <= 1_000_000.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid binary_step inputs must use the -1e300 result sentinel")
        elif expected_value != float(value >= 0.0):
            raise ValueError("binary_step expected result must be 1 when x >= 0 and 0 otherwise")
    elif algorithm == "gaussian_error_linear_unit":
        valid = -100.0 <= value <= 100.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid gaussian_error_linear_unit inputs must use the -1e300 result sentinel")
        else:
            source_result = value * (1.0 / (1.0 + math.exp(-1.702 * value)))
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("gaussian_error_linear_unit expected result must match the pinned Python operation order")
    elif algorithm == "gaussian_error_linear_unit_tanh":
        valid = -100.0 <= value <= 100.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid gaussian_error_linear_unit_tanh inputs must use the -1e300 result sentinel")
        else:
            z = math.sqrt(2.0 / math.pi) * (value + 0.044715 * (value ** 3))
            if z < -350.0:
                tangent = -1.0
            elif z > 350.0:
                tangent = 1.0
            else:
                tangent = 2.0 / (1.0 + math.exp(-2.0 * z)) - 1.0
            source_result = value * 0.5 * (1.0 + tangent)
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("gaussian_error_linear_unit_tanh expected result must match the pinned Rust expression")
    elif algorithm == "swish":
        valid = -100.0 <= value <= 100.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid swish inputs must use the -1e300 result sentinel")
        else:
            source_result = value * (1.0 / (1.0 + math.exp(-(1.0 * value))))
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("swish expected result must match the pinned Python operation order")
    elif algorithm == "newton_raphson_root":
        valid = 1.0 <= value <= 4.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError(f"invalid {algorithm} guesses must use the -1e300 result sentinel")
        else:
            from newton_raphson_root_oracle import expected_result as source_expected
            source_result = source_expected(value)
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError(f"{algorithm} expected result does not match its bounded Newton iteration")
    elif algorithm == "square_root_with_newton_raphson_method":
        valid = value.is_integer() and 1.0 <= value <= 2_147_483_647.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid square_root_with_newton_raphson_method inputs must use -1e300")
        else:
            guess = value
            root = 0.5 * (guess + value / guess)
            while abs(root - guess) > 1e-7:
                guess = root
                root = 0.5 * (guess + value / guess)
            if abs(expected_value - root) > absolute_tolerance + relative_tolerance * abs(root):
                raise ValueError("square_root_with_newton_raphson_method expected result must match the Newton iteration")
    elif algorithm == "babylonian_method":
        valid = value.is_integer() and 2.0 <= value <= 999_999.0
        floor_root = math.isqrt(int(value)) if valid else 0
        if valid and floor_root * floor_root == int(value):
            valid = False
        if not valid:
            if expected_value != -1.0:
                raise ValueError("invalid babylonian_method inputs must use the -1.0 result sentinel")
        else:
            x0 = float(floor_root)
            source_result = (value / x0 + x0) / 2.0
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("babylonian_method expected result must match the pinned first-update path")
    elif algorithm == "fast_inverse_sqrt_go":
        valid = 1e-6 <= value <= 1e6
        if not valid:
            if expected_value != -1.0:
                raise ValueError("invalid fast_inverse_sqrt_go inputs must use the -1.0 result sentinel")
        else:
            def f32(number: float) -> float:
                return struct.unpack("<f", struct.pack("<f", number))[0]

            source_input = f32(value)
            x2 = f32(source_input * f32(0.5))
            bits = struct.unpack("<I", struct.pack("<f", source_input))[0]
            seed_bits = 0x5F3759DF - (bits >> 1)
            estimate = struct.unpack("<f", struct.pack("<I", seed_bits))[0]
            for _ in range(2):
                product = f32(f32(x2 * estimate) * estimate)
                correction = f32(f32(1.5) - product)
                estimate = f32(estimate * correction)
            if expected_value != estimate:
                raise ValueError("fast_inverse_sqrt_go expected result must match two binary32 Newton corrections")
    elif algorithm == "fast_inverse_sqrt_cpp":
        source_result = fast_inverse_sqrt_cpp_expected(value)
        if source_result == FAST_INVERSE_SQRT_CPP_INVALID_RESULT:
            if expected_value != FAST_INVERSE_SQRT_CPP_INVALID_RESULT:
                raise ValueError("invalid fast_inverse_sqrt_cpp inputs must use the -1.0 result sentinel")
        elif abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
            raise ValueError("fast_inverse_sqrt_cpp expected result must match two binary64 Newton corrections")
    elif algorithm == "sqrt":
        valid = 1e-6 <= value <= 1e6
        if not valid:
            if expected_value != -1.0:
                raise ValueError("invalid sqrt inputs must use the -1.0 result sentinel")
        else:
            def f32(number: float) -> float:
                return struct.unpack("<f", struct.pack("<f", number))[0]

            source_input = f32(value)
            x2 = f32(source_input * f32(0.5))
            bits = struct.unpack("<I", struct.pack("<f", source_input))[0]
            seed_bits = 0x5F3759DF - (bits >> 1)
            estimate = struct.unpack("<f", struct.pack("<I", seed_bits))[0]
            for _ in range(2):
                product = f32(f32(x2 * estimate) * estimate)
                correction = f32(f32(1.5) - product)
                estimate = f32(estimate * correction)
            source_result = f32(1.0 / estimate)
            if expected_value != source_result:
                raise ValueError("sqrt expected result must match the binary32 reciprocal of two Newton corrections")
    elif algorithm == "decimal_isolate":
        valid = 0.0 < value <= 999_999.0
        scaled_value = value * 10_000.0 if valid else 0.0
        scaled = int(scaled_value) if valid else 0
        valid = (valid and float(scaled) == scaled_value
                 and float(scaled) / 10_000.0 == value
                 and scaled % 625 == 0 and scaled % 10_000 != 0)
        if not valid:
            if expected_value != -1.0:
                raise ValueError("invalid decimal_isolate inputs must use the -1.0 result sentinel")
        else:
            source_result = (scaled % 10_000) / 10_000.0
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("decimal_isolate expected result must match the exact binary decimal fraction")
    elif algorithm == "orbital_capture_area":
        valid = 0.0 <= value <= 1.0e10
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid orbital_capture_area inputs must use the -1e300 result sentinel")
        else:
            source_result = float(round(math.pi * value * value, 0))
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("orbital_capture_area expected result must match the pinned circular-area formula")
    elif algorithm == "problem58":
        valid = 0.1 <= value <= 0.6
        if not valid:
            if expected_value != -1.0:
                raise ValueError("invalid problem58 thresholds must use the -1.0 result sentinel")
        else:
            def is_prime(candidate: int) -> bool:
                if candidate < 2:
                    return False
                if candidate < 4:
                    return True
                if candidate % 2 == 0 or candidate % 3 == 0:
                    return False
                divisor = 5
                while divisor <= candidate // divisor:
                    if candidate % divisor == 0 or candidate % (divisor + 2) == 0:
                        return False
                    divisor += 6
                return True

            side, prime_count = 3, 3
            while prime_count / (2 * side - 1) >= value:
                square, step = side * side, side + 1
                prime_count += sum(is_prime(square + index * step) for index in (1, 2, 3))
                side += 2
            source_result = float(side)
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("problem58 expected result must match the first side below the diagonal-prime ratio")
    elif algorithm == "problem207":
        valid = 1e-5 <= value <= 1.0
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid problem207 thresholds must use the -1e300 result sentinel")
        else:
            source_result = problem207_source_result(value)
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("problem207 expected result must match the strict partition-ratio scan")
    elif algorithm == "problem587":
        valid = 0.001 <= value <= 0.1
        if not valid:
            if expected_value != -1e300:
                raise ValueError("invalid problem587 fractions must use the -1e300 result sentinel")
        else:
            source_result = problem587_source_result(value)
            if abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
                raise ValueError("problem587 expected result must match the concave-triangle area scan")
    elif algorithm == "gamma":
        source_result = gamma_source_result(value)
        if source_result == -1e300:
            if expected_value != -1e300:
                raise ValueError("invalid gamma inputs must use the -1e300 result sentinel")
        elif abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
            raise ValueError("gamma expected result must match the bounded half-integer recurrence")
    elif algorithm == "gauss_legendre":
        source_result = gauss_legendre_expected([value])
        if source_result == GAUSS_LEGENDRE_INVALID_RESULT:
            if expected_value != GAUSS_LEGENDRE_INVALID_RESULT:
                raise ValueError("invalid gauss_legendre inputs must use the -1e300 result sentinel")
        elif abs(expected_value - source_result) > absolute_tolerance + relative_tolerance * abs(source_result):
            raise ValueError("gauss_legendre expected result must match the bounded Gauss-Legendre recurrence")
    return value, expected_value


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
    if manifest.get("family") != "float64_unary":
        parser.error("build manifest must declare the float64_unary ABI")
    algorithm = manifest["algorithm"]
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_unary_runner"]
    executable = Path(binary["path"])
    runner_source = ROOT / "benchmarks/harness/float64_unary_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner_source) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "float64_unary_call"):
        parser.error("workload does not match the built float64 unary algorithm")
    timing = workload["measurement"]
    tolerance = float(timing["relative_tolerance"])
    absolute_tolerance = float(timing.get("absolute_tolerance", 0.0))
    if (not math.isfinite(tolerance) or tolerance <= 0.0
            or not math.isfinite(absolute_tolerance) or absolute_tolerance < 0.0):
        parser.error("workload float64 tolerances must be finite, with positive relative and nonnegative absolute values")
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
        value, expected = encode_case(case, algorithm, absolute_tolerance, tolerance)
        command = [str(executable), *(format(number, ".17g") for number in
                   (value, expected, tolerance, absolute_tolerance)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64 unary runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        if (not math.isfinite(observed)
                or abs(observed - expected) > absolute_tolerance + tolerance * abs(expected)
                or len(raw["samples_ns"]) != samples):
            raise ValueError(f"float64 unary runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [value],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_unary_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "result_checksum": raw["result_checksum"],
                                        "result_relative_tolerance": tolerance,
                                        "result_absolute_tolerance": absolute_tolerance}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
