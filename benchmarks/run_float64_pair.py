#!/usr/bin/env python3
"""Record a built two-input binary64 benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
from pathlib import Path
import platform
import shlex
import subprocess

from build_abi import ROOT, sha256_file

SUPPORTED_ALGORITHMS = {"conditional_probability", "arithmetic_geometric_mean", "speed_conversions", "speed_conversion",
                       "leaky_relu", "exponential_linear_unit", "elu", "composite_simpson_rule",
                       "false_position", "to_polar_angle_degrees", "problem144", "circle",
                       "sigmoid_without_inbuilt"}


def source_agm(a: float, g: float) -> float:
    """Match the pinned JavaScript AGM update and stopping condition."""
    if a == g:
        return a
    while True:
        old_a = a
        a = (a + g) / 2.0
        g = math.sqrt(old_a * g)
        if a == old_a or math.isnan(a):
            return a


def problem144_source_result(first_x: float, first_y: float) -> float:
    """Mirror the pinned tangent-gradient reflection and alternate ellipse root."""
    invalid = -1e300
    if (not math.isfinite(first_x) or not math.isfinite(first_y)
            or not 1e-5 <= first_x <= 5.0 or not -10.0 <= first_y <= 0.0
            or abs(4.0 * first_x * first_x + first_y * first_y - 100.0) > 1e-6):
        return invalid

    def next_point(x: float, y: float, incoming_gradient: float) -> tuple[float, float, float]:
        normal_gradient = y / 4.0 / x
        s2 = 2.0 * normal_gradient / (1.0 + normal_gradient * normal_gradient)
        c2 = (1.0 - normal_gradient * normal_gradient) / (1.0 + normal_gradient * normal_gradient)
        outgoing_gradient = (s2 - c2 * incoming_gradient) / (c2 + s2 * incoming_gradient)
        quadratic = outgoing_gradient * outgoing_gradient + 4.0
        line_offset = y - outgoing_gradient * x
        linear = 2.0 * outgoing_gradient * line_offset
        constant = line_offset * line_offset - 100.0
        discriminant = linear * linear - 4.0 * quadratic * constant
        if discriminant < 0.0:
            return math.nan, math.nan, outgoing_gradient
        root = math.sqrt(discriminant)
        minus = (-linear - root) / (2.0 * quadratic)
        plus = (-linear + root) / (2.0 * quadratic)
        close = abs(plus - x) <= 1e-9 * max(abs(plus), abs(x))
        next_x = minus if close else plus
        return next_x, y + outgoing_gradient * (next_x - x), outgoing_gradient

    x, y = first_x, first_y
    gradient = (10.1 - y) / -x
    reflections = 0
    while not (-0.01 <= x <= 0.01 and y > 0.0):
        if reflections >= 10_000:
            return invalid
        x, y, gradient = next_point(x, y, gradient)
        if not math.isfinite(x) or not math.isfinite(y):
            return invalid
        reflections += 1
    return float(reflections)


def encode_case(case: dict, tolerance: float,
                algorithm: str = "conditional_probability",
                absolute_tolerance: float = 0.0) -> tuple[float, float, float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values)
            or type(expected) not in (int, float) or not math.isfinite(float(expected))):
        raise ValueError("float64 pair cases require two finite values and one finite expected result")
    if not math.isfinite(tolerance) or tolerance <= 0.0:
        raise ValueError("relative tolerance must be positive and finite")
    first, second = map(float, values)
    if algorithm == "conditional_probability":
        valid = (0.0 <= first <= second and 0.0 < second <= 1.0)
        if valid and not 0.0 <= expected <= 1.0:
            raise ValueError("valid conditional probability inputs must produce a result in [0, 1]")
        if not valid and expected != -1.0:
            raise ValueError("invalid conditional probability inputs must use the -1 result sentinel")
        if valid and expected == -1.0:
            raise ValueError("valid conditional probability inputs cannot use the invalid-input sentinel")
    elif algorithm == "arithmetic_geometric_mean":
        valid = (0.0 <= first <= 1_000_000.0 and 0.0 <= second <= 1_000_000.0)
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid arithmetic_geometric_mean inputs must use the -1 result sentinel")
        else:
            if expected == -1.0 or not 0.0 <= expected <= max(first, second):
                raise ValueError("valid arithmetic_geometric_mean inputs must produce a nonnegative result")
            expected_agm = source_agm(first, second)
            if abs(expected - expected_agm) > tolerance * max(1.0, abs(first), abs(second)):
                raise ValueError("arithmetic_geometric_mean expected result must match the pinned iteration")
    elif algorithm == "speed_conversions":
        valid = (0.0 <= first <= 1_000_000.0 and 0.0 <= second <= 15.0
                 and second.is_integer())
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid speed conversion inputs must use the -1 result sentinel")
        else:
            unit_from, unit_to = divmod(int(second), 4)
            factors = (1.0, 3.6, 1.609344, 1.852)
            inverse_factors = (1.0, 0.277777778, 0.621371192, 0.539956803)
            expected_conversion = round(first * factors[unit_from] * inverse_factors[unit_to], 3)
            if abs(expected - expected_conversion) > tolerance * max(1.0, abs(first)):
                raise ValueError("speed_conversions expected result must match the pinned conversion")
            if expected == -1.0:
                raise ValueError("valid speed conversion inputs cannot use the invalid-input sentinel")
    elif algorithm == "speed_conversion":
        valid = (0.0 <= first <= 1_000_000.0 and 0.0 <= second <= 24.0
                 and second.is_integer())
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid speed_conversion inputs must use the -1 result sentinel")
        else:
            source, destination = divmod(int(second), 5)
            from_factors = (1.609344, 1.0, 3.6, 1.097, 1.852)
            to_factors = (0.6213712, 1.0, 0.277778, 0.911344, 0.539957)
            source_result = math.floor(first * from_factors[source] * to_factors[destination] * 100.0 + 0.5) / 100.0
            if expected == -1.0 or abs(expected - source_result) > tolerance * max(1.0, abs(first)):
                raise ValueError("speed_conversion expected result must match PHP multiplication and rounding")
    elif algorithm == "leaky_relu":
        valid = (-1_000_000.0 <= first <= 1_000_000.0
                 and -1_000_000.0 <= second <= 1_000_000.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid leaky_relu inputs must use the -1e300 result sentinel")
        else:
            expected_value = first * second if first < 0.0 else first
            scale = max(1.0, abs(first), abs(second))
            if abs(expected - expected_value) > tolerance * scale:
                raise ValueError("leaky_relu expected result must match x < 0 ? x * alpha : x")
    elif algorithm == "exponential_linear_unit":
        valid = (-100.0 <= first <= 100.0 and -1_000_000.0 <= second <= 1_000_000.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid exponential_linear_unit inputs must use the -1e300 result sentinel")
        else:
            expected_value = first * (second * (math.exp(first) - 1.0)) if first < 0.0 else first
            scale = max(1.0, abs(first), abs(second))
            if abs(expected - expected_value) > tolerance * scale:
                raise ValueError("exponential_linear_unit expected result must match the pinned Rust expression")
    elif algorithm == "elu":
        valid = (-100.0 <= first <= 100.0 and -1_000_000.0 <= second <= 1_000_000.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid elu inputs must use the -1e300 result sentinel")
        else:
            expected_value = second * (math.exp(first) - 1.0) if first < 0.0 else first
            scale = max(1.0, abs(first), abs(second))
            if expected == -1e300 or abs(expected - expected_value) > tolerance * scale:
                raise ValueError("elu expected result must match alpha * (exp(x) - 1) for x < 0, otherwise x")
    elif algorithm == "sigmoid_without_inbuilt":
        valid = (-10.0 <= first <= 10.0 and -10.0 <= second <= 10.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid sigmoid_without_inbuilt inputs must use the -1e300 result sentinel")
        else:
            expected_value = 1.0 / (1.0 + math.exp(-second * first))
            scale = max(1.0, abs(first), abs(second))
            if expected == -1e300 or abs(expected - expected_value) > tolerance * scale:
                raise ValueError("sigmoid_without_inbuilt expected result must match 1 / (1 + exp(-a*x))")
    elif algorithm == "composite_simpson_rule":
        valid = (2.0 <= first <= 128.0 and first.is_integer() and int(first) % 2 == 0
                 and 0.0 <= second <= 3.0 and second.is_integer())
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid composite_simpson_rule inputs must use the -1 result sentinel")
        else:
            interval_count = int(first)
            function_selector = int(second)
            step = (3.0 - 1.0) / interval_count

            def integrand(x: float) -> float:
                if function_selector == 0:
                    return math.sqrt(x) + math.log(x)
                if function_selector == 1:
                    return math.exp(-x) * (4.0 - math.pow(x, 2.0))
                if function_selector == 2:
                    return math.sqrt(2.0 * math.pow(x, 3.0) + 3.0)
                return x + math.log(2.0 * x + 1.0)

            source_sum = 0.0
            x = 1.0
            for index in range(interval_count + 1):
                sample = integrand(x)
                if index == 0 or index == interval_count:
                    source_sum += sample
                elif index % 2 == 1:
                    source_sum += 4.0 * sample
                else:
                    source_sum += 2.0 * sample
                x += step
            expected_value = source_sum * (step / 3.0)
            scale = max(1.0, abs(first), abs(second))
            if expected == -1.0 or abs(expected - expected_value) > tolerance * scale:
                raise ValueError("composite_simpson_rule expected result must match the pinned weighted sum")
    elif algorithm == "false_position":
        first_value = first * first - first
        second_value = second * second - second
        valid = (0.125 <= first <= 0.875 and
                 ((-2.0 <= second <= -0.125) or (1.125 <= second <= 3.0)) and
                 first_value < 0.0 and second_value > 0.0)
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid false_position inputs must use the -1 result sentinel")
        else:
            root = 0.0 if second < 0.0 else 1.0
            if expected == -1.0 or abs(expected - root) > tolerance * max(1.0, abs(first), abs(second)):
                raise ValueError("false_position expected result must match the uniquely bracketed root")
    elif algorithm == "to_polar_angle_degrees":
        valid = (-1_000_000.0 <= first <= 1_000_000.0
                 and -1_000_000.0 <= second <= 1_000_000.0
                 and not (first == 0.0 and second == 0.0))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid to_polar_angle_degrees inputs must use the -1e300 result sentinel")
        else:
            if first == 0.0:
                ratio = math.copysign(math.inf, second * math.copysign(1.0, first))
            else:
                ratio = second / first
            angle = math.atan(ratio)
            if first < 0.0:
                angle += math.pi
            expected_value = angle * 180.0 / math.pi
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(first), abs(second)):
                raise ValueError("to_polar_angle_degrees expected result must match atan(y/x), x<0 adjustment, and degree conversion")
    elif algorithm == "problem144":
        valid = (1e-5 <= first <= 5.0 and -10.0 <= second <= 0.0
                 and abs(4.0 * first * first + second * second - 100.0) <= 1e-6)
        expected_from_source = problem144_source_result(first, second)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid problem144 points must use the -1e300 result sentinel")
        elif (expected == -1e300
              or abs(expected - expected_from_source) > tolerance * max(1.0, abs(first), abs(second))):
            raise ValueError("problem144 expected result must match the bounded ellipse reflection count")
    elif algorithm == "circle":
        valid = (-1_000_000.0 <= first <= 1_000_000.0
                 and second in (0.0, 1.0))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid circle inputs must use the -1e300 result sentinel")
        else:
            expected_value = first * 2.0 * math.pi if second == 0.0 else math.pow(first, 2.0) * math.pi
            scale = max(1.0, abs(first), abs(second))
            if expected == -1e300 or abs(expected - expected_value) > max(absolute_tolerance, tolerance * scale):
                raise ValueError("circle expected result must match the pinned perimeter/area expression")
    else:
        raise ValueError(f"unsupported float64_pair algorithm: {algorithm}")
    return first, second, float(expected)


def matches(observed: float, expected: float, tolerance: float,
            first: float, second: float, absolute_tolerance: float = 0.0) -> bool:
    scale = max(1.0, abs(first), abs(second))
    return math.isfinite(observed) and abs(observed - expected) <= max(absolute_tolerance, tolerance * scale)


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
    algorithm = manifest.get("algorithm")
    if manifest.get("family") != "float64_pair" or algorithm not in SUPPORTED_ALGORITHMS:
        parser.error("build manifest must declare a supported float64_pair ABI")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_pair_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/float64_pair_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0]
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "float64_pair_call"):
        parser.error("workload does not match the built float64 pair algorithm")
    timing = workload["measurement"]
    tolerance = float(timing.get("relative_tolerance", timing.get("input_scaled_tolerance", 0.0)))
    absolute_tolerance = float(timing.get("absolute_tolerance", 0.0))
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
        first, second, expected = encode_case(case, tolerance, algorithm, absolute_tolerance)
        command = [str(executable), *(format(value, ".17g") for value in
                   (first, second, expected, tolerance)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64 pair runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        result_matches = matches(observed, expected, tolerance, first, second, absolute_tolerance)
        if not result_matches \
                or len(raw["samples_ns"]) != samples:
            raise ValueError(f"float64 pair runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [first, second],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_pair_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
                                        "result_checksum": raw["result_checksum"],
                                        "result_input_scaled_tolerance": tolerance}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
