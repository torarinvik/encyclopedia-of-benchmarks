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
                                  validate_rhumb_distance_workload,
                                  validate_rhumb_bearing_workload,
                                  validate_rhumb_destination_workload,
                                  validate_median_of_running_array_double_workload,
                                  validate_median_of_running_array_float_workload,
                                  validate_mean_shift_workload,
                                  validate_k_means_clust_workload,
                                  validate_lu_decompose_workload,
                                  validate_polynomial_regression_workload,
                                  validate_pi_monte_carlo_estimation_workload,
                                  validate_momentum_sgd_workload,
                                  validate_soboleva_modified_hyperbolic_tangent_workload,
                                  validate_rmsprop_workload,
                                  validate_sherman_morrison_workload,
                                  SHERMAN_MORRISON_MAX_DIMENSION,
                                  SHERMAN_MORRISON_MAX_ENTRY,
                                  SHERMAN_MORRISON_MAX_OUTPUT_ELEMENTS,
                                  SHERMAN_MORRISON_MAX_PARSEABLE_INPUT_LENGTH,
                                  SHERMAN_MORRISON_MIN_DIMENSION,
                                  SHERMAN_MORRISON_MIN_ENTRY,
                                  _sherman_morrison_finite_number,
                                  rmsprop_abi_oracle,
                                  RMSPROP_MAX_EPSILON, RMSPROP_MAX_GRADIENT,
                                  RMSPROP_MAX_LEARNING_RATE, RMSPROP_MAX_MOVING_AVERAGE,
                                  RMSPROP_MAX_PARAMETER, RMSPROP_MAX_RHO,
                                  RMSPROP_MAX_VECTOR_LENGTH, RMSPROP_MIN_EPSILON,
                                  RMSPROP_MIN_GRADIENT, RMSPROP_MIN_LEARNING_RATE,
                                  RMSPROP_MIN_MOVING_AVERAGE, RMSPROP_MIN_PARAMETER,
                                  RMSPROP_MIN_RHO, RMSPROP_MIN_VECTOR_LENGTH,
                                  _same_float64_sequence,
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
from median_of_running_array_float_oracle import _as_float32 as median_float32
from mean_shift_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH as MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH,
    WORKSPACE_ELEMENTS as MEAN_SHIFT_WORKSPACE_ELEMENTS,
    expected_output as mean_shift_oracle,
)
from k_means_clust_oracle import (
    MAX_CLUSTER_COUNT as K_MEANS_CLUST_MAX_CLUSTER_COUNT,
    MAX_DIMENSION as K_MEANS_CLUST_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as K_MEANS_CLUST_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as K_MEANS_CLUST_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_POINT_COUNT as K_MEANS_CLUST_MAX_POINT_COUNT,
    MAX_VALID_INPUT_LENGTH as K_MEANS_CLUST_MAX_VALID_INPUT_LENGTH,
    expected_output as k_means_clust_abi_oracle,
)
from lu_decompose_oracle import (
    MAX_DIMENSION as LU_DECOMPOSE_MAX_DIMENSION,
    MAX_OUTPUT_ELEMENTS as LU_DECOMPOSE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as LU_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as LU_DECOMPOSE_MAX_VALID_INPUT_LENGTH,
    expected_output as lu_decompose_abi_oracle,
)
from polynomial_regression_oracle import (
    MAX_ABSCISSA as POLYNOMIAL_REGRESSION_MAX_ABSCISSA,
    MAX_DEGREE as POLYNOMIAL_REGRESSION_MAX_DEGREE,
    MAX_PARSEABLE_INPUT_LENGTH as POLYNOMIAL_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERY_COUNT as POLYNOMIAL_REGRESSION_MAX_QUERY_COUNT,
    MAX_RESPONSE as POLYNOMIAL_REGRESSION_MAX_RESPONSE,
    MAX_TRAINING_COUNT as POLYNOMIAL_REGRESSION_MAX_TRAINING_COUNT,
    MAX_VALID_INPUT_LENGTH as POLYNOMIAL_REGRESSION_MAX_VALID_INPUT_LENGTH,
    MIN_ABSCISSA as POLYNOMIAL_REGRESSION_MIN_ABSCISSA,
    MIN_DEGREE as POLYNOMIAL_REGRESSION_MIN_DEGREE,
    MIN_QUERY_COUNT as POLYNOMIAL_REGRESSION_MIN_QUERY_COUNT,
    MIN_RESPONSE as POLYNOMIAL_REGRESSION_MIN_RESPONSE,
    expected_output as polynomial_regression_abi_oracle,
)
from soboleva_modified_hyperbolic_tangent_oracle import expected_output as soboleva_modified_hyperbolic_tangent_abi_oracle
from soboleva_modified_hyperbolic_tangent_oracle import INVALID_RESULT as SOBOLEVA_MODIFIED_HYPERBOLIC_TANGENT_INVALID_RESULT
from momentum_sgd_oracle import (
    MAX_CALL_COUNT as MOMENTUM_SGD_MAX_CALL_COUNT,
    MAX_GROUP_COUNT as MOMENTUM_SGD_MAX_GROUP_COUNT,
    MAX_GROUP_VECTOR_ELEMENTS as MOMENTUM_SGD_MAX_GROUP_VECTOR_ELEMENTS,
    MAX_GRADIENT as MOMENTUM_SGD_MAX_GRADIENT,
    MAX_LEARNING_RATE as MOMENTUM_SGD_MAX_LEARNING_RATE,
    MAX_MOMENTUM as MOMENTUM_SGD_MAX_MOMENTUM,
    MAX_OUTPUT_ELEMENTS as MOMENTUM_SGD_MAX_OUTPUT_ELEMENTS,
    MAX_PARAMETER as MOMENTUM_SGD_MAX_PARAMETER,
    MAX_VECTOR_LENGTH as MOMENTUM_SGD_MAX_VECTOR_LENGTH,
    MIN_CALL_COUNT as MOMENTUM_SGD_MIN_CALL_COUNT,
    MIN_GROUP_COUNT as MOMENTUM_SGD_MIN_GROUP_COUNT,
    MIN_GRADIENT as MOMENTUM_SGD_MIN_GRADIENT,
    MIN_LEARNING_RATE as MOMENTUM_SGD_MIN_LEARNING_RATE,
    MIN_MOMENTUM as MOMENTUM_SGD_MIN_MOMENTUM,
    MIN_PARAMETER as MOMENTUM_SGD_MIN_PARAMETER,
    MIN_VECTOR_LENGTH as MOMENTUM_SGD_MIN_VECTOR_LENGTH,
    expected_output as momentum_sgd_abi_oracle,
)
from sherman_morrison_oracle import expected_output as sherman_morrison_abi_oracle

