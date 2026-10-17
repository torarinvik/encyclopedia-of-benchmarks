#!/usr/bin/env python3
"""Check float64 slice-to-slice ports against their independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import math
from pathlib import Path
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_slice_io import (MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH, ORACLES,
                                  _format_output, _output_token, encode_case, tolerances,
                                  validate_joint_probability_distribution_workload,
                                  validate_pid_workload,
                                  validate_shreedharacharya_workload,
                                  validate_rotation_matrix_workload,
                                  validate_simple_pendulum_rk4_workload,
                                  validate_piecewise_without_inbuilt_workload,
                                  validate_koch_snowflake_workload,
                                  validate_k_d_tree_workload,
                                  validate_linear_regression_vectorized_workload,
                                  validate_perlin_noise_workload,
                                  validate_single_point_crossover_workload,
                                  validate_quaternions_workload,
                                  _decode_k_d_tree_abi_values,
                                  _decode_single_point_crossover_abi_values)
from shreedharacharya_oracle import MAX_COEFFICIENT as SHREEDHARACHARYA_MAX_COEFFICIENT
from shreedharacharya_oracle import MIN_ABS_LEADING_COEFFICIENT as SHREEDHARACHARYA_MIN_ABS_A
from linear_regression_vectorized_oracle import MAX_ALPHA as LINEAR_REGRESSION_MAX_ALPHA
from linear_regression_vectorized_oracle import MAX_FEATURE_COUNT as LINEAR_REGRESSION_MAX_FEATURE_COUNT
from linear_regression_vectorized_oracle import MAX_FEATURE_OR_LABEL as LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL
from linear_regression_vectorized_oracle import MAX_ITERATIONS as LINEAR_REGRESSION_MAX_ITERATIONS
from linear_regression_vectorized_oracle import MAX_SAMPLE_COUNT as LINEAR_REGRESSION_MAX_SAMPLE_COUNT
from linear_regression_vectorized_oracle import MIN_ALPHA as LINEAR_REGRESSION_MIN_ALPHA
from linear_regression_vectorized_oracle import MIN_FEATURE_COUNT as LINEAR_REGRESSION_MIN_FEATURE_COUNT
from linear_regression_vectorized_oracle import MIN_FEATURE_OR_LABEL as LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL
from linear_regression_vectorized_oracle import MIN_ITERATIONS as LINEAR_REGRESSION_MIN_ITERATIONS
from linear_regression_vectorized_oracle import MIN_SAMPLE_COUNT as LINEAR_REGRESSION_MIN_SAMPLE_COUNT
from perlin_noise_oracle import INVALID_RESULT as PERLIN_NOISE_INVALID_RESULT
from perlin_noise_oracle import MAX_DIMENSION as PERLIN_NOISE_MAX_DIMENSION
from perlin_noise_oracle import MAX_OCTAVES as PERLIN_NOISE_MAX_OCTAVES
from perlin_noise_oracle import MAX_OUTPUT_ELEMENTS as PERLIN_NOISE_MAX_OUTPUT_ELEMENTS
from perlin_noise_oracle import MAX_SEED as PERLIN_NOISE_MAX_SEED
from perlin_noise_oracle import MIN_DIMENSION as PERLIN_NOISE_MIN_DIMENSION
from perlin_noise_oracle import MIN_OCTAVES as PERLIN_NOISE_MIN_OCTAVES
from perlin_noise_oracle import MIN_SEED as PERLIN_NOISE_MIN_SEED
from perlin_noise_oracle import OUTPUT_ERROR as PERLIN_NOISE_OUTPUT_ERROR
from perlin_noise_oracle import PERSISTENCE_VALUES as PERLIN_NOISE_PERSISTENCE_VALUES
from perlin_noise_oracle import expected_result as perlin_noise_oracle
from single_point_crossover_oracle import expected_abi_result as single_point_crossover_expected_abi_result
from quaternions_oracle import expected_abi_result as quaternions_expected_abi_result

ALGORITHMS = tuple(ORACLES)


def checker_records(algorithm: str, workload: dict) -> tuple[str, int]:
    absolute_tolerance, relative_tolerance = tolerances(workload)
    workspace = workload.get("workspace", {}).get("elements")
    if type(workspace) is not int or not 1 <= workspace <= 64:
        raise ValueError("workspace.elements must be an integer from 1 through 64")
    records: list[tuple[list[float], int, list[float | str], int, int, int]] = []
    valid_case: tuple[list[float], int, list[float | str]] | None = None
    for case in workload.get("cases", []):
        values, expected_result, expected_output = encode_case(
            case, algorithm, absolute_tolerance, relative_tolerance)
        if expected_result >= 0 and expected_result > workspace:
            raise ValueError(f"workspace is too small for {case.get('id')}")
        records.append((values, expected_result, expected_output, workspace, 0, 0))
        if expected_result > 0 and valid_case is None:
            valid_case = (values, expected_result, expected_output)

    if not records:
        raise ValueError("workload requires at least one case")
    if valid_case is None:
        raise ValueError("workload requires a successful output case for ABI boundary checks")
    values, result_count, _ = valid_case
    records.append((values, -2, [], result_count - 1, 0, 0))
    records.append((values, -2, [], workspace, 0, 1))
    for invalid_length in (4, 6):
        invalid_input = [0.0] * invalid_length
        oracle_result = ORACLES[algorithm](invalid_input)
        invalid = (oracle_result[0] < 0
                   if algorithm in {"joint_probability_distribution", "shreedharacharya", "rotation_matrix"}
                   else oracle_result is None)
        if invalid:
            records.append((invalid_input, -1, [], workspace, 0, 0))
    records.append((values, -1, [], workspace, 1, 0))
    if algorithm != "md2_digest":
        records.append(([], -1, [], workspace, 0, 0))

    if algorithm == "k_d_tree":
        for case in workload.get("abi_cases", []):
            inputs = _decode_k_d_tree_abi_values(case.get("input_values"))
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            oracle_output = ORACLES[algorithm](inputs)
            if oracle_output is None:
                expected_result, expected_output = -1, []
            elif output_is_null or len(oracle_output) > capacity:
                expected_result, expected_output = -2, []
            else:
                expected_result = len(oracle_output)
                expected_output = [_output_token(value) for value in oracle_output]
            if case.get("expected_result") != expected_result:
                raise ValueError(f"k_d_tree ABI probe mismatch: {case.get('id')}")
            records.append((inputs, expected_result, expected_output, capacity, 0,
                            int(output_is_null)))

    if algorithm == "single_point_crossover":
        for case in workload.get("abi_cases", []):
            inputs = _decode_single_point_crossover_abi_values(case.get("input_values"))
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            expected_result, output = single_point_crossover_expected_abi_result(
                inputs, capacity, output_is_null)
            if case.get("expected_result") != expected_result:
                raise ValueError(f"single_point_crossover ABI probe mismatch: {case.get('id')}")
            expected_output = [_output_token(value) for value in output]
            records.append((inputs, expected_result, expected_output, capacity, 0,
                            int(output_is_null)))

    if algorithm == "quaternions":
        oracle = ORACLES[algorithm]

        def add_quaternion_case(inputs: list[float], capacity: int = workspace,
                                output_is_null: bool = False, input_is_null: bool = False,
                                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            result, output = quaternions_expected_abi_result(
                inputs, capacity, output_is_null, input_is_null, input_length)
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        absolute_tolerance, relative_tolerance = tolerances(workload)
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid quaternions ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            result, output = quaternions_expected_abi_result(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected, list)
                    or len(expected) != len(output)
                    or any(type(actual) not in (int, float)
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected, output))):
                raise ValueError(f"quaternions ABI workload mismatch: {case.get('id')}")
            records.append((inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))

        rng_quaternions = random.Random(20261017)
        for index in range(64):
            euler_values = [0.0,
                            rng_quaternions.uniform(-3.0, 3.0),
                            rng_quaternions.uniform(-3.0, 3.0),
                            rng_quaternions.uniform(-3.0, 3.0)]
            quaternion_components = [rng_quaternions.uniform(-1.0, 1.0)
                                     for _ in range(4)]
            norm = math.sqrt(sum(value * value for value in quaternion_components))
            if norm == 0.0:
                quaternion_components = [0.5, 0.5, 0.5, 0.5]
            else:
                quaternion_components = [value / norm for value in quaternion_components]
            euler_conversion = [1.0, *quaternion_components]
            if oracle(euler_conversion) is None:
                euler_conversion = [1.0, 0.5, 0.5, 0.5, 0.5]
            hamilton_product = [2.0, *(rng_quaternions.uniform(-1.0, 1.0)
                                       for _ in range(8))]
            for inputs in (euler_values, euler_conversion, hamilton_product):
                result, output = add_quaternion_case(inputs)
                if result > 0:
                    add_quaternion_case(inputs, capacity=result - 1)
                    if index % 16 == 0:
                        add_quaternion_case(inputs, output_is_null=True)

        malformed = (
            [0.0], [0.0, 0.0, 0.0], [1.0, 1.0, 0.0, 0.0],
            [1.0, 1.0, 0.0, 0.0, 0.0, 0.0],
            [2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            [2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            [3.0, 0.0, 0.0, 0.0], [0.5, 0.0, 0.0, 0.0],
            [0.0, 3.000001, 0.0, 0.0],
            [0.0, math.nan, 0.0, 0.0], [0.0, math.inf, 0.0, 0.0],
        )
        for inputs in malformed:
            add_quaternion_case(inputs)
        add_quaternion_case([0.0, 3.5, 0.0, 0.0], capacity=0, output_is_null=True)
        add_quaternion_case([0.0, 0.0, 0.0, 0.0], input_is_null=True, input_length=4)

    if algorithm == "median_filter":
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if not isinstance(raw_values, list):
                raise ValueError(f"median_filter ABI input must be a list: {case.get('id')}")
            values: list[float] = []
            for value in raw_values:
                if value == "NaN":
                    values.append(math.nan)
                elif value == "Infinity":
                    values.append(math.inf)
                elif value == "-Infinity":
                    values.append(-math.inf)
                elif type(value) in (int, float):
                    values.append(float(value))
                else:
                    raise ValueError(f"unsupported median_filter ABI token in {case.get('id')}")
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool):
                raise ValueError(f"invalid median_filter ABI capacity/null flag: {case.get('id')}")
            expected = ORACLES[algorithm](values)
            if expected is None:
                result, encoded = -1, []
            elif output_is_null or len(expected) > capacity:
                result, encoded = -2, []
            else:
                result = len(expected)
                encoded = [_output_token(value) for value in expected]
            if case.get("expected_result") != result:
                raise ValueError(f"median_filter ABI probe mismatch: {case.get('id')}")
            records.append((values, result, encoded, capacity, 0,
                            int(output_is_null)))

    if algorithm == "mutate":
        nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf,
                            "-Infinity": -math.inf}
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if not isinstance(raw_values, list):
                raise ValueError(f"mutate ABI input must be a list: {case.get('id')}")
            values: list[float] = []
            for value in raw_values:
                if isinstance(value, str):
                    if value not in nonfinite_tokens:
                        raise ValueError(f"unsupported mutate ABI token in {case.get('id')}")
                    values.append(nonfinite_tokens[value])
                elif type(value) in (int, float):
                    values.append(float(value))
                else:
                    raise ValueError(f"unsupported mutate ABI input in {case.get('id')}")
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool):
                raise ValueError(f"invalid mutate ABI capacity/null flag: {case.get('id')}")
            expected = ORACLES[algorithm](values)
            if expected is None:
                result, encoded = -1, []
            elif output_is_null or len(expected) > capacity:
                result, encoded = -2, []
            else:
                result = len(expected)
                encoded = [_output_token(value) for value in expected]
            if case.get("expected_result") != result:
                raise ValueError(f"mutate ABI probe mismatch: {case.get('id')}")
            records.append((values, result, encoded, capacity, 0,
                            int(output_is_null)))

    if algorithm == "koch_snowflake":
        invalid_input = [0.0, 1.0]
        if ORACLES[algorithm](invalid_input) is not None:
            raise ValueError("koch_snowflake must reject a point count below its minimum")
        records.append((invalid_input, -1, [], workspace, 0, 1))

    if algorithm == "rayleigh_quotient":
        oracle = ORACLES[algorithm]

        def add_rayleigh_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        rng = random.Random(20261016)
        for _ in range(128):
            dimension = rng.randint(1, 16)
            matrix = [0.0] * (dimension * dimension)
            for row in range(dimension):
                for col in range(row, dimension):
                    value = rng.uniform(-1000.0, 1000.0)
                    matrix[row * dimension + col] = value
                    matrix[col * dimension + row] = value
            vector = [rng.uniform(-100.0, 100.0) for _ in range(dimension)]
            if all(value == 0.0 for value in vector):
                vector[0] = 1.0
            inputs = [float(dimension), *matrix, *vector]
            if len(inputs) > MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH:
                raise ValueError("rayleigh_quotient generated input exceeds its reviewed bound")
            add_rayleigh_case(inputs)

        boundary_matrix = [1000.0, -1000.0, -1000.0, -1000.0]
        add_rayleigh_case([2.0, *boundary_matrix, -100.0, 100.0])
        invalid_cases = (
            [0.0], [17.0], [1.5], [1.0, 1.0], [1.0, 1.0, 1.0, 0.0],
            [2.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0],
            [1.0, -1000.000001, 1.0], [1.0, 1000.000001, 1.0],
            [1.0, 1.0, -100.000001], [1.0, 1.0, 100.000001],
            [1.0, 1.0, 0.0], [1.0, math.nan, 1.0],
            [1.0, math.inf, 1.0], [1.0, 1.0, math.inf],
        )
        for inputs in invalid_cases:
            if oracle(inputs) is not None:
                raise ValueError("rayleigh_quotient oracle accepted a malformed probe")
            add_rayleigh_case(inputs)
    elif algorithm == "fresnel_diffract":
        oracle = ORACLES[algorithm]

        def add_fresnel_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # The fixed physical prefix is part of this bounded ABI contract.
        for index, replacement in ((0, 3.0), (1, 0.0), (2, 2.0), (3, 15.0)):
            invalid_parameters = list(values)
            invalid_parameters[index] = replacement
            add_fresnel_case(invalid_parameters)

        # Exercise both accepted range endpoints and just-outside values.
        boundary_values = list(values)
        boundary_values[4], boundary_values[8] = 100.0, -100.0
        add_fresnel_case(boundary_values)
        for index, replacement in ((4, 100.000001), (5, -100.000001),
                                   (8, 100.000001), (11, -100.000001)):
            out_of_range = list(values)
            out_of_range[index] = replacement
            add_fresnel_case(out_of_range)

        for special in (math.nan, math.inf, -math.inf):
            nonfinite = list(values)
            nonfinite[4] = special
            add_fresnel_case(nonfinite)

        add_fresnel_case(values[:-1])
        add_fresnel_case([*values, 0.0])
    elif algorithm == "softmax":
        oracle = ORACLES[algorithm]
        for invalid_logit in (20.000001, -20.000001, math.nan, math.inf, -math.inf):
            invalid_input = [invalid_logit]
            if oracle(invalid_input) is not None:
                raise ValueError("softmax oracle must reject out-of-range and non-finite logits")
            records.append((invalid_input, -1, [], workspace, 0, 0))
    elif algorithm == "trig_functions":
        oracle = ORACLES[algorithm]

        def add_trig_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Valid non-finite x is deliberately represented by one NaN output.
        for special_x in (math.nan, math.inf, -math.inf):
            add_trig_case([0.0, special_x, 1e-9])

        # Cover the accepted finite x endpoints and the immediately out-of-range values.
        for boundary_x in (-10_000.0, 10_000.0):
            add_trig_case([0.0, boundary_x, 1e-9])
        for invalid_x in (-10_000.000001, 10_000.000001):
            add_trig_case([0.0, invalid_x, 1e-9])

        for invalid_selector in (-1.0, 8.0, 1.5, math.nan, math.inf):
            add_trig_case([invalid_selector, 0.0, 1e-9])
        for invalid_tolerance in (0.0, 0.999e-9, 0.010000001, math.nan, math.inf):
            add_trig_case([0.0, 0.0, invalid_tolerance])

        # This operation requires exactly three input values.
        add_trig_case([0.0, 0.0])
    elif algorithm == "verlet":
        oracle = ORACLES[algorithm]

        def add_verlet_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Every input slot must be finite, even when all other fields are valid.
        valid_input = [2.0, 0.25, -0.5, 2.0]
        for index in range(4):
            for special in (math.nan, math.inf, -math.inf):
                invalid_input = list(valid_input)
                invalid_input[index] = special
                add_verlet_case(invalid_input)

        for invalid_input in (
            [1.5, 0.0, 0.0, 0.0], [1.0, 0.0, 0.0, 0.0],
            [32.5, 0.0, 0.0, 0.0], [2.0, -1.000001, 0.0, 0.0],
            [2.0, 1.000001, 0.0, 0.0], [2.0, 0.0, -1.000001, 0.0],
            [2.0, 0.0, 1.000001, 0.0], [2.0, 0.0, 0.0, -1.0],
            [2.0, 0.0, 0.0, 5.0], [2.0, 0.0, 0.0, 1.5],
            [2.0, 0.0, 0.0],
        ):
            add_verlet_case(invalid_input)
    elif algorithm == "vector2":
        oracle = ORACLES[algorithm]

        def add_vector2_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Every ABI slot is numeric and finite, including operation selectors and
        # fields that are otherwise unused by a selected operation.
        valid_add = [4.0, 1.25, -2.5, 3.5, 4.25, 0.0]
        for index in range(6):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_add)
                nonfinite[index] = special
                add_vector2_case(nonfinite)

        for invalid_selector in (-1.0, 11.0, 2.5, math.nan, math.inf):
            add_vector2_case([invalid_selector, 0.0, 0.0, 0.0, 0.0, 0.0])

        # Coordinates have a closed [-1000, 1000] domain. Probe each field
        # outside it and include the accepted endpoints on an active operation.
        for index in range(1, 5):
            for invalid_coordinate in (-1000.000001, 1000.000001):
                invalid = list(valid_add)
                invalid[index] = invalid_coordinate
                add_vector2_case(invalid)
        add_vector2_case([4.0, -1000.0, 1000.0, 1000.0, -1000.0, 0.0])

        # Approximate equality uses epsilon in [0, 2000], including both ends.
        for epsilon in (0.0, 2000.0):
            add_vector2_case([1.0, 0.0, 0.0, 1.0, -1.0, epsilon])
        for invalid_epsilon in (-0.000001, 2000.000001):
            add_vector2_case([1.0, 0.0, 0.0, 1.0, -1.0, invalid_epsilon])

        # Multiplication and rotation are the only operations that consume the
        # final field. Their endpoints are valid; just-outside values are not.
        for factor in (-1000.0, 1000.0):
            add_vector2_case([6.0, 1.0, -1.0, 0.0, 0.0, factor])
        for invalid_factor in (-1000.000001, 1000.000001):
            add_vector2_case([6.0, 1.0, -1.0, 0.0, 0.0, invalid_factor])
        angle_limit = 2.0 * math.pi
        for angle in (-angle_limit, angle_limit):
            add_vector2_case([9.0, 1.0, 0.0, 0.0, 0.0, angle])
        for invalid_angle in (-angle_limit - 0.000001, angle_limit + 0.000001):
            add_vector2_case([9.0, 1.0, 0.0, 0.0, 0.0, invalid_angle])

        # Each operation has an unambiguous encoding: unused coordinates and
        # scalar slots must be zero. Cover each distinct validation rule.
        for malformed_unused in (
            [0.0, 1.0, 2.0, 1.0, 2.0, 1.0],
            [2.0, 3.0, 4.0, 1.0, 0.0, 0.0],
            [2.0, 3.0, 4.0, 0.0, 1.0, 0.0],
            [2.0, 3.0, 4.0, 0.0, 0.0, 1.0],
            [3.0, 3.0, 4.0, 1.0, 0.0, 0.0],
            [3.0, 3.0, 4.0, 0.0, 1.0, 0.0],
            [3.0, 3.0, 4.0, 0.0, 0.0, 1.0],
            [4.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [5.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [6.0, 1.0, 2.0, 1.0, 0.0, 2.0],
            [6.0, 1.0, 2.0, 0.0, 1.0, 2.0],
            [7.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [8.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [9.0, 1.0, 2.0, 1.0, 0.0, 0.5],
            [9.0, 1.0, 2.0, 0.0, 1.0, 0.5],
            [10.0, 1.0, 2.0, 3.0, 4.0, 1.0],
        ):
            add_vector2_case(malformed_unused)

        # The source rejects normalization when computed length is zero,
        # including a nonzero vector whose squared components underflow.
        add_vector2_case([3.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        add_vector2_case([3.0, 1e-200, 0.0, 0.0, 0.0, 0.0])

        # The operation tuple must contain exactly six values.
        add_vector2_case([4.0, 1.0, 2.0, 3.0, 4.0])
        add_vector2_case([4.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0])

        # The shared capacity probe uses a scalar-returning first workload
        # case, so separately reject capacity one for a valid vector result.
        records.append((valid_add, -2, [], 1, 0, 0))
    elif algorithm == "projectile_motion":
        oracle = ORACLES[algorithm]

        def add_projectile_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        valid_input = [250.0, 37.0, 12.5, 9.80665]
        # Every parameter must be finite before the trajectory formulas run.
        for index in range(4):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_input)
                nonfinite[index] = special
                add_projectile_case(nonfinite)
    elif algorithm == "momentum":
        oracle = ORACLES[algorithm]

        def add_momentum_invalid_case(inputs: list[float]) -> None:
            if oracle(inputs) is not None:
                raise ValueError("momentum oracle accepted an invalid ABI probe")
            # Keep malformed values out of the JSON workload/recorder path:
            # encode_case intentionally accepts only finite inputs. The C ABI
            # checker can parse these values and verify rejection/no-write.
            records.append((inputs, -1, [], workspace, 0, 0))

        add_momentum_invalid_case([0.0] * 65)
        add_momentum_invalid_case([1_000_000.000001])
        add_momentum_invalid_case([-1_000_000.000001])
        for special in (math.nan, math.inf, -math.inf):
            add_momentum_invalid_case([special])
    elif algorithm == "pid":
        oracle = ORACLES[algorithm]

        def add_pid_invalid_case(inputs: list[float], output_is_null: bool = False) -> None:
            if oracle(inputs) is not None:
                raise ValueError("pid oracle accepted an invalid ABI probe")
            records.append((inputs, -1, [], workspace, 0, int(output_is_null)))

        # The active float64-slice ABI accepts at most 64 input values.
        add_pid_invalid_case([0.0, 0.0, 0.0, 0.5, *([0.0] * 61)])
        # A malformed finite input must be rejected before a null output pointer.
        add_pid_invalid_case([1.00000001, 0.0, 0.0, 0.5, 0.0], output_is_null=True)

        # Probe every parameter class and an error sample with non-finite values.
        valid_input = [0.0, 0.0, 0.0, 0.5, 0.0]
        for index in range(len(valid_input)):
            for special in (math.nan, math.inf, -math.inf):
                invalid_input = list(valid_input)
                invalid_input[index] = special
                add_pid_invalid_case(invalid_input)
    elif algorithm == "joint_probability_distribution":
        oracle = ORACLES[algorithm]

        def add_joint_probability_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_result, expected_output = oracle(inputs)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result, expected_output,
                            workspace, 0, int(output_is_null)))

        rng = random.Random(20261017)
        for _ in range(64):
            nx, ny = rng.randint(1, 4), rng.randint(1, 4)
            x_values = rng.sample(range(-1000, 1001), nx)
            y_values = rng.sample(range(-1000, 1001), ny)
            x_probabilities = [rng.uniform(-1_000_000.0, 1_000_000.0) for _ in range(nx)]
            y_probabilities = [rng.uniform(-1_000_000.0, 1_000_000.0) for _ in range(ny)]
            inputs = [float(nx), float(ny), *map(float, x_values), *map(float, y_values),
                      *x_probabilities, *y_probabilities]
            add_joint_probability_case(inputs)

        invalid_inputs = (
            [1.0, 1.0, 1.0, 2.0, 0.5],
            [1.0, 1.0, 1.0, 2.0, 0.5, 0.5, 99.0],
            [1.0, 1.0, 1.5, 2.0, 0.5, 0.5],
            [2.0, 1.0, 1.0, 1.0, 2.0, 0.25, 0.75, 0.5],
            [1.0, 1.0, 1.0, 2.0, 1_000_000.1, 0.5],
            [1.0, 1.0, 1.0, 2.0, math.nan, 0.5],
            [1.0, 1.0, 1.0, 2.0, math.inf, 0.5],
        )
        for inputs in invalid_inputs:
            if oracle(inputs)[0] != -1:
                raise ValueError("joint_probability_distribution oracle accepted a malformed probe")
            add_joint_probability_case(inputs)

        maximum_case = next(case for case in workload["cases"]
                            if case.get("id") == "maximum_support_sizes")
        maximum_values, _, _ = encode_case(
            maximum_case, algorithm, absolute_tolerance, relative_tolerance)
        parseable_limit_input = [*maximum_values, 0.0, 0.0]
        if len(parseable_limit_input) != 20 or oracle(parseable_limit_input)[0] != -1:
            raise ValueError("joint_probability_distribution parseable-limit probe is malformed")
        add_joint_probability_case(parseable_limit_input)

        invalid_before_null_output = [1.0, 1.0, 1.5, 2.0, 0.5, 0.5]
        if oracle(invalid_before_null_output)[0] != -1:
            raise ValueError("joint_probability_distribution oracle accepted an invalid null-output probe")
        add_joint_probability_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "shreedharacharya":
        oracle = ORACLES[algorithm]

        def add_shreedharacharya_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_result, expected_output = oracle(inputs)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result, expected_output,
                            workspace, 0, int(output_is_null)))

        finite_probes = (
            [SHREEDHARACHARYA_MIN_ABS_A, -2e-6, 1e-6],
            [-SHREEDHARACHARYA_MIN_ABS_A, 2e-6, -1e-6],
            [SHREEDHARACHARYA_MAX_COEFFICIENT, 0.0, 0.0],
            [-SHREEDHARACHARYA_MAX_COEFFICIENT, 0.0, 0.0],
            [1.0, 0.0, 1.0],
            [1.0, 2.0, 1.0],
            [0.0, 0.0, 1.0],
            [SHREEDHARACHARYA_MIN_ABS_A * 0.999, 0.0, 0.0],
            [SHREEDHARACHARYA_MAX_COEFFICIENT + 1.0, 0.0, 0.0],
            [1.0, SHREEDHARACHARYA_MAX_COEFFICIENT + 1.0, 0.0],
            [1.0, 0.0, SHREEDHARACHARYA_MAX_COEFFICIENT + 1.0],
        )
        for inputs in finite_probes:
            add_shreedharacharya_case(inputs)

        parseable_limit_input = [1.0, 2.0, 1.0, *([0.0] * 61)]
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input)[0] != -1:
            raise ValueError("shreedharacharya parseable-limit probe is malformed")
        add_shreedharacharya_case(parseable_limit_input)

        rng = random.Random(20261017)
        for _ in range(64):
            magnitude = 10.0 ** rng.uniform(-6.0, 6.0)
            a = magnitude if rng.randrange(2) else -magnitude
            b = rng.uniform(-SHREEDHARACHARYA_MAX_COEFFICIENT,
                            SHREEDHARACHARYA_MAX_COEFFICIENT)
            c = rng.uniform(-SHREEDHARACHARYA_MAX_COEFFICIENT,
                            SHREEDHARACHARYA_MAX_COEFFICIENT)
            add_shreedharacharya_case([a, b, c])

        for index in range(3):
            for special in (math.nan, math.inf, -math.inf):
                inputs = [1.0, 2.0, 1.0]
                inputs[index] = special
                if oracle(inputs)[0] != -1:
                    raise ValueError("shreedharacharya oracle accepted a non-finite coefficient")
                add_shreedharacharya_case(inputs)

        zero_root_input = [1.0, 0.0, 1.0]
        if oracle(zero_root_input) != (0, []):
            raise ValueError("shreedharacharya oracle must preserve the empty-root result")
        records.append((zero_root_input, 0, [], 0, 0, 0))
        add_shreedharacharya_case(zero_root_input, output_is_null=True)

        invalid_before_null_output = [0.0, 0.0, 1.0]
        if oracle(invalid_before_null_output)[0] != -1:
            raise ValueError("shreedharacharya oracle accepted the invalid null-output probe")
        add_shreedharacharya_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "rotation_matrix":
        oracle = ORACLES[algorithm]

        def add_rotation_matrix_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_result, expected_output = oracle(inputs)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result, expected_output,
                            workspace, 0, int(output_is_null)))

        rng = random.Random(20261017)
        for _ in range(128):
            add_rotation_matrix_case([rng.uniform(-1000.0, 1000.0)])

        for angle in (0.0, -0.0, -1000.0, 1000.0, -999.999999, 999.999999,
                      -1000.000001, 1000.000001):
            add_rotation_matrix_case([angle])
        for special in (math.nan, math.inf, -math.inf):
            add_rotation_matrix_case([special])

        parseable_limit_input = [0.0] * 64
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input)[0] != -1:
            raise ValueError("rotation_matrix parseable-limit probe is malformed")
        add_rotation_matrix_case(parseable_limit_input)

        invalid_before_null_output = [1000.000001]
        if oracle(invalid_before_null_output)[0] != -1:
            raise ValueError("rotation_matrix oracle accepted invalid input before null output")
        add_rotation_matrix_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "simple_pendulum_rk4":
        oracle = ORACLES[algorithm]

        def add_simple_pendulum_case(inputs: list[float], output_is_null: bool = False) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            if output_is_null and expected_result >= 0:
                expected_result, expected_output = -2, []
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, int(output_is_null)))

        rng_pendulum = random.Random(20261017)
        for _ in range(128):
            inputs = [
                float(rng_pendulum.randint(10_000, 100_000_000)),
                float(rng_pendulum.randint(100_000, 20_000_000)),
                float(rng_pendulum.randint(-3_141_593, 3_141_593)),
                float(rng_pendulum.randint(-100_000_000, 100_000_000)),
                float(rng_pendulum.randint(1, 100_000)),
            ]
            add_simple_pendulum_case(inputs)

        valid_input = [1_000_000.0, 9_800_000.0, 523_599.0, -1_250_000.0, 20_000.0]
        if oracle(valid_input) is None:
            raise ValueError("simple_pendulum_rk4 oracle rejected a valid capacity probe")
        for capacity in (0, 1, 2):
            result = -2 if capacity < 2 else 2
            output = [] if capacity < 2 else oracle(valid_input)
            records.append((valid_input, result, output, capacity, 0, 0))
        add_simple_pendulum_case(valid_input, output_is_null=True)

        for index in range(5):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(valid_input)
                inputs[index] = special
                if oracle(inputs) is not None:
                    raise ValueError("simple_pendulum_rk4 oracle accepted a non-finite input")
                add_simple_pendulum_case(inputs)

        fractional_micro_input = list(valid_input)
        fractional_micro_input[2] = 523_599.5
        if oracle(fractional_micro_input) is not None:
            raise ValueError("simple_pendulum_rk4 oracle accepted a fractional micro-unit")
        add_simple_pendulum_case(fractional_micro_input)

        parseable_limit_input = [*valid_input, *([0.0] * 59)]
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input) is not None:
            raise ValueError("simple_pendulum_rk4 parseable-limit probe is malformed")
        add_simple_pendulum_case(parseable_limit_input)

        invalid_before_null_output = [9_999.0, *valid_input[1:]]
        if len(invalid_before_null_output) != 5 or oracle(invalid_before_null_output) is not None:
            raise ValueError("simple_pendulum_rk4 null-output precedence probe is malformed")
        add_simple_pendulum_case(invalid_before_null_output, output_is_null=True)
    elif algorithm == "piecewise_without_inbuilt":
        oracle = ORACLES[algorithm]

        def add_piecewise_case(inputs: list[float], capacity: int = workspace,
                               output_is_null: bool = False) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            output = [] if expected_output is None else expected_output
            if expected_result >= 0 and output_is_null:
                expected_result, output = -2, []
            elif expected_result >= 0 and capacity < expected_result:
                expected_result, output = -2, []
            records.append((inputs, expected_result, output, capacity, 0,
                            int(output_is_null)))

        rng_piecewise = random.Random(20261019)
        for _ in range(128):
            add_piecewise_case([rng_piecewise.uniform(-10.0, 10.0)])

        for value in (-10.0, -0.500001, -0.5, -0.499999, 0.0,
                      0.499999, 0.5, 0.500001, 10.0):
            add_piecewise_case([value])

        for special in (math.nan, math.inf, -math.inf):
            if oracle([special]) is not None:
                raise ValueError("piecewise_without_inbuilt oracle accepted a non-finite input")
            add_piecewise_case([special])

        parseable_limit_input = [0.0] * 64
        if len(parseable_limit_input) != 64 or oracle(parseable_limit_input) is not None:
            raise ValueError("piecewise_without_inbuilt parseable-limit probe is malformed")
        add_piecewise_case(parseable_limit_input)

        valid_capacity_probe = [0.125]
        if oracle(valid_capacity_probe) is None:
            raise ValueError("piecewise_without_inbuilt oracle rejected a valid capacity probe")
        add_piecewise_case(valid_capacity_probe, capacity=0)
        add_piecewise_case(valid_capacity_probe, capacity=1)
        add_piecewise_case(valid_capacity_probe, output_is_null=True)

        invalid_before_null_output = [10.000001]
        if oracle(invalid_before_null_output) is not None:
            raise ValueError("piecewise_without_inbuilt oracle accepted invalid input before null output")
        add_piecewise_case(invalid_before_null_output, capacity=0, output_is_null=True)

        for malformed in ([], [0.0, 0.0]):
            if oracle(malformed) is not None:
                raise ValueError("piecewise_without_inbuilt oracle accepted malformed input framing")
            add_piecewise_case(malformed)
    elif algorithm == "linear_regression_vectorized":
        oracle = ORACLES[algorithm]

        def add_linear_regression_case(inputs: list[float], capacity: int = workspace,
                                       output_is_null: bool = False) -> None:
            expected = oracle(inputs)
            if expected is None:
                result, output = -1, []
            elif output_is_null or len(expected) > capacity:
                result, output = -2, []
            else:
                result, output = len(expected), expected
            records.append((inputs, result, output, capacity, 0, int(output_is_null)))

        rng_regression = random.Random(20261017)
        for _ in range(128):
            sample_count = rng_regression.randint(
                LINEAR_REGRESSION_MIN_SAMPLE_COUNT, LINEAR_REGRESSION_MAX_SAMPLE_COUNT)
            feature_count = rng_regression.randint(
                LINEAR_REGRESSION_MIN_FEATURE_COUNT, LINEAR_REGRESSION_MAX_FEATURE_COUNT)
            iterations = rng_regression.randint(
                LINEAR_REGRESSION_MIN_ITERATIONS, LINEAR_REGRESSION_MAX_ITERATIONS)
            alpha = rng_regression.uniform(LINEAR_REGRESSION_MIN_ALPHA, LINEAR_REGRESSION_MAX_ALPHA)
            features: list[float] = []
            for _row in range(sample_count):
                features.append(1.0)
                features.extend(rng_regression.uniform(
                    LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL,
                    LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL)
                    for _column in range(feature_count - 1))
            labels = [rng_regression.uniform(
                LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL,
                LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL)
                for _row in range(sample_count)]
            inputs = [float(sample_count), float(feature_count), float(iterations), alpha,
                      *features, *labels]
            add_linear_regression_case(inputs)

        valid_probe = [float(value) for value in workload["cases"][0]["input_values"]]
        add_linear_regression_case(valid_probe, capacity=1)
        add_linear_regression_case(valid_probe, output_is_null=True)
        invalid_before_null = [0.0, 2.0, 10.0, 0.001, 1.0, 0.0, 1.0, 0.0]
        if oracle(invalid_before_null) is not None:
            raise ValueError("linear_regression_vectorized oracle accepted invalid input before null output")
        add_linear_regression_case(invalid_before_null, capacity=0, output_is_null=True)
    elif algorithm == "perlin_noise":
        oracle = ORACLES[algorithm]

        def add_perlin_case(inputs: list[float], capacity: int = workspace,
                            output_is_null: bool = False) -> None:
            expected = oracle(inputs)
            if expected is None:
                result, output = -1, []
            elif output_is_null or len(expected) > capacity:
                result, output = PERLIN_NOISE_OUTPUT_ERROR, []
            else:
                result, output = len(expected), expected
            records.append((inputs, result, output, capacity, 0, int(output_is_null)))

        rng_perlin = random.Random(20261017)
        for index in range(128):
            width = rng_perlin.randint(PERLIN_NOISE_MIN_DIMENSION, PERLIN_NOISE_MAX_DIMENSION)
            height = rng_perlin.randint(PERLIN_NOISE_MIN_DIMENSION, PERLIN_NOISE_MAX_DIMENSION)
            octave_count = rng_perlin.randint(PERLIN_NOISE_MIN_OCTAVES, PERLIN_NOISE_MAX_OCTAVES)
            persistence = rng_perlin.choice(PERLIN_NOISE_PERSISTENCE_VALUES)
            seed = rng_perlin.choice((PERLIN_NOISE_MIN_SEED, 1, 12345,
                                      PERLIN_NOISE_MAX_SEED,
                                      rng_perlin.randint(PERLIN_NOISE_MIN_SEED,
                                                         PERLIN_NOISE_MAX_SEED)))
            inputs = [float(width), float(height), float(octave_count), persistence, float(seed)]
            add_perlin_case(inputs)
            if index % 16 == 0:
                add_perlin_case(inputs, output_is_null=True)

        valid_probe = [1.0, 1.0, 1.0, 0.5, 0.0]
        add_perlin_case(valid_probe, capacity=0)
        add_perlin_case(valid_probe, capacity=1)
        add_perlin_case(valid_probe, output_is_null=True)

        invalid_before_null_output = [0.0, 1.0, 1.0, 0.5, 0.0]
        if oracle(invalid_before_null_output) is not None:
            raise ValueError("perlin_noise oracle accepted invalid input before null output")
        add_perlin_case(invalid_before_null_output, capacity=0, output_is_null=True)

        malformed = (
            [], [1.0, 1.0, 1.0, 0.5], [1.0, 1.0, 1.0, 0.5, 0.0, 0.0],
            [1.5, 1.0, 1.0, 0.5, 0.0], [1.0, 1.0, 0.0, 0.5, 0.0],
            [1.0, 1.0, 1.0, 0.25, 0.0], [1.0, 1.0, 1.0, 0.5, -1.0],
        )
        for inputs in malformed:
            add_perlin_case(inputs)
        # The checker distinguishes a null pointer from a one-element input array.
        records.append(([0.0], PERLIN_NOISE_INVALID_RESULT, [], workspace, 1, 0))

    lines = [f"{len(records)} {absolute_tolerance:.17g} {relative_tolerance:.17g} {workspace}\n"]
    for inputs, expected_result, expected_output, capacity, input_null, output_null in records:
        lines.append(f"{len(inputs)} {expected_result} {len(expected_output)} {capacity} "
                     f"{input_null} {output_null}\n")
        if inputs:
            lines.append(" ".join(format(value, ".17g") for value in inputs) + "\n")
        if expected_output:
            lines.append(" ".join(_format_output(value) for value in expected_output) + "\n")
    return "".join(lines), len(records)


def _matches_output(observed: object, expected: list[float | str],
                    absolute_tolerance: float, relative_tolerance: float) -> bool:
    if not isinstance(observed, list) or len(observed) != len(expected):
        return False
    for actual, reference in zip(observed, expected):
        if reference == "NaN":
            if actual != "NaN":
                return False
            continue
        if type(actual) not in (int, float) or not math.isfinite(float(actual)):
            return False
        target = float(reference)
        if abs(float(actual) - target) > absolute_tolerance + relative_tolerance * abs(target):
            return False
    return True


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    extra_link_sources = ()
    if language == "elisa" and elisa_compiler:
        runtime = Path(elisa_compiler).resolve().parent.parent / "build/runtime/elisacore_runtime.o"
        if runtime.is_file():
            extra_link_sources = (runtime,)
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_slice_io",
                     extra_link_sources=extra_link_sources)
    checker = manifest["binaries"]["float64_slice_io_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64-slice C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete float64-slice corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_float64_slice_io.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case, record in zip(workload["cases"], records):
        values, expected_result, expected_output = encode_case(
            case, algorithm, absolute_tolerance, relative_tolerance)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_result
                or record["workload"]["expected_output"] != expected_output
                or record["measurement"]["comparison_model"] != "float64_slice_io_call"
                or record["measurement"]["observed_result"] != expected_result
                or not _matches_output(record["measurement"]["observed_output"], expected_output,
                                       absolute_tolerance, relative_tolerance)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, required=True)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    algorithm = args.algorithm
    workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != algorithm:
        parser.error("workload algorithm does not match the requested algorithm")
    if algorithm == "pid":
        validate_pid_workload(workload)
    elif algorithm == "joint_probability_distribution":
        validate_joint_probability_distribution_workload(workload)
    elif algorithm == "shreedharacharya":
        validate_shreedharacharya_workload(workload)
    elif algorithm == "rotation_matrix":
        validate_rotation_matrix_workload(workload)
    elif algorithm == "simple_pendulum_rk4":
        validate_simple_pendulum_rk4_workload(workload)
    elif algorithm == "koch_snowflake":
        validate_koch_snowflake_workload(workload)
    elif algorithm == "k_d_tree":
        validate_k_d_tree_workload(workload)
    elif algorithm == "linear_regression_vectorized":
        validate_linear_regression_vectorized_workload(workload)
    elif algorithm == "perlin_noise":
        validate_perlin_noise_workload(workload)
    elif algorithm == "single_point_crossover":
        validate_single_point_crossover_workload(workload)
    elif algorithm == "quaternions":
        validate_quaternions_workload(workload)
    data, count = checker_records(algorithm, workload)
    build_root = (args.build_dir or ROOT / "build" / "float64_slice_io" / algorithm).resolve()
    build_root.mkdir(parents=True, exist_ok=True)
    (build_root / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {
            pool.submit(verify, algorithm, language, build_root / language,
                        args.elisa_compiler, data, count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
                results.append(result)
                print(f"PASS {language}: {count} ABI cases, {result['workload_records']} workload records",
                      flush=True)
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {language}: {error}", file=sys.stderr, flush=True)
    report = {"algorithm": algorithm, "results": sorted(results, key=lambda result: result["language"]),
              "failures": failures}
    (build_root / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
