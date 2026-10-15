#!/usr/bin/env python3
"""Record a built three-input binary64 benchmark."""

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

SUPPORTED_ALGORITHMS = {"lerp", "arc_length", "bayes_theorem", "affine_converter", "brent_method_extrema", "annuity_due_future_value", "count_numbers_divisible", "sum_of_geometric_progression", "sum_of_harmonic_series", "equated_monthly_installments", "pressure", "order_of_magnitude_conversion", "pressure_conversions", "addition_rule", "electric_power", "cartesian_to_polar", "ohms_law", "first_law_of_thermodynamics", "length_conversion"}


def encode_case(case: dict, tolerance: float, algorithm: str = "lerp") -> tuple[float, float, float, float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values)
            or type(expected) not in (int, float) or not math.isfinite(float(expected))):
        raise ValueError("float64 triple cases require three finite values and one finite expected result")
    start, end, t = map(float, values)
    if algorithm == "lerp":
        if abs(start) > 1e12 or abs(end) > 1e12 or not 0.0 <= t <= 1.0:
            raise ValueError("lerp inputs must use bounded endpoints and t in [0, 1]")
    elif algorithm == "arc_length":
        if (not 0.0 <= start <= 1_000_000.0 or t not in (0.0, 1.0)
                or (t == 0.0 and not 0.0 <= end <= 360.0)
                or (t == 1.0 and not 0.0 <= end <= 2.0 * math.pi)):
            raise ValueError("arc_length requires a bounded radius, valid angle, and unit 0 or 1")
    elif algorithm == "bayes_theorem":
        valid = (0.0 <= start <= 1.0 and 0.0 <= end <= 1.0 and 0.0 <= t <= 1.0
                 and end > 0.0 and start * t <= end)
        if valid and (expected < 0.0 or expected > 1.0):
            raise ValueError("valid Bayes inputs must produce a posterior in [0, 1]")
        if not valid and expected != -1.0:
            raise ValueError("invalid Bayes inputs must use the -1 result sentinel")
        if valid and expected == -1.0:
            raise ValueError("valid Bayes inputs cannot use the invalid-input sentinel")
    elif algorithm == "affine_converter":
        if any(abs(value) > 1000.0 for value in (start, end, t)):
            raise ValueError("affine_converter operands must be finite and bounded by 1000")
        if expected != start * end + t:
            raise ValueError("affine_converter expected result must equal slope * x + intercept")
    elif algorithm == "brent_method_extrema":
        low, high = sorted((start, end))
        valid = (abs(start) <= 10.0 and abs(end) <= 10.0
                 and high - low > 1.4901161193847656e-8)
        target = None
        if valid and t == 0.0 and low < 2.0 < high:
            target = 2.0
        elif valid and t == 0.5 and 0.0 <= low and high <= 2.0 * math.pi and low < math.pi < high:
            target = math.pi
        elif valid and t == 1.0 and math.pi <= low and high <= 3.0 * math.pi and low < 2.0 * math.pi < high:
            target = 2.0 * math.pi
        if target is None:
            if expected != -1.0:
                raise ValueError("invalid Brent inputs must use the -1 result sentinel")
        elif abs(expected - target) > tolerance * max(1.0, abs(start), abs(end)):
            raise ValueError("valid Brent inputs must expect the bracketed extremum location")
    elif algorithm == "annuity_due_future_value":
        valid = (0.0 <= start <= 10000.0 and end.is_integer()
                 and 1.0 <= end <= 20.0 and 0.0 < t <= 0.5)
        if not valid:
            raise ValueError("annuity_due_future_value requires payment in [0, 10000], integral periods in [1, 20], and rate in (0, 0.5]")
    elif algorithm == "count_numbers_divisible":
        valid = (start.is_integer() and end.is_integer() and t.is_integer()
                 and 1.0 <= start <= end <= 2147483647.0
                 and 1.0 <= t <= 2147483647.0)
        if not valid:
            raise ValueError("count_numbers_divisible requires positive int32 endpoints with first <= last and a positive int32 divisor")
        expected_count = math.floor(end / t) - math.floor((start - 1.0) / t)
        if expected != expected_count:
            raise ValueError("count_numbers_divisible expected result must match the inclusive multiple count")
    elif algorithm == "sum_of_geometric_progression":
        valid = (abs(start) <= 1000.0 and -2.0 <= end <= 2.0
                 and (end == 1.0 or end <= 0.9 or end >= 1.1)
                 and t.is_integer() and 0.0 <= t <= 16.0)
        if not valid:
            raise ValueError("sum_of_geometric_progression requires first term in [-1000, 1000], ratio in [-2, 2] outside (0.9, 1.1) except 1, and integral terms in [0, 16]")
        expected_sum = (t * start if end == 1.0 else
                        (start / (1.0 - end)) * (1.0 - math.pow(end, int(t))))
        if abs(expected - expected_sum) > tolerance * max(1.0, abs(start), abs(end)):
            raise ValueError("sum_of_geometric_progression expected result must match the finite progression sum")
    elif algorithm == "sum_of_harmonic_series":
        valid = (0.0 < start <= 1000.0 and 0.0 <= end <= 1000.0
                 and t.is_integer() and 1.0 <= t <= 256.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid sum_of_harmonic_series inputs must use the -1e300 result sentinel")
        else:
            if expected == -1e300:
                raise ValueError("valid sum_of_harmonic_series inputs cannot use the invalid-input sentinel")
            arithmetic_term = 1.0 / start
            expected_sum = 0.0
            for index in range(int(t)):
                expected_sum += 1.0 / arithmetic_term
                if index + 1 < int(t):
                    arithmetic_term += end
            if abs(expected - expected_sum) > tolerance * max(1.0, abs(start), abs(end)):
                raise ValueError("sum_of_harmonic_series expected result must match the harmonic progression sum")
    elif algorithm == "equated_monthly_installments":
        valid = (0.0 < start <= 1_000_000.0 and 0.0001 <= end <= 0.2
                 and t.is_integer() and 1.0 <= t <= 30.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid equated_monthly_installments inputs must use the -1e300 sentinel")
        else:
            if expected == -1e300:
                raise ValueError("valid equated_monthly_installments inputs cannot use the invalid-input sentinel")
            monthly_rate = end / 12.0
            monthly_payments = int(t * 12.0)
            factor = math.pow(1.0 + monthly_rate, monthly_payments)
            expected_payment = (start * monthly_rate * factor) / (factor - 1.0)
            if abs(expected - expected_payment) > tolerance * max(1.0, abs(start), abs(end)):
                raise ValueError("equated_monthly_installments expected result must match the bounded EMI formula")
    elif algorithm == "pressure":
        factors = (1.0, 1000.0, 1_000_000.0, 100_000.0, 101_325.0, 6894.757293168)
        valid = (abs(start) <= 1_000_000.0 and end.is_integer() and t.is_integer()
                 and 0.0 <= end < len(factors) and 0.0 <= t < len(factors))
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid pressure inputs must use the -1.0 result sentinel")
        else:
            expected_pressure = start * factors[int(end)] / factors[int(t)]
            if abs(expected - expected_pressure) > tolerance * max(1.0, abs(start)):
                raise ValueError("pressure expected result must match the source-factor multiplication and division")
    elif algorithm == "order_of_magnitude_conversion":
        exponents = (0, 3, 6, 9, 12, 15, 18, 21, 24)
        valid = (abs(start) <= 1e100 and end.is_integer() and t.is_integer()
                 and 0.0 <= end < len(exponents) and 0.0 <= t < len(exponents))
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid order_of_magnitude_conversion inputs must use the -1.0 result sentinel")
        else:
            factor = math.pow(10.0, exponents[int(end)] - exponents[int(t)])
            expected_value = start * factor
            if abs(expected - expected_value) > tolerance * max(1.0, abs(start)):
                raise ValueError("order_of_magnitude_conversion expected result must match the bounded power-of-ten formula")
    elif algorithm == "pressure_conversions":
        factors = ((1.0, 1.0), (0.0000098, 101325.0), (0.986923, 1.01325),
                   (0.00986923, 101.325), (9.86923, 0.101325),
                   (0.068046, 14.6959), (0.0334211, 29.9213),
                   (0.00131579, 760.0))
        valid = (abs(start) <= 1_000_000.0 and end.is_integer() and t.is_integer()
                 and 0.0 <= end < len(factors) and 0.0 <= t < len(factors))
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid pressure_conversions inputs must use the -1.0 result sentinel")
        else:
            source_factor = factors[int(end)][0]
            target_factor = factors[int(t)][1]
            expected_pressure = (start * source_factor) * target_factor
            if abs(expected - expected_pressure) > tolerance * max(1.0, abs(start)):
                raise ValueError("pressure_conversions expected result must match the source's ordered factor products")
    elif algorithm == "addition_rule":
        valid = all(0.0 <= value <= 1.0 for value in (start, end, t))
        if not valid:
            raise ValueError("addition_rule inputs must be finite probabilities in [0, 1]")
        expected_probability = (start + end) - (start * t)
        if abs(expected - expected_probability) > tolerance:
            raise ValueError("addition_rule expected result must match P(A) + P(B) - P(A) * P(B|A)")
    elif algorithm == "electric_power":
        valid = (start.is_integer() and end.is_integer() and t.is_integer()
                 and -10000.0 <= start <= 10000.0
                 and -10000.0 <= end <= 10000.0
                 and 0.0 <= t <= 100000000.0
                 and sum(value == 0.0 for value in (start, end, t)) == 1)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid electric_power inputs must use the -1e300 result sentinel")
        else:
            expected_value = (t / end if start == 0.0 else
                              t / start if end == 0.0 else
                              abs(start * end))
            if abs(expected - expected_value) > tolerance * max(1.0, abs(start), abs(end)):
                raise ValueError("electric_power expected result must match the source branch formula")
    elif algorithm == "cartesian_to_polar":
        valid = (abs(start) <= 1_000_000.0 and abs(end) <= 1_000_000.0
                 and t in (0.0, 1.0))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid cartesian_to_polar inputs must use the -1e300 result sentinel")
        else:
            if expected == -1e300:
                raise ValueError("valid cartesian_to_polar inputs cannot use the invalid-input sentinel")
            expected_component = (math.sqrt(start * start + end * end) if t == 0.0
                                  else math.atan2(end, start))
            if abs(expected - expected_component) > tolerance * max(1.0, abs(start), abs(end)):
                raise ValueError("cartesian_to_polar expected result must match its selected component")
    elif algorithm == "ohms_law":
        valid = (start.is_integer() and end.is_integer() and t.is_integer()
                 and -1000.0 <= start <= 1000.0 and -1000.0 <= end <= 1000.0
                 and 0.0 <= t <= 1000.0
                 and sum(value == 0.0 for value in (start, end, t)) == 1)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid ohms_law inputs must use the -1e300 result sentinel")
        else:
            expected_value = (end * t if start == 0.0 else
                              start / t if end == 0.0 else
                              start / end)
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end), abs(t)):
                raise ValueError("ohms_law expected result must match the selected V/I/R source formula")
    elif algorithm == "first_law_of_thermodynamics":
        valid = (start.is_integer() and end.is_integer() and t.is_integer()
                 and -1_000_000.0 <= start <= 1_000_000.0
                 and -1_000_000.0 <= end <= 1_000_000.0
                 and t in (0.0, 1.0, 2.0))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid first_law_of_thermodynamics inputs must use -1e300")
        else:
            expected_value = (start - end if t == 0.0 else
                              start + end if t == 1.0 else
                              start - end)
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("first_law_of_thermodynamics expected result must match its selected source formula")
    elif algorithm == "length_conversion":
        factors = (0.001, 0.01, 1.0, 1000.0)
        valid = (-1_000_000.0 <= start <= 1_000_000.0
                 and end in (0.0, 1.0, 2.0, 3.0)
                 and t in (0.0, 1.0, 2.0, 3.0))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid length_conversion inputs must use the -1e300 result sentinel")
        else:
            expected_value = (start * factors[int(end)]) / factors[int(t)]
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("length_conversion expected result must match the selected metric-unit conversion")
    else:
        raise ValueError(f"unsupported float64_triple algorithm: {algorithm}")
    if not math.isfinite(tolerance) or tolerance <= 0.0:
        raise ValueError("relative tolerance must be positive and finite")
    return start, end, t, float(expected)


def matches(observed: float, expected: float, tolerance: float, start: float, end: float) -> bool:
    scale = max(1.0, abs(start), abs(end))
    return math.isfinite(observed) and abs(observed - expected) <= tolerance * scale


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
    if manifest.get("family") != "float64_triple" or algorithm not in SUPPORTED_ALGORITHMS:
        parser.error("build manifest must declare a supported float64_triple ABI")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["float64_triple_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/float64_triple_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0]
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "float64_triple_call"):
        parser.error("workload does not match the built float64 triple algorithm")
    timing = workload["measurement"]
    tolerance = float(timing["input_scaled_tolerance"])
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
        start, end, t, expected = encode_case(case, tolerance, algorithm)
        command = [str(executable), *(format(value, ".17g") for value in (start, end, t, expected, tolerance)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64 triple runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        if not matches(observed, expected, tolerance, start, end) or len(raw["samples_ns"]) != samples:
            raise ValueError(f"float64 triple runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [start, end, t],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "float64_triple_call",
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