ALGORITHMS = tuple(ORACLES)


def checker_records(algorithm: str, workload: dict) -> tuple[str, int]:
    if algorithm == "rhumb_distance":
        validate_rhumb_distance_workload(workload)
    elif algorithm == "rhumb_bearing":
        validate_rhumb_bearing_workload(workload)
    elif algorithm == "rhumb_destination":
        validate_rhumb_destination_workload(workload)
    elif algorithm == "median_of_running_array_double":
        validate_median_of_running_array_double_workload(workload)
    elif algorithm == "median_of_running_array_float":
        validate_median_of_running_array_float_workload(workload)
    elif algorithm == "mean_shift":
        validate_mean_shift_workload(workload)
    elif algorithm == "pi_monte_carlo_estimation":
        validate_pi_monte_carlo_estimation_workload(workload)
    elif algorithm == "soboleva_modified_hyperbolic_tangent":
        validate_soboleva_modified_hyperbolic_tangent_workload(workload)
    elif algorithm == "rmsprop":
        validate_rmsprop_workload(workload)
    elif algorithm == "momentum_sgd":
        validate_momentum_sgd_workload(workload)
    elif algorithm == "k_means_clust":
        validate_k_means_clust_workload(workload)
    elif algorithm == "lu_decompose":
        validate_lu_decompose_workload(workload)
    elif algorithm == "polynomial_regression":
        validate_polynomial_regression_workload(workload)
    elif algorithm == "sherman_morrison":
        validate_sherman_morrison_workload(workload)
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
                   if algorithm in {"joint_probability_distribution", "shreedharacharya", "rotation_matrix",
                                    "rhumb_distance", "rhumb_bearing", "rhumb_destination",
                                    "median_of_running_array_double", "median_of_running_array_float",
                                    "mean_shift", "k_means_clust", "lu_decompose",
                                    "polynomial_regression"}
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

    if algorithm == "rmsprop":
        oracle = rmsprop_abi_oracle

        def add_rmsprop_case(inputs: list[float], capacity: int = workspace,
                             output_is_null: bool = False, input_is_null: bool = False,
                             input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(not _sherman_morrison_finite_number(value)
                           for value in raw_values)):
                raise ValueError(f"invalid rmsprop ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"invalid rmsprop ABI framing: {case.get('id')}")
            result, output = add_rmsprop_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or result != case["expected_result"]
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"rmsprop ABI workload mismatch: {case.get('id')}")

        rng_rmsprop = random.Random(20261017)
        for index in range(128):
            count = rng_rmsprop.randint(RMSPROP_MIN_VECTOR_LENGTH, RMSPROP_MAX_VECTOR_LENGTH)
            state_mode = rng_rmsprop.randrange(2)
            learning_rate = 10 ** rng_rmsprop.uniform(
                math.log10(RMSPROP_MIN_LEARNING_RATE), math.log10(RMSPROP_MAX_LEARNING_RATE))
            rho = rng_rmsprop.uniform(RMSPROP_MIN_RHO, RMSPROP_MAX_RHO)
            epsilon = 10 ** rng_rmsprop.uniform(
                math.log10(RMSPROP_MIN_EPSILON), math.log10(RMSPROP_MAX_EPSILON))
            params = [rng_rmsprop.uniform(RMSPROP_MIN_PARAMETER, RMSPROP_MAX_PARAMETER)
                      for _ in range(count)]
            gradients = [rng_rmsprop.uniform(RMSPROP_MIN_GRADIENT, RMSPROP_MAX_GRADIENT)
                         for _ in range(count)]
            moving_average = (
                [rng_rmsprop.uniform(RMSPROP_MIN_MOVING_AVERAGE, RMSPROP_MAX_MOVING_AVERAGE)
                 for _ in range(count)] if state_mode == 1 else [])
            inputs = [float(count), float(state_mode), learning_rate, rho, epsilon,
                      *params, *gradients, *moving_average]
            result, _ = add_rmsprop_case(inputs)
            if count > 0 and index % 16 == 0:
                add_rmsprop_case(inputs, capacity=2 * count - 1)
            if count > 0 and index % 32 == 0:
                add_rmsprop_case(inputs, output_is_null=True)
            if index % 32 == 0:
                add_rmsprop_case([0.0, 0.0, 0.01, 0.9, 1e-8], capacity=0)
                add_rmsprop_case([0.0, 0.0, 0.01, 0.9, 1e-8],
                                 capacity=0, output_is_null=True)

        malformed = (
            [], [0.0], [1.5, 0.0, 0.01, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 0.5, 0.01, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 2.0, 0.01, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 1.0],
            [1.0, 0.0, 0.0, 0.9, 1e-8, 1.0, 0.5],
            [1.0, 0.0, 0.01, 1.0, 1e-8, 1.0, 0.5],
            [1.0, 0.0, 0.01, 0.9, 0.0, 1.0, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 100.000001, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 1.0, -100.000001],
            [1.0, 1.0, 0.01, 0.9, 1e-8, 1.0, 0.5, -0.000001],
            [1.0, 1.0, 0.01, 0.9, 1e-8, 1.0, 0.5, 10000.000001],
            [0.0, 0.0, 0.01, 0.9, 1e-8, *([0.0] * 97)],
            [1.0, 0.0, 0.01, 0.9, 1e-8, math.nan, 0.5],
            [1.0, 0.0, 0.01, 0.9, 1e-8, 1.0, math.inf],
        )
        for inputs in malformed:
            add_rmsprop_case(inputs)
        add_rmsprop_case([1.0, 0.0, 0.01, 0.9, 1e-8, 1.0, 0.5, 0.0],
                         capacity=64, output_is_null=True)

    if algorithm == "sherman_morrison":
        oracle = sherman_morrison_abi_oracle

        def add_sherman_morrison_case(
                inputs: list[float], capacity: int = workspace,
                output_is_null: bool = False, input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, list(output)

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(f"invalid sherman_morrison ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int
                    or not 0 <= capacity <= SHERMAN_MORRISON_MAX_OUTPUT_ELEMENTS
                    or type(output_is_null) is not bool or type(input_is_null) is not bool
                    or type(input_length) is not int
                    or not 0 <= input_length <= SHERMAN_MORRISON_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"invalid sherman_morrison ABI framing: {case.get('id')}")
            result, output = add_sherman_morrison_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (type(case.get("expected_result")) is not int
                    or result != case["expected_result"]
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"sherman_morrison ABI workload mismatch: {case.get('id')}")

        rng_sherman_morrison = random.Random(20261017)
        for index in range(128):
            dimension = rng_sherman_morrison.randint(
                SHERMAN_MORRISON_MIN_DIMENSION, SHERMAN_MORRISON_MAX_DIMENSION)
            coefficient = lambda: float(rng_sherman_morrison.randint(
                SHERMAN_MORRISON_MIN_ENTRY, SHERMAN_MORRISON_MAX_ENTRY))
            matrix = [coefficient() for _ in range(dimension * dimension)]
            u = [coefficient() for _ in range(dimension)]
            v = [coefficient() for _ in range(dimension)]
            inputs = [float(dimension), *matrix, *u, *v]
            result, _ = add_sherman_morrison_case(inputs)
            if result > 0:
                add_sherman_morrison_case(inputs, capacity=result - 1)
                if index % 16 == 0:
                    add_sherman_morrison_case(inputs, output_is_null=True)

        maximum_case = next(case for case in workload["cases"]
                            if case["id"] == "four_by_four_maximum_shape")
        maximum_inputs = [float(value) for value in maximum_case["input_values"]]
        add_sherman_morrison_case(maximum_inputs, capacity=15)
        add_sherman_morrison_case(maximum_inputs, capacity=16)
        add_sherman_morrison_case(maximum_inputs, output_is_null=True)
        malformed_inputs = (
            [], [0.0], [5.0], [1.5], [1.0, 0.5, 0.0, 0.0],
            [1.0, 3.0, 1.0, 1.0], [2.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0],
            [1.0, 1.0, 1.0, 1.0, 0.0],
            [4.0, *([0.0] * (SHERMAN_MORRISON_MAX_PARSEABLE_INPUT_LENGTH - 1))],
            [1.0, math.nan, 1.0, 1.0], [1.0, math.inf, 1.0, 1.0],
        )
        for inputs in malformed_inputs:
            add_sherman_morrison_case(inputs)
        add_sherman_morrison_case([1.0, 3.0, 1.0, 1.0],
                                  capacity=0, output_is_null=True)

    if algorithm in {"median_of_running_array_double", "median_of_running_array_float"}:
        oracle = ORACLES[algorithm]
        is_float = algorithm == "median_of_running_array_float"

        def add_median_double_case(inputs: list[float], capacity: int = workspace,
                                   output_is_null: bool = False, input_is_null: bool = False,
                                   input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid median_of_running_array_double ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            input_length = case.get("input_length", len(inputs))
            result, output = add_median_double_case(
                inputs, capacity, output_is_null, input_is_null, input_length)
            if (result != case.get("expected_result")
                    or not _same_float64_sequence(output, case.get("expected_output"))):
                raise ValueError(f"{algorithm} ABI probe mismatch: {case.get('id')}")

        rng_median = random.Random(20261020)
        special_samples = (-1_000_000.0, 1_000_000.0, -0.0, 0.0)
        for index in range(128):
            sample_count = rng_median.randint(1, 64)
            samples = [rng_median.choice(special_samples) if index % 4 == 0
                       else (median_float32(rng_median.uniform(-1_000_000.0, 1_000_000.0))
                             if is_float else rng_median.uniform(-1_000_000.0, 1_000_000.0))
                       for _ in range(sample_count)]
            inputs = [float(sample_count), *samples]
            result, _ = add_median_double_case(inputs)
            if result > 0:
                add_median_double_case(inputs, capacity=result - 1)
                if index % 16 == 0:
                    add_median_double_case(inputs, output_is_null=True)

        malformed = (
            [], [0.0], [1.5, 0.0], [65.0], [1.0], [1.0, 1.0, 2.0],
            [1.0, -1_000_000.000001], [1.0, 1_000_000.000001],
            [66.0, *([0.0] * 65)],
            [1.0, math.nan], [1.0, math.inf], [1.0, -math.inf],
        )
        if is_float:
            malformed += ([1.0, 0.1],)
        for inputs in malformed:
            add_median_double_case(inputs)

    if algorithm in {"rhumb_distance", "rhumb_bearing", "rhumb_destination"}:
        oracle = ORACLES[algorithm]

        def add_rhumb_case(inputs: list[float], capacity: int = workspace,
                           output_is_null: bool = False, input_is_null: bool = False,
                           input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case["input_values"]
            inputs = [float(value) for value in raw_values]
            result, output = add_rhumb_case(
                inputs, case["output_capacity"], case.get("output_is_null", False),
                case.get("input_is_null", False), case["input_length"])
            expected = case.get("expected_output", [])
            if (result != case["expected_result"] or len(output) != len(expected)
                    or any(abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected, output))):
                raise ValueError(f"{algorithm} ABI probe mismatch: {case.get('id')}")

        rng_rhumb = random.Random(20261017)
        for index in range(128):
            if algorithm in {"rhumb_distance", "rhumb_bearing"}:
                inputs = [rng_rhumb.uniform(-85.0, 85.0), rng_rhumb.uniform(-180.0, 180.0),
                          rng_rhumb.uniform(-85.0, 85.0), rng_rhumb.uniform(-180.0, 180.0)]
            else:
                inputs = [rng_rhumb.uniform(-80.0, 80.0), rng_rhumb.uniform(-180.0, 180.0),
                          rng_rhumb.uniform(0.0, 300_000.0), rng_rhumb.uniform(0.0, 360.0)]
            add_rhumb_case(inputs)
            if index % 16 == 0:
                add_rhumb_case(inputs, output_is_null=True)

        valid_probe = ([10.0, 20.0, 30.0, 40.0] if algorithm != "rhumb_destination"
                       else [10.0, 20.0, 100_000.0, 90.0])
        add_rhumb_case(valid_probe, capacity=0)
        add_rhumb_case(valid_probe, capacity=1)
        malformed_inputs = ([], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 1.0],
                            [85.000001, 0.0, 0.0, 0.0], [0.0, 180.000001, 0.0, 0.0])
        if algorithm == "rhumb_destination":
            malformed_inputs += ([0.0, 0.0, -1.0, 0.0], [0.0, 0.0, 300_001.0, 0.0],
                                 [0.0, 0.0, 0.0, 360.0001])
        for malformed in malformed_inputs:
            add_rhumb_case(malformed)
        add_rhumb_case([86.0, 0.0, 0.0, 0.0], capacity=0, output_is_null=True)

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

    if algorithm == "mean_shift":
        if (workspace != MEAN_SHIFT_WORKSPACE_ELEMENTS
                or absolute_tolerance != 0.0 or relative_tolerance != 0.0):
            raise ValueError("mean_shift requires a 16-element workspace and exact label comparison")
        nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf, "-Infinity": -math.inf}
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if not isinstance(raw_values, list):
                raise ValueError(f"mean_shift ABI input must be an array: {case.get('id')}")
            inputs: list[float] = []
            for value in raw_values:
                if isinstance(value, str) and value in nonfinite_tokens:
                    inputs.append(nonfinite_tokens[value])
                elif type(value) in (int, float):
                    inputs.append(float(value))
                else:
                    raise ValueError(f"mean_shift ABI input token is invalid: {case.get('id')}")
            capacity = case.get("output_capacity")
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(inputs))
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(input_is_null) is not bool or type(output_is_null) is not bool
                    or input_is_null and output_is_null
                    or type(input_length) is not int
                    or not 0 <= input_length <= MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH
                    or input_is_null and (inputs or input_length <= 0)
                    or not input_is_null and input_length != len(inputs)):
                raise ValueError(f"mean_shift ABI framing is invalid: {case.get('id')}")
            result, output = mean_shift_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or not _same_float64_sequence(expected_output, output)):
                raise ValueError(f"mean_shift ABI workload mismatch: {case.get('id')}")
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))

        valid_nonfinite_base = [1.0, 1.0, 1.0, 1.0, 0.01, 0.0]
        for index in range(len(valid_nonfinite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(valid_nonfinite_base)
                inputs[index] = special
                result, output = mean_shift_oracle(inputs)
                if result != -1 or output:
                    raise ValueError("mean_shift oracle accepted a nonfinite ABI probe")
                records.append((inputs, -1, [], workspace, 0, 0))

    if algorithm == "k_means_clust":
        if (workspace != K_MEANS_CLUST_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("k_means_clust requires a 32-element workspace and 1e-12 tolerances")

        def add_k_means_case(inputs: list[float], capacity: int = workspace,
                             output_is_null: bool = False, input_is_null: bool = False,
                             input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            oracle_inputs = [] if input_is_null else inputs
            result, output = k_means_clust_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > K_MEANS_CLUST_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid k_means_clust ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
            output_is_null = False if output_is_null is None else output_is_null
            input_is_null = False if input_is_null is None else input_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = k_means_clust_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"k_means_clust ABI fixture mismatch: {case.get('id')}")
            add_k_means_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_k_means = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            if index == 0:
                point_count = K_MEANS_CLUST_MAX_POINT_COUNT
                dimension = K_MEANS_CLUST_MAX_DIMENSION
                cluster_count = K_MEANS_CLUST_MAX_CLUSTER_COUNT
            else:
                point_count = rng_k_means.randint(1, K_MEANS_CLUST_MAX_POINT_COUNT)
                dimension = rng_k_means.randint(1, K_MEANS_CLUST_MAX_DIMENSION)
                cluster_count = rng_k_means.randint(1, min(K_MEANS_CLUST_MAX_CLUSTER_COUNT,
                                                           point_count))
            centroids = [[-12 + 8 * cluster]
                         + [rng_k_means.randint(-16, 16) for _ in range(dimension - 1)]
                         for cluster in range(cluster_count)]
            data = [list(centroid) for centroid in centroids]
            data.extend([[rng_k_means.randint(-16, 16) for _ in range(dimension)]
                         for _ in range(point_count - cluster_count)])
            rng_k_means.shuffle(data)
            inputs = [float(point_count), float(dimension), float(cluster_count)]
            inputs.extend(float(value) for point in data for value in point)
            inputs.extend(float(value) for centroid in centroids for value in centroid)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != K_MEANS_CLUST_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("k_means_clust maximum-shape trace is not 83 values")
            result, output = add_k_means_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("k_means_clust oracle rejected a generated valid trace")
            if index == 0:
                add_k_means_case(inputs, capacity=result)
                add_k_means_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_k_means_case(inputs, output_is_null=True)

        assert maximum_valid is not None
        if len(maximum_valid) + 1 != K_MEANS_CLUST_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("k_means_clust maximum parseable shape is not 84 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [0.0, 1.0, 1.0, 0.0, 0.0],
            [1.5, 1.0, 1.0, 0.0, 0.0],
            [1.0, 0.0, 1.0, 0.0],
            [1.0, 1.0, 5.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
            [1.0, 1.0, 1.0, 0.5, 0.0],
            [1.0, 1.0, 1.0, 17.0, 0.0],
            [2.0, 1.0, 2.0, 0.0, 1.0, 0.0, 16.0],
        )
        for inputs in malformed:
            add_k_means_case(inputs)
        add_k_means_case([2.0, 1.0, 2.0, 0.0, 1.0, 0.0, 16.0],
                         output_is_null=True)
        add_k_means_case([], input_is_null=True, input_length=5)

    if algorithm == "lu_decompose":
        if (workspace != LU_DECOMPOSE_MAX_OUTPUT_ELEMENTS
                or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("lu_decompose requires a 32-element workspace and 1e-12 tolerances")

        def add_lu_case(inputs: list[float], capacity: int = workspace,
                        output_is_null: bool = False, input_is_null: bool = False,
                        input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            oracle_inputs = [] if input_is_null else inputs
            result, output = lu_decompose_abi_oracle(
                oracle_inputs, capacity, output_is_null, input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > LU_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid lu_decompose ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            if capacity is None:
                capacity = workspace
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = lu_decompose_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"lu_decompose ABI fixture mismatch: {case.get('id')}")
            add_lu_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_lu = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            dimension = (LU_DECOMPOSE_MAX_DIMENSION if index == 0 else
                         rng_lu.randint(1, LU_DECOMPOSE_MAX_DIMENSION))
            matrix = [[rng_lu.randint(-1, 1) for _ in range(dimension)]
                      for _ in range(dimension)]
            for diagonal in range(dimension):
                matrix[diagonal][diagonal] = rng_lu.randint(4, 8)
            inputs = [float(dimension)]
            inputs.extend(float(value) for row in matrix for value in row)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != LU_DECOMPOSE_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("lu_decompose maximum-shape trace is not 17 values")
            result, output = add_lu_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("lu_decompose oracle rejected a generated valid trace")
            if index == 0:
                add_lu_case(inputs, capacity=result)
                add_lu_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_lu_case(inputs, output_is_null=True)

        if maximum_valid is None or len(maximum_valid) + 1 != LU_DECOMPOSE_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError("lu_decompose maximum parseable shape is not 18 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [0.0], [1.5, 0.0], [5.0] + [0.0] * 16,
            [1.0, 0.5], [1.0, 9.0], [2.0, 1.0, 2.0, 2.0, 4.0],
        )
        for inputs in malformed:
            add_lu_case(inputs)
        add_lu_case([2.0, 1.0, 2.0, 2.0, 4.0], output_is_null=True)
        add_lu_case([], input_is_null=True, input_length=2)

    if algorithm == "polynomial_regression":
        if (workspace != 8 or absolute_tolerance != 1e-9 or relative_tolerance != 1e-9):
            raise ValueError("polynomial_regression requires an 8-element workspace and 1e-9 tolerances")

        def add_polynomial_case(inputs: list[float], capacity: int = workspace,
                                output_is_null: bool = False, input_is_null: bool = False,
                                input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            result, output = polynomial_regression_abi_oracle(
                [] if input_is_null else inputs, capacity, output_is_null,
                input_is_null, input_length)
            checker_inputs = [0.0] * input_length if input_is_null else inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or len(raw_values) > POLYNOMIAL_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid polynomial_regression ABI values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            capacity = workspace if capacity is None else capacity
            input_is_null = case.get("input_is_null")
            output_is_null = case.get("output_is_null")
            input_is_null = False if input_is_null is None else input_is_null
            output_is_null = False if output_is_null is None else output_is_null
            input_length = case.get("input_length", len(inputs))
            result, output = polynomial_regression_abi_oracle(
                inputs, capacity, output_is_null, input_is_null, input_length)
            expected = case.get("expected_output")
            if (case.get("expected_result") != result or not isinstance(expected, list)
                    or len(expected) != len(output)
                    or any(type(actual) not in (int, float) or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected, output))):
                raise ValueError(f"polynomial_regression ABI fixture mismatch: {case.get('id')}")
            add_polynomial_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_polynomial = random.Random(20261017)
        maximum_valid: list[float] | None = None
        for index in range(128):
            if index == 0:
                degree, training_count, query_count = 3, 5, 4
            else:
                degree = rng_polynomial.randint(
                    POLYNOMIAL_REGRESSION_MIN_DEGREE, POLYNOMIAL_REGRESSION_MAX_DEGREE)
                training_count = rng_polynomial.randint(
                    degree + 1, POLYNOMIAL_REGRESSION_MAX_TRAINING_COUNT)
                query_count = rng_polynomial.randint(
                    POLYNOMIAL_REGRESSION_MIN_QUERY_COUNT, POLYNOMIAL_REGRESSION_MAX_QUERY_COUNT)
            x_train = rng_polynomial.sample(
                range(POLYNOMIAL_REGRESSION_MIN_ABSCISSA,
                      POLYNOMIAL_REGRESSION_MAX_ABSCISSA + 1),
                training_count)
            y_train = [rng_polynomial.randint(
                POLYNOMIAL_REGRESSION_MIN_RESPONSE, POLYNOMIAL_REGRESSION_MAX_RESPONSE)
                for _ in range(training_count)]
            x_query = [rng_polynomial.randint(
                POLYNOMIAL_REGRESSION_MIN_ABSCISSA,
                POLYNOMIAL_REGRESSION_MAX_ABSCISSA)
                for _ in range(query_count)]
            inputs = [float(degree), float(training_count), float(query_count)]
            inputs.extend(float(value) for value in x_train)
            inputs.extend(float(value) for value in y_train)
            inputs.extend(float(value) for value in x_query)
            if index == 0:
                maximum_valid = inputs
                if len(inputs) != POLYNOMIAL_REGRESSION_MAX_VALID_INPUT_LENGTH:
                    raise ValueError("polynomial_regression maximum-shape trace is not 17 values")
            result, output = add_polynomial_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("polynomial_regression oracle rejected a generated valid trace")
            if index == 0:
                add_polynomial_case(inputs, capacity=result)
                add_polynomial_case(inputs, capacity=result - 1)
            if index % 16 == 0:
                add_polynomial_case(inputs, output_is_null=True)

        if (maximum_valid is None
                or len(maximum_valid) + 1 != POLYNOMIAL_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH):
            raise ValueError("polynomial_regression maximum parseable shape is not 18 values")
        malformed = (
            [], maximum_valid[:-1], maximum_valid + [0.0],
            [4.0, 1.0, 1.0, 0.0, 0.0, 0.0],
            [1.5, 2.0, 1.0, 0.0, 1.0, 0.0, 1.0, 2.0],
            [2.0, 2.0, 1.0, 0.0, 1.0, 0.0, 1.0, 2.0],
            [0.0, 1.0, 1.0, 0.0, 0.5, 1.0],
            [0.0, 1.0, 1.0, 3.0, 0.0, 0.0],
        )
        for inputs in malformed:
            add_polynomial_case(inputs)
        duplicate_x = [1.0, 2.0, 1.0, 0.0, 0.0, 1.0, 2.0, 2.0]
        add_polynomial_case(duplicate_x, output_is_null=True)
        add_polynomial_case([], input_is_null=True, input_length=5)

    if algorithm == "soboleva_modified_hyperbolic_tangent":
        if (workspace != 32 or absolute_tolerance != 1e-12 or relative_tolerance != 1e-12):
            raise ValueError("soboleva_modified_hyperbolic_tangent requires a 32-element workspace and 1e-12 tolerances")
        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float)
                           or not math.isfinite(float(value)) for value in raw_values)):
                raise ValueError(f"soboleva_modified_hyperbolic_tangent ABI values are invalid: {case.get('id')}")
            values = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(values))
            if (type(capacity) is not int or not 0 <= capacity <= workspace
                    or type(input_is_null) is not bool or type(output_is_null) is not bool
                    or type(input_length) is not int or not 0 <= input_length <= 38
                    or input_is_null and values
                    or not input_is_null and input_length != len(values)
                       and case.get("id") != "input_length_mismatch"):
                raise ValueError(f"soboleva_modified_hyperbolic_tangent ABI framing is invalid: {case.get('id')}")
            result, output = soboleva_modified_hyperbolic_tangent_abi_oracle(
                values, capacity, output_is_null, input_is_null, input_length)
            if (case.get("expected_result") != result
                    or not _matches_output(case.get("expected_output"), output,
                                           absolute_tolerance, relative_tolerance)):
                raise ValueError(f"soboleva_modified_hyperbolic_tangent ABI fixture mismatch: {case.get('id')}")
            if input_is_null:
                checker_values = [0.0] * input_length
            elif case.get("id") == "input_length_mismatch":
                checker_values = values[:input_length]
            else:
                checker_values = values
            records.append((checker_values, result, [_output_token(value) for value in output],
                            capacity, int(input_is_null), int(output_is_null)))

        rng_soboleva = random.Random(20261017)
        for _ in range(96):
            count = rng_soboleva.randint(1, 32)
            coefficients = [rng_soboleva.uniform(-2.0, 2.0) for _ in range(4)]
            samples = [rng_soboleva.uniform(-20.0, 20.0) for _ in range(count)]
            inputs = [float(count), *coefficients, *samples]
            output = ORACLES[algorithm](inputs)
            if output is None or len(output) != count:
                raise ValueError("soboleva_modified_hyperbolic_tangent oracle rejected a generated valid trace")
            records.append((inputs, count, [_output_token(value) for value in output], workspace, 0, 0))

        finite_base = [1.0, 1.0, 1.0, 1.0, 1.0, 0.0]
        for index in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[index] = special
                result, output = soboleva_modified_hyperbolic_tangent_abi_oracle(inputs)
                if result != SOBOLEVA_MODIFIED_HYPERBOLIC_TANGENT_INVALID_RESULT or output:
                    raise ValueError("soboleva_modified_hyperbolic_tangent accepted a non-finite value")
                records.append((inputs, -1, [], workspace, 0, 0))

    if algorithm == "pi_monte_carlo_estimation":
        oracle = ORACLES[algorithm]
        rng_pi = random.Random(20261017)
        for _ in range(96):
            simulations = rng_pi.randint(1, 4096)
            seed = rng_pi.getrandbits(32)
            inputs = [float(simulations), float(seed)]
            output = oracle(inputs)
            if output is None or len(output) != 1:
                raise ValueError("pi_monte_carlo_estimation oracle rejected a generated valid trace")
            records.append((inputs, 1, [_output_token(value) for value in output],
                            workspace, 0, 0))
        for special in (math.nan, math.inf, -math.inf):
            for index, inputs in (
                (0, [100.0, 1.0]),
                (1, [100.0, 1.0]),
            ):
                inputs[index] = special
                if oracle(inputs) is not None:
                    raise ValueError("pi_monte_carlo_estimation oracle accepted a non-finite input")
                records.append((inputs, -1, [], workspace, 0, 0))
                records.append((inputs, -1, [], workspace, 0, 1))

    if algorithm == "momentum_sgd":
        oracle = momentum_sgd_abi_oracle

        def add_momentum_case(inputs: list[float], capacity: int = workspace,
                              output_is_null: bool = False, input_is_null: bool = False,
                              input_length: int | None = None) -> tuple[int, list[float]]:
            if input_length is None:
                input_length = len(inputs)
            if input_is_null:
                result, output = oracle([], capacity, output_is_null, True, input_length)
                checker_inputs = [0.0] * input_length
            else:
                result, output = oracle(inputs, capacity, output_is_null, False, input_length)
                checker_inputs = inputs
            records.append((checker_inputs, result,
                            [_output_token(value) for value in output], capacity,
                            int(input_is_null), int(output_is_null)))
            return result, output

        for case in workload.get("abi_cases", []):
            raw_values = case.get("input_values")
            if (not isinstance(raw_values, list)
                    or any(type(value) not in (int, float) or not math.isfinite(float(value))
                           for value in raw_values)):
                raise ValueError(f"invalid momentum_sgd ABI input values: {case.get('id')}")
            inputs = [float(value) for value in raw_values]
            capacity = case.get("output_capacity")
            output_is_null = case.get("output_is_null")
            input_is_null = case.get("input_is_null")
            input_length = case.get("input_length")
            result, output = oracle(inputs, capacity, output_is_null, input_is_null, input_length)
            expected_output = case.get("expected_output")
            if (case.get("expected_result") != result
                    or not isinstance(expected_output, list)
                    or len(expected_output) != len(output)
                    or any(type(actual) not in (int, float)
                           or not math.isfinite(float(actual))
                           or abs(float(actual) - reference)
                           > absolute_tolerance + relative_tolerance * abs(reference)
                           for actual, reference in zip(expected_output, output))):
                raise ValueError(f"momentum_sgd ABI workload mismatch: {case.get('id')}")
            add_momentum_case(inputs, capacity, output_is_null, input_is_null, input_length)

        rng_momentum = random.Random(20261017)
        for index in range(96):
            group_count = rng_momentum.randint(
                MOMENTUM_SGD_MIN_GROUP_COUNT, MOMENTUM_SGD_MAX_GROUP_COUNT)
            vector_length = rng_momentum.randint(
                MOMENTUM_SGD_MIN_VECTOR_LENGTH,
                min(MOMENTUM_SGD_MAX_VECTOR_LENGTH,
                    MOMENTUM_SGD_MAX_GROUP_VECTOR_ELEMENTS // group_count))
            call_count = rng_momentum.randint(
                max(group_count, MOMENTUM_SGD_MIN_CALL_COUNT), MOMENTUM_SGD_MAX_CALL_COUNT)
            event_ids = list(range(group_count))
            event_ids.extend(rng_momentum.randrange(group_count)
                             for _ in range(call_count - group_count))
            rng_momentum.shuffle(event_ids)
            inputs = [float(group_count), float(vector_length), float(call_count),
                      rng_momentum.uniform(MOMENTUM_SGD_MIN_LEARNING_RATE,
                                           MOMENTUM_SGD_MAX_LEARNING_RATE),
                      rng_momentum.uniform(MOMENTUM_SGD_MIN_MOMENTUM,
                                           MOMENTUM_SGD_MAX_MOMENTUM)]
            for param_id in event_ids:
                inputs.append(float(param_id))
                inputs.extend(rng_momentum.uniform(MOMENTUM_SGD_MIN_PARAMETER,
                                                   MOMENTUM_SGD_MAX_PARAMETER)
                              for _ in range(vector_length))
                inputs.extend(rng_momentum.uniform(MOMENTUM_SGD_MIN_GRADIENT,
                                                   MOMENTUM_SGD_MAX_GRADIENT)
                              for _ in range(vector_length))
            result, output = add_momentum_case(inputs)
            if result <= 0 or len(output) != result:
                raise ValueError("momentum_sgd oracle rejected a generated valid multi-ID trace")
            if index % 16 == 0:
                add_momentum_case(inputs, output_is_null=True)

        finite_base = [1.0, 1.0, 1.0, 0.1, 0.9, 0.0, 1.0, 0.1]
        for position in range(len(finite_base)):
            for special in (math.nan, math.inf, -math.inf):
                inputs = list(finite_base)
                inputs[position] = special
                result, output = oracle(inputs)
                if result != -1 or output:
                    raise ValueError("momentum_sgd oracle accepted a non-finite input")
                add_momentum_case(inputs)
                if position == 3:
                    add_momentum_case(inputs, output_is_null=True)

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
                    absolute_tolerance: float, relative_tolerance: float,
                    *, preserve_signed_zero: bool = False) -> bool:
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
        if (preserve_signed_zero and target == 0.0 and float(actual) == 0.0
                and absolute_tolerance == 0.0 and relative_tolerance == 0.0
                and math.copysign(1.0, float(actual)) != math.copysign(1.0, target)):
            return False
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
                                       absolute_tolerance, relative_tolerance,
                                       preserve_signed_zero=algorithm in {
                                           "median_of_running_array_double",
                                           "median_of_running_array_float",
                                           "mean_shift"})
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
    elif algorithm == "rmsprop":
        validate_rmsprop_workload(workload)
    elif algorithm == "k_means_clust":
        validate_k_means_clust_workload(workload)
    elif algorithm == "lu_decompose":
        validate_lu_decompose_workload(workload)
    elif algorithm == "sherman_morrison":
        validate_sherman_morrison_workload(workload)
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
