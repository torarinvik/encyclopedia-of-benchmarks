#!/usr/bin/env python3
"""Record float64 slice-to-slice C ABI benchmark workloads."""

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
from vector3_axis_rotation_oracle import expected_result as vector3_axis_rotation_oracle
from vector3_perspective_projection_oracle import expected_result as vector3_perspective_projection_oracle
from vector2_oracle import expected_result as vector2_oracle
from vectors_3d_oracle import expected_result as vectors_3d_oracle
from dimensionality_reduction_pca_oracle import expected_result as dimensionality_reduction_pca_oracle
from dimensionality_reduction_lda_oracle import expected_result as dimensionality_reduction_lda_oracle
from dimensionality_reduction_tsne_oracle import expected_result as dimensionality_reduction_tsne_oracle
from fresnel_diffract_oracle import expected_result as fresnel_diffract_oracle
from gauss_optimization_oracle import expected_result as gauss_optimization_oracle
from geo_location_oracle import expected_result as geo_location_oracle
from gravitational_force_oracle import expected_result as gravitational_force_oracle
from circular_orbit_velocity_oracle import expected_result as circular_orbit_velocity_oracle
from momentum_oracle import expected_result as momentum_oracle
from joint_probability_distribution_oracle import (
    INVALID_RESULT as JOINT_PROBABILITY_DISTRIBUTION_INVALID_RESULT,
    MAX_INPUT_LENGTH as MAX_JOINT_PROBABILITY_DISTRIBUTION_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS as MAX_JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as MAX_JOINT_PROBABILITY_DISTRIBUTION_PARSEABLE_INPUT_LENGTH,
    MAX_SUPPORT_LENGTH as MAX_JOINT_PROBABILITY_DISTRIBUTION_SUPPORT_LENGTH,
    OUTPUT_ERROR as JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ERROR,
    expected_output as joint_probability_distribution_oracle,
)
from shreedharacharya_oracle import INVALID_RESULT as SHREEDHARACHARYA_INVALID_RESULT
from shreedharacharya_oracle import MAX_COEFFICIENT as SHREEDHARACHARYA_MAX_COEFFICIENT
from shreedharacharya_oracle import MAX_INPUT_LENGTH as MAX_SHREEDHARACHARYA_INPUT_LENGTH
from shreedharacharya_oracle import MAX_OUTPUT_ELEMENTS as MAX_SHREEDHARACHARYA_OUTPUT_ELEMENTS
from shreedharacharya_oracle import MIN_ABS_LEADING_COEFFICIENT as SHREEDHARACHARYA_MIN_ABS_A
from shreedharacharya_oracle import OUTPUT_ERROR as SHREEDHARACHARYA_OUTPUT_ERROR
from shreedharacharya_oracle import expected_output as shreedharacharya_oracle
from rotation_matrix_oracle import INVALID_RESULT as ROTATION_MATRIX_INVALID_RESULT
from rotation_matrix_oracle import MAX_ANGLE as ROTATION_MATRIX_MAX_ANGLE
from rotation_matrix_oracle import MAX_INPUT_LENGTH as ROTATION_MATRIX_MAX_INPUT_LENGTH
from rotation_matrix_oracle import MAX_OUTPUT_ELEMENTS as ROTATION_MATRIX_MAX_OUTPUT_ELEMENTS
from rotation_matrix_oracle import MAX_PARSEABLE_INPUT_LENGTH as ROTATION_MATRIX_MAX_PARSEABLE_INPUT_LENGTH
from rotation_matrix_oracle import OUTPUT_ERROR as ROTATION_MATRIX_OUTPUT_ERROR
from rotation_matrix_oracle import expected_output as rotation_matrix_oracle
from simple_pendulum_rk4_oracle import INVALID_RESULT as SIMPLE_PENDULUM_RK4_INVALID_RESULT
from simple_pendulum_rk4_oracle import INPUT_LENGTH as SIMPLE_PENDULUM_RK4_INPUT_LENGTH
from simple_pendulum_rk4_oracle import MAX_PARSEABLE_INPUT_LENGTH as SIMPLE_PENDULUM_RK4_MAX_PARSEABLE_INPUT_LENGTH
from simple_pendulum_rk4_oracle import OUTPUT_ERROR as SIMPLE_PENDULUM_RK4_OUTPUT_ERROR
from simple_pendulum_rk4_oracle import MAX_OUTPUT_ELEMENTS as SIMPLE_PENDULUM_RK4_MAX_OUTPUT_ELEMENTS
from simple_pendulum_rk4_oracle import SCALE as SIMPLE_PENDULUM_RK4_SCALE
from simple_pendulum_rk4_oracle import expected_result as simple_pendulum_rk4_oracle
from piecewise_without_inbuilt_oracle import INPUT_LENGTH as PIECEWISE_WITHOUT_INBUILT_INPUT_LENGTH
from piecewise_without_inbuilt_oracle import INVALID_RESULT as PIECEWISE_WITHOUT_INBUILT_INVALID_RESULT
from piecewise_without_inbuilt_oracle import MAX_PARSEABLE_INPUT_LENGTH as PIECEWISE_WITHOUT_INBUILT_MAX_PARSEABLE_INPUT_LENGTH
from piecewise_without_inbuilt_oracle import MAX_X as PIECEWISE_WITHOUT_INBUILT_MAX_X
from piecewise_without_inbuilt_oracle import MIN_X as PIECEWISE_WITHOUT_INBUILT_MIN_X
from piecewise_without_inbuilt_oracle import OUTPUT_ERROR as PIECEWISE_WITHOUT_INBUILT_OUTPUT_ERROR
from piecewise_without_inbuilt_oracle import MAX_OUTPUT_ELEMENTS as PIECEWISE_WITHOUT_INBUILT_MAX_OUTPUT_ELEMENTS
from piecewise_without_inbuilt_oracle import expected_result as piecewise_without_inbuilt_oracle
from pid_oracle import MAX_ERROR_COUNT as PID_MAX_ERROR_COUNT
from pid_oracle import MAX_INPUT_LENGTH as MAX_PID_INPUT_LENGTH
from pid_oracle import MIN_ERROR_COUNT as PID_MIN_ERROR_COUNT
from pid_oracle import expected_output as pid_oracle
from projectile_motion_oracle import expected_result as projectile_motion_oracle
from radar_target_calculation_oracle import expected_result as radar_target_calculation_oracle
from rayleigh_quotient_oracle import expected_result as rayleigh_quotient_oracle
from softmax_oracle import expected_result as softmax_oracle
from trig_functions_oracle import expected_result as trig_functions_oracle
from verlet_oracle import expected_result as verlet_oracle
from koch_snowflake_oracle import MAX_COORDINATE as KOCH_SNOWFLAKE_MAX_COORDINATE
from koch_snowflake_oracle import MAX_OUTPUT_ELEMENTS as KOCH_SNOWFLAKE_MAX_OUTPUT_ELEMENTS
from koch_snowflake_oracle import MAX_PARSEABLE_INPUT_LENGTH as KOCH_SNOWFLAKE_MAX_PARSEABLE_INPUT_LENGTH
from koch_snowflake_oracle import MAX_POINT_COUNT as KOCH_SNOWFLAKE_MAX_POINT_COUNT
from koch_snowflake_oracle import MAX_STEPS as KOCH_SNOWFLAKE_MAX_STEPS
from koch_snowflake_oracle import MAX_VALID_INPUT_LENGTH as KOCH_SNOWFLAKE_MAX_VALID_INPUT_LENGTH
from koch_snowflake_oracle import MIN_POINT_COUNT as KOCH_SNOWFLAKE_MIN_POINT_COUNT
from koch_snowflake_oracle import MIN_STEPS as KOCH_SNOWFLAKE_MIN_STEPS
from koch_snowflake_oracle import expected_result as koch_snowflake_oracle
from k_d_tree_oracle import INVALID_RESULT as K_D_TREE_INVALID_RESULT
from k_d_tree_oracle import MAX_COORDINATE as K_D_TREE_MAX_COORDINATE
from k_d_tree_oracle import MAX_DIMENSION as K_D_TREE_MAX_DIMENSION
from k_d_tree_oracle import MAX_INPUT_LENGTH as K_D_TREE_MAX_INPUT_LENGTH
from k_d_tree_oracle import MAX_OUTPUT_ELEMENTS as K_D_TREE_MAX_OUTPUT_ELEMENTS
from k_d_tree_oracle import MAX_POINT_COUNT as K_D_TREE_MAX_POINT_COUNT
from k_d_tree_oracle import MAX_VALID_INPUT_LENGTH as K_D_TREE_MAX_VALID_INPUT_LENGTH
from k_d_tree_oracle import MIN_COORDINATE as K_D_TREE_MIN_COORDINATE
from k_d_tree_oracle import MIN_DIMENSION as K_D_TREE_MIN_DIMENSION
from k_d_tree_oracle import MIN_POINT_COUNT as K_D_TREE_MIN_POINT_COUNT
from k_d_tree_oracle import OUTPUT_ERROR as K_D_TREE_OUTPUT_ERROR
from k_d_tree_oracle import expected_output as k_d_tree_oracle
from linear_regression_vectorized_oracle import ABSOLUTE_TOLERANCE as LINEAR_REGRESSION_ABSOLUTE_TOLERANCE
from linear_regression_vectorized_oracle import MAX_ALPHA as LINEAR_REGRESSION_MAX_ALPHA
from linear_regression_vectorized_oracle import MAX_FEATURE_COUNT as LINEAR_REGRESSION_MAX_FEATURE_COUNT
from linear_regression_vectorized_oracle import MAX_FEATURE_OR_LABEL as LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL
from linear_regression_vectorized_oracle import MAX_INPUT_LENGTH as LINEAR_REGRESSION_MAX_INPUT_LENGTH
from linear_regression_vectorized_oracle import MAX_ITERATIONS as LINEAR_REGRESSION_MAX_ITERATIONS
from linear_regression_vectorized_oracle import MAX_OUTPUT_ELEMENTS as LINEAR_REGRESSION_MAX_OUTPUT_ELEMENTS
from linear_regression_vectorized_oracle import MAX_SAMPLE_COUNT as LINEAR_REGRESSION_MAX_SAMPLE_COUNT
from linear_regression_vectorized_oracle import MIN_ALPHA as LINEAR_REGRESSION_MIN_ALPHA
from linear_regression_vectorized_oracle import MIN_FEATURE_COUNT as LINEAR_REGRESSION_MIN_FEATURE_COUNT
from linear_regression_vectorized_oracle import MIN_FEATURE_OR_LABEL as LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL
from linear_regression_vectorized_oracle import MIN_ITERATIONS as LINEAR_REGRESSION_MIN_ITERATIONS
from linear_regression_vectorized_oracle import MIN_SAMPLE_COUNT as LINEAR_REGRESSION_MIN_SAMPLE_COUNT
from linear_regression_vectorized_oracle import MAX_PARSEABLE_INPUT_LENGTH as LINEAR_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH
from linear_regression_vectorized_oracle import RELATIVE_TOLERANCE as LINEAR_REGRESSION_RELATIVE_TOLERANCE
from linear_regression_vectorized_oracle import expected_result as linear_regression_vectorized_oracle
from perlin_noise_oracle import (
    INVALID_RESULT as PERLIN_NOISE_INVALID_RESULT,
    MAX_DIMENSION as PERLIN_NOISE_MAX_DIMENSION,
    MAX_INPUT_ELEMENTS as PERLIN_NOISE_MAX_INPUT_ELEMENTS,
    MAX_OCTAVES as PERLIN_NOISE_MAX_OCTAVES,
    MAX_OUTPUT_ELEMENTS as PERLIN_NOISE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_ELEMENTS as PERLIN_NOISE_MAX_PARSEABLE_INPUT_ELEMENTS,
    MAX_SEED as PERLIN_NOISE_MAX_SEED,
    MIN_DIMENSION as PERLIN_NOISE_MIN_DIMENSION,
    MIN_OCTAVES as PERLIN_NOISE_MIN_OCTAVES,
    MIN_SEED as PERLIN_NOISE_MIN_SEED,
    OUTPUT_ERROR as PERLIN_NOISE_OUTPUT_ERROR,
    PERSISTENCE_VALUES as PERLIN_NOISE_PERSISTENCE_VALUES,
    expected_result as perlin_noise_oracle,
)
from md2_digest_oracle import MAX_INPUT_LENGTH as MD2_DIGEST_MAX_INPUT_LENGTH
from md2_digest_oracle import expected_result as md2_digest_oracle
from median_filter_oracle import MAX_INPUT_LENGTH as MEDIAN_FILTER_MAX_INPUT_LENGTH
from median_filter_oracle import expected_result as median_filter_oracle
from mutate_oracle import MAX_INPUT_LENGTH as MUTATE_MAX_INPUT_LENGTH
from mutate_oracle import expected_result as mutate_oracle
from single_point_crossover_oracle import INVALID_RESULT as SINGLE_POINT_CROSSOVER_INVALID_RESULT
from single_point_crossover_oracle import MAX_INPUT_LENGTH as SINGLE_POINT_CROSSOVER_MAX_INPUT_LENGTH
from single_point_crossover_oracle import MAX_OUTPUT_ELEMENTS as SINGLE_POINT_CROSSOVER_MAX_OUTPUT_ELEMENTS
from single_point_crossover_oracle import MAX_VALID_INPUT_LENGTH as SINGLE_POINT_CROSSOVER_MAX_VALID_INPUT_LENGTH
from single_point_crossover_oracle import MIN_PARENT_LENGTH as SINGLE_POINT_CROSSOVER_MIN_PARENT_LENGTH
from single_point_crossover_oracle import OUTPUT_ERROR as SINGLE_POINT_CROSSOVER_OUTPUT_ERROR
from single_point_crossover_oracle import expected_abi_result as single_point_crossover_expected_abi_result
from single_point_crossover_oracle import expected_output as single_point_crossover_oracle
from quaternions_oracle import ABSOLUTE_TOLERANCE as QUATERNIONS_ABSOLUTE_TOLERANCE
from quaternions_oracle import INVALID_RESULT as QUATERNIONS_INVALID_RESULT
from quaternions_oracle import MAX_INPUT_LENGTH as QUATERNIONS_MAX_INPUT_LENGTH
from quaternions_oracle import MAX_OUTPUT_ELEMENTS as QUATERNIONS_MAX_OUTPUT_ELEMENTS
from quaternions_oracle import NORMALIZATION_TOLERANCE as QUATERNIONS_NORMALIZATION_TOLERANCE
from quaternions_oracle import OUTPUT_ERROR as QUATERNIONS_OUTPUT_ERROR
from quaternions_oracle import RELATIVE_TOLERANCE as QUATERNIONS_RELATIVE_TOLERANCE
from quaternions_oracle import expected_abi_result as quaternions_expected_abi_result
from quaternions_oracle import expected_output as quaternions_oracle
from rhumb_distance_oracle import EARTH_RADIUS as RHUMB_DISTANCE_EARTH_RADIUS
from rhumb_distance_oracle import INVALID_RESULT as RHUMB_DISTANCE_INVALID_RESULT
from rhumb_distance_oracle import MAX_INPUT_LENGTH as RHUMB_DISTANCE_MAX_INPUT_LENGTH
from rhumb_distance_oracle import MAX_LATITUDE as RHUMB_DISTANCE_MAX_LATITUDE
from rhumb_distance_oracle import MAX_LONGITUDE as RHUMB_DISTANCE_MAX_LONGITUDE
from rhumb_distance_oracle import MAX_OUTPUT_ELEMENTS as RHUMB_DISTANCE_MAX_OUTPUT_ELEMENTS
from rhumb_distance_oracle import MAX_PARSEABLE_INPUT_LENGTH as RHUMB_DISTANCE_MAX_PARSEABLE_INPUT_LENGTH
from rhumb_distance_oracle import MIN_LATITUDE as RHUMB_DISTANCE_MIN_LATITUDE
from rhumb_distance_oracle import MIN_LONGITUDE as RHUMB_DISTANCE_MIN_LONGITUDE
from rhumb_distance_oracle import OUTPUT_ERROR as RHUMB_DISTANCE_OUTPUT_ERROR
from rhumb_distance_oracle import expected_output as rhumb_distance_oracle
from rhumb_bearing_oracle import INVALID_RESULT as RHUMB_BEARING_INVALID_RESULT
from rhumb_bearing_oracle import MAX_INPUT_LENGTH as RHUMB_BEARING_MAX_INPUT_LENGTH
from rhumb_bearing_oracle import MAX_LATITUDE as RHUMB_BEARING_MAX_LATITUDE
from rhumb_bearing_oracle import MAX_LONGITUDE as RHUMB_BEARING_MAX_LONGITUDE
from rhumb_bearing_oracle import MAX_OUTPUT_ELEMENTS as RHUMB_BEARING_MAX_OUTPUT_ELEMENTS
from rhumb_bearing_oracle import MAX_PARSEABLE_INPUT_LENGTH as RHUMB_BEARING_MAX_PARSEABLE_INPUT_LENGTH
from rhumb_bearing_oracle import MIN_LATITUDE as RHUMB_BEARING_MIN_LATITUDE
from rhumb_bearing_oracle import MIN_LONGITUDE as RHUMB_BEARING_MIN_LONGITUDE
from rhumb_bearing_oracle import OUTPUT_ERROR as RHUMB_BEARING_OUTPUT_ERROR
from rhumb_bearing_oracle import expected_output as rhumb_bearing_oracle
from rhumb_destination_oracle import EARTH_RADIUS as RHUMB_DESTINATION_EARTH_RADIUS
from rhumb_destination_oracle import INVALID_RESULT as RHUMB_DESTINATION_INVALID_RESULT
from rhumb_destination_oracle import MAX_BEARING as RHUMB_DESTINATION_MAX_BEARING
from rhumb_destination_oracle import MAX_DISTANCE as RHUMB_DESTINATION_MAX_DISTANCE
from rhumb_destination_oracle import MAX_INPUT_LENGTH as RHUMB_DESTINATION_MAX_INPUT_LENGTH
from rhumb_destination_oracle import MAX_LATITUDE as RHUMB_DESTINATION_MAX_LATITUDE
from rhumb_destination_oracle import MAX_LONGITUDE as RHUMB_DESTINATION_MAX_LONGITUDE
from rhumb_destination_oracle import MAX_OUTPUT_ELEMENTS as RHUMB_DESTINATION_MAX_OUTPUT_ELEMENTS
from rhumb_destination_oracle import MAX_PARSEABLE_INPUT_LENGTH as RHUMB_DESTINATION_MAX_PARSEABLE_INPUT_LENGTH
from rhumb_destination_oracle import MIN_BEARING as RHUMB_DESTINATION_MIN_BEARING
from rhumb_destination_oracle import MIN_DISTANCE as RHUMB_DESTINATION_MIN_DISTANCE
from rhumb_destination_oracle import MIN_LATITUDE as RHUMB_DESTINATION_MIN_LATITUDE
from rhumb_destination_oracle import MIN_LONGITUDE as RHUMB_DESTINATION_MIN_LONGITUDE
from rhumb_destination_oracle import OUTPUT_ERROR as RHUMB_DESTINATION_OUTPUT_ERROR
from rhumb_destination_oracle import expected_output as rhumb_destination_oracle
from median_of_running_array_double_oracle import (
    INVALID_RESULT as MEDIAN_RUNNING_DOUBLE_INVALID_RESULT,
    MAX_SAMPLE as MEDIAN_RUNNING_DOUBLE_MAX_SAMPLE,
    MAX_SAMPLE_COUNT as MEDIAN_RUNNING_DOUBLE_MAX_SAMPLE_COUNT,
    MAX_OUTPUT_ELEMENTS as MEDIAN_RUNNING_DOUBLE_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as MEDIAN_RUNNING_DOUBLE_MAX_PARSEABLE_INPUT_LENGTH,
    MIN_SAMPLE as MEDIAN_RUNNING_DOUBLE_MIN_SAMPLE,
    MIN_SAMPLE_COUNT as MEDIAN_RUNNING_DOUBLE_MIN_SAMPLE_COUNT,
    OUTPUT_ERROR as MEDIAN_RUNNING_DOUBLE_OUTPUT_ERROR,
    expected_output as median_of_running_array_double_oracle,
)
from median_of_running_array_float_oracle import (
    INVALID_RESULT as MEDIAN_RUNNING_FLOAT_INVALID_RESULT,
    MAX_SAMPLE as MEDIAN_RUNNING_FLOAT_MAX_SAMPLE,
    MAX_SAMPLE_COUNT as MEDIAN_RUNNING_FLOAT_MAX_SAMPLE_COUNT,
    MAX_OUTPUT_ELEMENTS as MEDIAN_RUNNING_FLOAT_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as MEDIAN_RUNNING_FLOAT_MAX_PARSEABLE_INPUT_LENGTH,
    MIN_SAMPLE as MEDIAN_RUNNING_FLOAT_MIN_SAMPLE,
    MIN_SAMPLE_COUNT as MEDIAN_RUNNING_FLOAT_MIN_SAMPLE_COUNT,
    OUTPUT_ERROR as MEDIAN_RUNNING_FLOAT_OUTPUT_ERROR,
    expected_output as median_of_running_array_float_oracle,
)
from mean_shift_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH as MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as MEAN_SHIFT_MAX_VALID_INPUT_LENGTH,
    WORKSPACE_ELEMENTS as MEAN_SHIFT_WORKSPACE_ELEMENTS,
    expected_output as mean_shift_oracle,
)
from pi_monte_carlo_estimation_oracle import (
    ABSOLUTE_TOLERANCE as PI_MONTE_CARLO_ABSOLUTE_TOLERANCE,
    INVALID_RESULT as PI_MONTE_CARLO_INVALID_RESULT,
    MAX_INPUT_LENGTH as PI_MONTE_CARLO_MAX_INPUT_LENGTH,
    MAX_OUTPUT_ELEMENTS as PI_MONTE_CARLO_MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH as PI_MONTE_CARLO_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_SEED as PI_MONTE_CARLO_MAX_SEED,
    MAX_SIMULATIONS as PI_MONTE_CARLO_MAX_SIMULATIONS,
    MIN_SEED as PI_MONTE_CARLO_MIN_SEED,
    MIN_SIMULATIONS as PI_MONTE_CARLO_MIN_SIMULATIONS,
    OUTPUT_ERROR as PI_MONTE_CARLO_OUTPUT_ERROR,
    RELATIVE_TOLERANCE as PI_MONTE_CARLO_RELATIVE_TOLERANCE,
    expected_result as pi_monte_carlo_estimation_oracle,
)

ORACLES = {
    "vector3_axis_rotation": vector3_axis_rotation_oracle,
    "vector3_perspective_projection": vector3_perspective_projection_oracle,
    "vector2": vector2_oracle,
    "vectors_3d": vectors_3d_oracle,
    "dimensionality_reduction_pca": dimensionality_reduction_pca_oracle,
    "dimensionality_reduction_lda": dimensionality_reduction_lda_oracle,
    "dimensionality_reduction_tsne": dimensionality_reduction_tsne_oracle,
    "fresnel_diffract": fresnel_diffract_oracle,
    "gauss_optimization": gauss_optimization_oracle,
    "geo_location": geo_location_oracle,
    "gravitational_force": gravitational_force_oracle,
    "circular_orbit_velocity": circular_orbit_velocity_oracle,
    "momentum": momentum_oracle,
    "joint_probability_distribution": joint_probability_distribution_oracle,
    "shreedharacharya": shreedharacharya_oracle,
    "rotation_matrix": rotation_matrix_oracle,
    "simple_pendulum_rk4": simple_pendulum_rk4_oracle,
    "piecewise_without_inbuilt": piecewise_without_inbuilt_oracle,
    "pid": pid_oracle,
    "projectile_motion": projectile_motion_oracle,
    "radar_target_calculation": radar_target_calculation_oracle,
    "rayleigh_quotient": rayleigh_quotient_oracle,
    "softmax": softmax_oracle,
    "trig_functions": trig_functions_oracle,
    "verlet": verlet_oracle,
    "koch_snowflake": koch_snowflake_oracle,
    "k_d_tree": k_d_tree_oracle,
    "linear_regression_vectorized": linear_regression_vectorized_oracle,
    "perlin_noise": perlin_noise_oracle,
    "md2_digest": md2_digest_oracle,
    "median_filter": median_filter_oracle,
    "mutate": mutate_oracle,
    "single_point_crossover": single_point_crossover_oracle,
    "quaternions": quaternions_oracle,
    "rhumb_distance": rhumb_distance_oracle,
    "rhumb_bearing": rhumb_bearing_oracle,
    "rhumb_destination": rhumb_destination_oracle,
    "median_of_running_array_double": median_of_running_array_double_oracle,
    "median_of_running_array_float": median_of_running_array_float_oracle,
    "mean_shift": mean_shift_oracle,
    "pi_monte_carlo_estimation": pi_monte_carlo_estimation_oracle,
}
MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH = 1 + 16 * 16 + 16

LINEAR_REGRESSION_CASE_IDS = frozenset({
    "two_samples_exact_linear_relation", "minimum_learning_rate_and_iterations",
    "maximum_learning_rate_and_iterations", "three_features_with_mixed_signs",
    "four_features_two_samples", "eight_samples_four_features", "zero_targets_keep_zero_theta",
    "zero_nonintercept_feature_column", "intercept_only_signal_with_feature_noise",
    "boundary_feature_and_label_values", "collinear_feature_columns",
    "small_step_for_many_iterations", "large_step_for_minimum_iteration_count",
    "maximum_sample_count_two_features", "maximum_feature_count_and_sample_count",
    "fractional_sample_count", "sample_count_below_bound", "sample_count_above_bound",
    "fractional_feature_count", "feature_count_below_bound", "feature_count_above_bound",
    "fractional_iteration_count", "iteration_count_below_bound", "iteration_count_above_bound",
    "learning_rate_below_bound", "learning_rate_above_bound", "intercept_column_not_one",
    "feature_value_above_bound", "feature_value_below_bound", "label_above_bound",
    "label_below_bound", "truncated_feature_matrix", "truncated_label_vector",
    "trailing_input_value", "maximum_parseable_length_invalid",
})


ROTATION_MATRIX_CASE_IDS = {
    "zero_angle_identity", "positive_quarter_turn", "negative_quarter_turn", "half_turn",
    "full_turn", "positive_eighth_turn", "negative_eighth_turn", "positive_one_third_turn",
    "negative_one_third_turn", "fractional_radian", "negative_fractional_radian",
    "large_positive_angle", "large_negative_angle", "upper_angle_boundary",
    "lower_angle_boundary", "angle_above_boundary", "angle_below_boundary", "extra_input_value",
}


def validate_rotation_matrix_workload(workload: dict) -> None:
    """Pin the Julia rotation matrix package and its bounded float64 slice ABI."""
    source = {
        "repository": "TheAlgorithms/Julia",
        "commit": "384424b762bbb40d43f31001beeca0c6ffda2f1f",
        "path": "src/matrix/rotation_matrix.jl",
        "symbol": "rotation_matrix",
        "url": "https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/matrix/rotation_matrix.jl",
        "role": "algorithm",
    }
    contract = {
        "operation": "construct the 2D counterclockwise rotation matrix from an angle in radians",
        "formula": "[cos(theta), -sin(theta), sin(theta), cos(theta)]",
        "output_order": "row-major",
        "angle_normalization": "none",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[theta] in radians",
        "valid_length_range": [1, 1],
        "maximum_valid_length": ROTATION_MATRIX_MAX_INPUT_LENGTH,
        "maximum_parseable_length": ROTATION_MATRIX_MAX_PARSEABLE_INPUT_LENGTH,
        "angle_range": [-ROTATION_MATRIX_MAX_ANGLE, ROTATION_MATRIX_MAX_ANGLE],
        "invalid_input_result": ROTATION_MATRIX_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "row-major [cos(theta),-sin(theta),sin(theta),cos(theta)]",
        "maximum_elements": ROTATION_MATRIX_MAX_OUTPUT_ELEMENTS,
        "success_result": "number of output float64 elements (4)",
        "invalid_input_result": ROTATION_MATRIX_INVALID_RESULT,
        "invalid_output_buffer_result": ROTATION_MATRIX_OUTPUT_ERROR,
        "null_output_result": ROTATION_MATRIX_OUTPUT_ERROR,
        "no_write_on_error": True,
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    workspace = {
        "elements": ROTATION_MATRIX_MAX_OUTPUT_ELEMENTS,
        "meaning": "Four row-major elements of the 2x2 matrix.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    cases = workload.get("cases")
    cases = cases if isinstance(cases, list) else []
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "rotation-matrix-julia-f64-slice-io-v1"
            or workload.get("algorithm") != "rotation_matrix"
            or workload.get("function_symbol") != "rotation_matrix"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or ROTATION_MATRIX_MAX_INPUT_LENGTH != 1
            or ROTATION_MATRIX_MAX_PARSEABLE_INPUT_LENGTH != 64
            or ROTATION_MATRIX_MAX_ANGLE != 1000.0
            or ROTATION_MATRIX_MAX_OUTPUT_ELEMENTS != 4
            or len(ids) != len(ROTATION_MATRIX_CASE_IDS)
            or len(ids) != len(set(ids))
            or set(ids) != ROTATION_MATRIX_CASE_IDS):
        raise ValueError("rotation_matrix workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "r" / "rotation_matrix" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme:
        raise ValueError("rotation_matrix README is missing its pinned source link")
    for case in cases:
        values = case.get("input_values")
        if (not isinstance(values, list)
                or case.get("input_length") != len(values)
                or not values
                or len(values) > ROTATION_MATRIX_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       for value in values)):
            raise ValueError(f"rotation_matrix input framing is invalid for {case.get('id')}")
        expected_result, expected_output = rotation_matrix_oracle(values)
        raw_output = case.get("expected_output")
        if (case.get("expected_result") != expected_result
                or not isinstance(raw_output, list)
                or len(raw_output) != len(expected_output)
                or any(type(actual) not in (int, float)
                       or not math.isfinite(float(actual))
                       or abs(float(actual) - expected)
                       > 1e-12 + 1e-12 * abs(expected)
                       for actual, expected in zip(raw_output, expected_output))):
            raise ValueError(f"rotation_matrix workload mismatch: {case.get('id')}")


KOCH_SNOWFLAKE_CASE_IDS = {
    "zero_steps_preserves_order", "pinned_single_segment_one_step", "two_segments_one_step",
    "negative_diagonal_segment", "reversed_segment_orientation", "repeated_adjacent_point",
    "translated_fractional_points", "maximum_point_count", "maximum_output_length",
    "count_below_minimum", "count_above_maximum", "negative_steps", "steps_above_maximum",
    "short_input", "extra_coordinate", "coordinate_out_of_range",
}


def validate_koch_snowflake_workload(workload: dict) -> None:
    """Pin the bounded, binary32-faithful Koch point iteration workload."""
    sources = [
        {
            "repository": "TheAlgorithms/C-Sharp",
            "commit": "96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c",
            "path": "Algorithms/Other/KochSnowflake.cs",
            "symbol": "KochSnowflake.Iterate",
            "url": "https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/KochSnowflake.cs",
        },
        {
            "repository": "TheAlgorithms/Java",
            "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
            "path": "src/main/java/com/thealgorithms/others/KochSnowflake.java",
            "symbol": "KochSnowflake.iterate",
            "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/KochSnowflake.java",
        },
        {
            "repository": "TheAlgorithms/JavaScript",
            "commit": "5c39e87a9a31f279c60f830ad74a845e4788a517",
            "path": "Recursive/KochSnowflake.js",
            "symbol": "iterate",
            "url": "https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Recursive/KochSnowflake.js",
        },
        {
            "repository": "TheAlgorithms/Python",
            "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
            "path": "fractals/koch_snowflake.py",
            "symbol": "iterate",
            "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/koch_snowflake.py",
        },
    ]
    input_spec = {
        "kind": "finite_float64_array",
        "layout": "[steps, point_count, x0, y0, ..., x(n-1), y(n-1)]",
        "length_formula": "2+2*point_count",
        "point_count_range": [KOCH_SNOWFLAKE_MIN_POINT_COUNT, KOCH_SNOWFLAKE_MAX_POINT_COUNT],
        "steps_range": [KOCH_SNOWFLAKE_MIN_STEPS, KOCH_SNOWFLAKE_MAX_STEPS],
        "coordinate_range": [-KOCH_SNOWFLAKE_MAX_COORDINATE, KOCH_SNOWFLAKE_MAX_COORDINATE],
        "invalid_input_result": -1,
    }
    output_spec = {
        "kind": "float64_array_of_widened_binary32_coordinates",
        "layout": "[x0, y0, x1, y1, ...] in preserved source order",
        "coordinate_count_formula": "2*((point_count-1)*4^steps+1)",
        "null_output_result": -2,
        "insufficient_output_capacity_result": -2,
        "no_write_on_error": True,
        "success_result": "number of returned binary64 coordinates",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 100,
        "absolute_tolerance": 1e-6,
        "relative_tolerance": 1e-7,
    }
    cases = workload.get("cases")
    case_list = cases if isinstance(cases, list) else []
    ids = [case.get("id") for case in case_list if isinstance(case, dict)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "koch-snowflake-f32-point-array-v1"
            or workload.get("algorithm") != "koch_snowflake"
            or workload.get("function_symbol") != "koch_snowflake"
            or workload.get("pinned_sources") != sources
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "elements": KOCH_SNOWFLAKE_MAX_OUTPUT_ELEMENTS,
                "meaning": "Maximum 29 output points, each with two widened binary32 coordinates.",
            }
            or workload.get("measurement") != measurement
            or KOCH_SNOWFLAKE_MIN_POINT_COUNT != 2
            or KOCH_SNOWFLAKE_MAX_POINT_COUNT != 8
            or KOCH_SNOWFLAKE_MIN_STEPS != 0
            or KOCH_SNOWFLAKE_MAX_STEPS != 1
            or KOCH_SNOWFLAKE_MAX_VALID_INPUT_LENGTH != 18
            or KOCH_SNOWFLAKE_MAX_PARSEABLE_INPUT_LENGTH != 20
            or KOCH_SNOWFLAKE_MAX_OUTPUT_ELEMENTS != 58
            or len(ids) != len(KOCH_SNOWFLAKE_CASE_IDS)
            or len(ids) != len(set(ids))
            or set(ids) != KOCH_SNOWFLAKE_CASE_IDS):
        raise ValueError("koch_snowflake workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "k" / "koch_snowflake" / "README.md").read_text(
        encoding="utf-8")
    if any(source["url"] not in readme for source in sources):
        raise ValueError("koch_snowflake README is missing a pinned source link")
    for case in case_list:
        values = case.get("input_values")
        if (not isinstance(values, list)
                or case.get("input_length") != len(values)
                or not 2 <= len(values) <= KOCH_SNOWFLAKE_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       for value in values)):
            raise ValueError(f"koch_snowflake input framing is invalid for {case.get('id')}")
        expected_output = koch_snowflake_oracle(values)
        expected_result = -1 if expected_output is None else len(expected_output)
        actual_output = case.get("expected_output")
        if (type(case.get("expected_result")) is not int
                or case.get("expected_result") != expected_result
                or not isinstance(actual_output, list)
                or len(actual_output) != (0 if expected_output is None else len(expected_output))
                or any(type(actual) not in (int, float)
                       or not math.isfinite(float(actual))
                       or abs(float(actual) - expected)
                       > measurement["absolute_tolerance"]
                           + measurement["relative_tolerance"] * abs(expected)
                       for actual, expected in zip(actual_output, expected_output or []))):
            raise ValueError(f"koch_snowflake workload mismatch: {case.get('id')}")


SIMPLE_PENDULUM_RK4_CASE_IDS = {
    "equilibrium", "small_angle_from_rest", "moderate_angle_and_velocity",
    "negative_angle_and_velocity", "all_lower_physical_bounds", "all_upper_physical_bounds",
    "length_minimum", "length_maximum", "gravity_minimum", "gravity_maximum",
    "theta_minimum", "theta_maximum", "omega_minimum", "omega_maximum",
    "dt_minimum", "dt_maximum", "length_below_minimum", "length_above_maximum",
    "gravity_below_minimum", "gravity_above_maximum", "theta_below_minimum",
    "theta_above_maximum", "omega_below_minimum", "omega_above_maximum",
    "dt_below_minimum", "dt_above_maximum", "fractional_micro_unit",
    "short_input", "extra_input",
}


def validate_simple_pendulum_rk4_workload(workload: dict) -> None:
    """Pin the one-step Java RK4 package and its finite float64 slice ABI."""
    source = {
        "repository": "TheAlgorithms/Java",
        "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
        "path": "src/main/java/com/thealgorithms/physics/SimplePendulumRK4.java",
        "symbol": "SimplePendulumRK4.stepRK4",
        "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/SimplePendulumRK4.java",
        "role": "algorithm",
    }
    contract = {
        "operation": "advance the simple-pendulum state [theta, omega] by exactly one classical RK4 step",
        "equations": [
            "theta' = omega",
            "omega' = -(gravity / length) * sin(theta)",
        ],
        "stage_order": "k1 at state; k2 and k3 at half steps; k4 at the full step; weighted sum k1+2*k2+2*k3+k4",
        "output_order": "[theta_next, omega_next] in physical radians and radians per second",
        "excluded_source_helpers": ["simulate", "energy"],
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[length_micro_units, gravity_micro_units, theta_micro_units, omega_micro_units, dt_micro_units]",
        "valid_length_range": [SIMPLE_PENDULUM_RK4_INPUT_LENGTH, SIMPLE_PENDULUM_RK4_INPUT_LENGTH],
        "maximum_valid_length": SIMPLE_PENDULUM_RK4_INPUT_LENGTH,
        "maximum_parseable_length": SIMPLE_PENDULUM_RK4_MAX_PARSEABLE_INPUT_LENGTH,
        "scale": 1_000_000,
        "scaled_values_must_be_integer_valued": True,
        "physical_ranges": {
            "length_m": [0.01, 100.0],
            "gravity_m_per_s2": [0.1, 20.0],
            "theta_rad": [-3.141593, 3.141593],
            "omega_rad_per_s": [-100.0, 100.0],
            "dt_s": [1e-6, 0.1],
        },
        "invalid_input_result": SIMPLE_PENDULUM_RK4_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "[theta_next_rad, omega_next_rad_per_s]",
        "maximum_elements": SIMPLE_PENDULUM_RK4_MAX_OUTPUT_ELEMENTS,
        "success_result": "number of output float64 elements (2)",
        "invalid_input_result": SIMPLE_PENDULUM_RK4_INVALID_RESULT,
        "invalid_output_buffer_result": SIMPLE_PENDULUM_RK4_OUTPUT_ERROR,
        "null_output_result": SIMPLE_PENDULUM_RK4_OUTPUT_ERROR,
        "no_write_on_error": True,
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    workspace = {
        "elements": SIMPLE_PENDULUM_RK4_MAX_OUTPUT_ELEMENTS,
        "meaning": "The updated [theta, omega] state.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 2000,
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    cases = workload.get("cases")
    cases = cases if isinstance(cases, list) else []
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "simple-pendulum-rk4-java-float64-slice-io-v1"
            or workload.get("algorithm") != "simple_pendulum_rk4"
            or workload.get("function_symbol") != "simple_pendulum_rk4"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or SIMPLE_PENDULUM_RK4_INPUT_LENGTH != 5
            or SIMPLE_PENDULUM_RK4_MAX_PARSEABLE_INPUT_LENGTH != 64
            or SIMPLE_PENDULUM_RK4_SCALE != 1_000_000.0
            or SIMPLE_PENDULUM_RK4_MAX_OUTPUT_ELEMENTS != 2
            or len(ids) != len(SIMPLE_PENDULUM_RK4_CASE_IDS)
            or len(ids) != len(set(ids))
            or set(ids) != SIMPLE_PENDULUM_RK4_CASE_IDS):
        raise ValueError("simple_pendulum_rk4 workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "s" / "simple_pendulum_rk4" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme:
        raise ValueError("simple_pendulum_rk4 README is missing its pinned source link")
    absolute_tolerance = output_spec["absolute_tolerance"]
    relative_tolerance = output_spec["relative_tolerance"]
    for case in cases:
        values = case.get("input_values")
        if (not isinstance(values, list)
                or case.get("input_length") != len(values)
                or not values
                or len(values) > SIMPLE_PENDULUM_RK4_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       or not float(value).is_integer() for value in values)):
            raise ValueError(f"simple_pendulum_rk4 input framing is invalid for {case.get('id')}")
        expected_output = simple_pendulum_rk4_oracle(values)
        expected_result = -1 if expected_output is None else len(expected_output)
        raw_output = case.get("expected_output")
        if (case.get("expected_result") != expected_result
                or not isinstance(raw_output, list)
                or len(raw_output) != (0 if expected_output is None else len(expected_output))):
            raise ValueError(f"simple_pendulum_rk4 workload shape mismatch: {case.get('id')}")
        if expected_output is not None and any(
                type(actual) not in (int, float)
                or not math.isfinite(float(actual))
                or abs(float(actual) - expected)
                > absolute_tolerance + relative_tolerance * abs(expected)
                for actual, expected in zip(raw_output, expected_output)):
            raise ValueError(f"simple_pendulum_rk4 workload mismatch: {case.get('id')}")
        if expected_output is None and raw_output:
            raise ValueError(f"simple_pendulum_rk4 invalid case has output: {case.get('id')}")


PIECEWISE_WITHOUT_INBUILT_CASE_IDS = {
    "lower_domain_boundary", "below_lower_threshold", "at_lower_threshold",
    "above_lower_threshold", "negative_middle", "zero", "positive_middle",
    "below_upper_threshold", "at_upper_threshold", "above_upper_threshold",
    "upper_domain_boundary", "below_domain", "above_domain", "fractional_input",
    "negative_fractional_input", "extra_input_value",
}


def validate_piecewise_without_inbuilt_workload(workload: dict) -> None:
    """Pin the MATLAB/Octave scalar piecewise function and finite slice contract."""
    source = {
        "repository": "TheAlgorithms/MATLAB-Octave",
        "commit": "e150b77ad256de46c1ce3815c3d7945ac4fc28dc",
        "path": "algorithms/machine_learning/Activation Functions/Piecewise(without inbuilt).m",
        "symbol": "y",
        "url": "https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Activation%20Functions/Piecewise%28without%20inbuilt%29.m",
        "role": "algorithm",
    }
    contract = {
        "operation": "evaluate the pinned scalar anonymous piecewise function y",
        "branches": [
            "0 when x <= -0.5",
            "x when -0.5 < x < 0.5",
            "1 when x >= 0.5",
        ],
        "threshold_equality": "The lower equality selects 0; the upper equality selects 1.",
        "plotting": "fplot, axis labels, and grid setup are excluded.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[x] in the source physical units",
        "valid_length_range": [PIECEWISE_WITHOUT_INBUILT_INPUT_LENGTH,
                               PIECEWISE_WITHOUT_INBUILT_INPUT_LENGTH],
        "maximum_valid_length": PIECEWISE_WITHOUT_INBUILT_INPUT_LENGTH,
        "maximum_parseable_length": PIECEWISE_WITHOUT_INBUILT_MAX_PARSEABLE_INPUT_LENGTH,
        "x_range": [PIECEWISE_WITHOUT_INBUILT_MIN_X, PIECEWISE_WITHOUT_INBUILT_MAX_X],
        "invalid_input_result": PIECEWISE_WITHOUT_INBUILT_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "[y]",
        "maximum_elements": PIECEWISE_WITHOUT_INBUILT_MAX_OUTPUT_ELEMENTS,
        "success_result": "number of output float64 elements (1)",
        "invalid_input_result": PIECEWISE_WITHOUT_INBUILT_INVALID_RESULT,
        "invalid_output_buffer_result": PIECEWISE_WITHOUT_INBUILT_OUTPUT_ERROR,
        "null_output_result": PIECEWISE_WITHOUT_INBUILT_OUTPUT_ERROR,
        "no_write_on_error": True,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    workspace = {
        "elements": PIECEWISE_WITHOUT_INBUILT_MAX_OUTPUT_ELEMENTS,
        "meaning": "The single piecewise function result.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    cases = workload.get("cases")
    case_list = cases if isinstance(cases, list) else []
    ids = [case.get("id") for case in case_list if isinstance(case, dict)]
    if (workload.get("schema_version") != 1
            or workload.get("id") != "piecewise-without-inbuilt-matlab-octave-float64-slice-io-v1"
            or workload.get("algorithm") != "piecewise_without_inbuilt"
            or workload.get("function_symbol") != "piecewise_without_inbuilt"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or PIECEWISE_WITHOUT_INBUILT_INPUT_LENGTH != 1
            or PIECEWISE_WITHOUT_INBUILT_MAX_PARSEABLE_INPUT_LENGTH != 64
            or PIECEWISE_WITHOUT_INBUILT_MIN_X != -10.0
            or PIECEWISE_WITHOUT_INBUILT_MAX_X != 10.0
            or PIECEWISE_WITHOUT_INBUILT_MAX_OUTPUT_ELEMENTS != 1
            or len(ids) != len(PIECEWISE_WITHOUT_INBUILT_CASE_IDS)
            or len(ids) != len(set(ids))
            or set(ids) != PIECEWISE_WITHOUT_INBUILT_CASE_IDS):
        raise ValueError("piecewise_without_inbuilt workload metadata does not match its reviewed contract")

    readme = (ROOT / "benchmarks" / "p" / "piecewise_without_inbuilt" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme:
        raise ValueError("piecewise_without_inbuilt README is missing its pinned source link")
    for case in case_list:
        values = case.get("input_values")
        if (not isinstance(values, list)
                or case.get("input_length") != len(values)
                or not 1 <= len(values) <= PIECEWISE_WITHOUT_INBUILT_MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       for value in values)):
            raise ValueError(f"piecewise_without_inbuilt input framing is invalid for {case.get('id')}")
        expected = piecewise_without_inbuilt_oracle(values)
        expected_result = PIECEWISE_WITHOUT_INBUILT_INVALID_RESULT if expected is None else len(expected)
        raw_output = case.get("expected_output")
        if (type(case.get("expected_result")) is not int
                or case.get("expected_result") != expected_result
                or not isinstance(raw_output, list)
                or len(raw_output) != (0 if expected is None else len(expected))):
            raise ValueError(f"piecewise_without_inbuilt workload shape mismatch: {case.get('id')}")
        if expected is not None and any(
                type(actual) not in (int, float) or not math.isfinite(float(actual))
                or float(actual) != wanted
                for actual, wanted in zip(raw_output, expected)):
            raise ValueError(f"piecewise_without_inbuilt workload mismatch: {case.get('id')}")
        if expected is None and raw_output:
            raise ValueError(f"piecewise_without_inbuilt invalid case has output: {case.get('id')}")


JOINT_PROBABILITY_DISTRIBUTION_CASE_IDS = {
    "pinned_cartesian_example", "single_pair_with_zero_support", "unnormalized_marginals",
    "negative_probability_is_multiplied", "different_support_sizes", "support_boundaries",
    "maximum_support_sizes", "probability_magnitude_boundaries", "short_input",
    "zero_x_support_count", "zero_y_support_count", "count_above_limit", "fractional_count",
    "missing_probability_value", "extra_packed_value", "noninteger_support",
    "support_below_limit", "support_above_limit", "duplicate_x_support",
    "duplicate_y_support", "probability_below_limit", "probability_above_limit",
}


def validate_joint_probability_distribution_workload(workload: dict) -> None:
    """Pin the Python Cartesian-product package and its bounded float64 ABI."""
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "maths/joint_probability_distribution.py",
        "symbol": "joint_probability_distribution",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/joint_probability_distribution.py",
        "role": "algorithm",
    }
    contract = {
        "operation": "form the independent Cartesian product and multiply px*py",
        "iteration_order": "x support outer loop, y support inner loop",
        "normalization": "none; use probabilities as supplied",
        "source_zip_and_dictionary_semantics": "The pinned Python uses zip and a dict comprehension; the bounded workload requires aligned arrays and unique supports, excluding truncation and duplicate tuple-key overwrites.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[nx, ny, x_values[nx], y_values[ny], x_probabilities[nx], y_probabilities[ny]]",
        "support_count_range": [1, MAX_JOINT_PROBABILITY_DISTRIBUTION_SUPPORT_LENGTH],
        "valid_length_range": [6, MAX_JOINT_PROBABILITY_DISTRIBUTION_INPUT_LENGTH],
        "maximum_valid_length": MAX_JOINT_PROBABILITY_DISTRIBUTION_INPUT_LENGTH,
        "maximum_parseable_length": MAX_JOINT_PROBABILITY_DISTRIBUTION_PARSEABLE_INPUT_LENGTH,
        "support_range": [-1000, 1000],
        "supports_must_be_unique": True,
        "probability_range": [-1000000.0, 1000000.0],
        "support_probability_arrays_aligned": True,
        "invalid_input_result": JOINT_PROBABILITY_DISTRIBUTION_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "ordered triples [x, y, px*py] for each Cartesian-product entry",
        "maximum_elements": MAX_JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ELEMENTS,
        "success_result": "number of output float64 elements (3 per pair)",
        "invalid_input_result": JOINT_PROBABILITY_DISTRIBUTION_INVALID_RESULT,
        "invalid_output_buffer_result": JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ERROR,
        "no_write_on_error": True,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    workspace = {
        "elements": MAX_JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ELEMENTS,
        "meaning": "Maximum output size for the 4-by-4 Cartesian product.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 500,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    cases = workload.get("cases")
    case_list = cases if isinstance(cases, list) else []
    case_ids = [case.get("id") for case in case_list if isinstance(case, dict)]
    maximum_case = next((case for case in case_list if isinstance(case, dict)
                         and case.get("id") == "maximum_support_sizes"), None)
    readme = (ROOT / "benchmarks" / "j" / "joint_probability_distribution" / "README.md").read_text(
        encoding="utf-8")
    if (workload.get("schema_version") != 1
            or workload.get("id") != "joint-probability-distribution-python-float64-slice-io-v1"
            or workload.get("algorithm") != "joint_probability_distribution"
            or workload.get("function_symbol") != "joint_probability_distribution"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or len(case_ids) != len(JOINT_PROBABILITY_DISTRIBUTION_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != JOINT_PROBABILITY_DISTRIBUTION_CASE_IDS
            or maximum_case is None
            or maximum_case.get("input_length") != MAX_JOINT_PROBABILITY_DISTRIBUTION_INPUT_LENGTH
            or maximum_case.get("expected_result") != MAX_JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ELEMENTS
            or len(maximum_case.get("input_values", [])) != MAX_JOINT_PROBABILITY_DISTRIBUTION_INPUT_LENGTH
            or source["url"] not in readme
            or MAX_JOINT_PROBABILITY_DISTRIBUTION_SUPPORT_LENGTH != 4
            or MAX_JOINT_PROBABILITY_DISTRIBUTION_INPUT_LENGTH != 18
            or MAX_JOINT_PROBABILITY_DISTRIBUTION_PARSEABLE_INPUT_LENGTH != 20
            or MAX_JOINT_PROBABILITY_DISTRIBUTION_OUTPUT_ELEMENTS != 48):
        raise ValueError("joint_probability_distribution workload metadata does not match its reviewed contract")


SHREEDHARACHARYA_CASE_IDS = {
    "pinned_repeated_root", "two_roots_source_order", "negative_discriminant_empty_result",
    "irrational_roots", "fractional_roots", "negative_leading_coefficient",
    "fractional_repeated_root", "negative_a_no_real_roots", "minimum_leading_coefficient",
    "negative_minimum_leading_coefficient", "maximum_coefficient_root_pair",
    "maximum_coefficients_negative_discriminant", "direct_formula_cancellation",
    "slightly_negative_discriminant", "positive_b_boundary", "negative_a_boundary",
    "zero_leading_coefficient", "leading_coefficient_below_minimum",
    "leading_coefficient_above_maximum", "b_below_minimum", "c_above_maximum",
    "short_input", "one_value_input", "extra_input_value",
}


def validate_shreedharacharya_workload(workload: dict) -> None:
    """Pin the Dart quadratic formula and its variable-length root result."""
    source = {
        "repository": "TheAlgorithms/Dart",
        "commit": "73da8ab4ea413eee9bf29aa2263157d86060f871",
        "path": "maths/shreedharacharya.dart",
        "symbol": "shreedharacharya",
        "url": "https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/shreedharacharya.dart",
        "role": "algorithm",
    }
    contract = {
        "operation": "solve a*x^2+b*x+c=0 using the pinned direct discriminant formula",
        "discriminant": "d=b*b-4*a*c; negative returns zero roots, zero returns one root, positive returns two roots",
        "root_order": "(-b+sqrt(d))/(2*a) before (-b-sqrt(d))/(2*a)",
        "negative_discriminant_source_behavior": "The Dart source prints Imaginary roots and returns an empty List; the benchmark ignores console output and returns result count 0.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[a,b,c]",
        "valid_length_range": [3, 3],
        "maximum_valid_length": MAX_SHREEDHARACHARYA_INPUT_LENGTH,
        "maximum_parseable_length": 64,
        "leading_coefficient_abs_range": [SHREEDHARACHARYA_MIN_ABS_A, SHREEDHARACHARYA_MAX_COEFFICIENT],
        "other_coefficient_abs_range": [0.0, SHREEDHARACHARYA_MAX_COEFFICIENT],
        "invalid_input_result": SHREEDHARACHARYA_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "zero, one, or two roots in the pinned source order",
        "maximum_elements": MAX_SHREEDHARACHARYA_OUTPUT_ELEMENTS,
        "success_result": "number of real roots",
        "empty_result": 0,
        "invalid_input_result": SHREEDHARACHARYA_INVALID_RESULT,
        "invalid_output_buffer_result": SHREEDHARACHARYA_OUTPUT_ERROR,
        "null_output_result": SHREEDHARACHARYA_OUTPUT_ERROR,
        "empty_result_requires_nonnull_output_pointer": True,
        "no_write_on_error": True,
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    workspace = {"elements": MAX_SHREEDHARACHARYA_OUTPUT_ELEMENTS,
                 "meaning": "Maximum of two real roots."}
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    cases = workload.get("cases")
    case_list = cases if isinstance(cases, list) else []
    ids = [case.get("id") for case in case_list if isinstance(case, dict)]
    zero_root_case = next((case for case in case_list if isinstance(case, dict)
                           and case.get("id") == "negative_discriminant_empty_result"), None)
    readme = (ROOT / "benchmarks" / "s" / "shreedharacharya" / "README.md").read_text(
        encoding="utf-8")
    if (workload.get("schema_version") != 1
            or workload.get("id") != "shreedharacharya-dart-f64-slice-io-v1"
            or workload.get("algorithm") != "shreedharacharya"
            or workload.get("function_symbol") != "shreedharacharya"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or len(ids) != len(SHREEDHARACHARYA_CASE_IDS)
            or len(ids) != len(set(ids))
            or set(ids) != SHREEDHARACHARYA_CASE_IDS
            or zero_root_case is None
            or zero_root_case.get("expected_result") != 0
            or zero_root_case.get("expected_output") != []
            or source["url"] not in readme
            or MAX_SHREEDHARACHARYA_INPUT_LENGTH != 3
            or SHREEDHARACHARYA_MAX_COEFFICIENT != 1_000_000.0
            or MAX_SHREEDHARACHARYA_OUTPUT_ELEMENTS != 2):
        raise ValueError("shreedharacharya workload metadata does not match its reviewed contract")


def validate_pid_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/C",
        "commit": "e5dad3fa8def3726ec850ca66a7f51521f8ad393",
        "path": "misc/pid.c",
        "symbol": "pid_step",
        "url": "https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/pid.c",
    }
    contract = {
        "state_initialization": "integral=0 and lastError=0 at the beginning of every call",
        "operation_order": "float32 p=error*kP; float32 integral += error*dt*kI left to right; float32 d=(dt==0?0:((error-lastError)/dt)*kD); lastError=error; output=p+integral+d left to right",
        "dt_zero_rule": "Suppress derivative only; still update integral and lastError.",
        "input_validation": "Check finite float64 parameters and their bounds before casting to float32.",
        "output_conversion": "Widen each float32 step result exactly to float64.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "layout": "[kP, kI, kD, dt, error_0, ...]",
        "length_range": [4 + PID_MIN_ERROR_COUNT, MAX_PID_INPUT_LENGTH],
        "error_count_range": [PID_MIN_ERROR_COUNT, PID_MAX_ERROR_COUNT],
        "gain_range": [-1.0, 1.0],
        "dt_rule": "Exactly 0 or in [0.01, 1.0], checked before float32 conversion.",
        "error_range": [-1.0, 1.0],
        "invalid_input_result": -1,
    }
    output_spec = {
        "kind": "float64_array",
        "meaning": "One widened float32 PID step result per error sample.",
        "success_result": "error count",
        "invalid_input_result": -1,
        "invalid_output_buffer_result": -2,
        "no_write_on_error": True,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    workspace = {
        "elements": PID_MAX_ERROR_COUNT,
        "meaning": "Maximum number of error samples and output values.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 100,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    required_case_ids = {
        "proportional_only", "integral_accumulates", "derivative_uses_previous_error",
        "combined_terms", "fractional_float32_rounding_and_accumulation",
        "zero_dt_suppresses_derivative", "minimum_positive_dt",
        "maximum_dt", "gain_and_error_endpoints", "maximum_60_error_samples",
        "missing_error_sample", "gain_above_range_before_float32_cast",
        "gain_below_range", "negative_dt", "dt_below_minimum_before_float32_cast",
        "dt_above_maximum", "error_above_range_before_float32_cast", "error_below_range",
    }
    cases = workload.get("cases")
    case_list = cases if isinstance(cases, list) else []
    case_ids = [case.get("id") for case in case_list if isinstance(case, dict)]
    maximum_case = next((case for case in case_list if isinstance(case, dict)
                         and case.get("id") == "maximum_60_error_samples"), None)
    readme = (ROOT / "benchmarks" / "p" / "pid" / "README.md").read_text(encoding="utf-8")
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-c-pid-float32-sequence-v1"
            or workload.get("algorithm") != "pid"
            or workload.get("function_symbol") != "pid"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or not required_case_ids.issubset(set(case_ids))
            or len(case_ids) != len(set(case_ids))
            or maximum_case is None
            or maximum_case.get("input_length") != MAX_PID_INPUT_LENGTH
            or maximum_case.get("expected_result") != PID_MAX_ERROR_COUNT
            or len(maximum_case.get("input_values", [])) != MAX_PID_INPUT_LENGTH
            or source["url"] not in readme
            or "float32" not in readme
            or "When `dt` is zero" not in readme):
        raise ValueError("pid workload metadata does not match its reviewed contract")


def _output_value(value: object) -> float:
    if value == "NaN":
        return math.nan
    if type(value) not in (int, float):
        raise ValueError("float64-slice outputs must be finite numbers or the string 'NaN'")
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("float64-slice outputs cannot be infinite")
    return number


def _output_token(value: object) -> float | str:
    number = float(value)
    if math.isnan(number):
        return "NaN"
    if not math.isfinite(number):
        raise ValueError("float64-slice oracle produced an infinite output")
    return number


def _format_output(value: float | str) -> str:
    return "NaN" if value == "NaN" else format(float(value), ".17g")


def _same_float64_value(actual: object, expected: object) -> bool:
    if type(actual) not in (int, float) or type(expected) not in (int, float):
        return False
    actual_number, expected_number = float(actual), float(expected)
    if actual_number != expected_number:
        return False
    return (actual_number != 0.0
            or math.copysign(1.0, actual_number) == math.copysign(1.0, expected_number))


def _same_float64_sequence(actual: object, expected: object) -> bool:
    return (isinstance(actual, list) and isinstance(expected, list)
            and len(actual) == len(expected)
            and all(_same_float64_value(value, reference)
                    for value, reference in zip(actual, expected)))


def tolerances(workload: dict) -> tuple[float, float]:
    measurement = workload.get("measurement", {})
    output = workload.get("output", {})
    absolute = float(measurement.get("absolute_tolerance", output.get("absolute_tolerance", 0.0)))
    relative = float(measurement.get("relative_tolerance", output.get("relative_tolerance", 0.0)))
    if (not math.isfinite(absolute) or absolute < 0.0
            or not math.isfinite(relative) or relative < 0.0):
        raise ValueError("float64-slice tolerances must be finite and nonnegative")
    if ("absolute_tolerance" in output and float(output["absolute_tolerance"]) != absolute
            or "relative_tolerance" in output and float(output["relative_tolerance"]) != relative):
        raise ValueError("measurement and output tolerances must agree")
    return absolute, relative


def encode_case(case: dict, algorithm: str, absolute_tolerance: float,
                relative_tolerance: float) -> tuple[list[float], int, list[float]]:
    oracle = ORACLES.get(algorithm)
    if oracle is None:
        raise ValueError(f"no float64-slice oracle registered for {algorithm}")
    raw_values = case.get("input_values")
    max_input_length = (MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH
                        if algorithm == "rayleigh_quotient" else
                        MAX_PID_INPUT_LENGTH if algorithm == "pid" else
                        K_D_TREE_MAX_INPUT_LENGTH if algorithm == "k_d_tree" else
                        KOCH_SNOWFLAKE_MAX_PARSEABLE_INPUT_LENGTH
                        if algorithm == "koch_snowflake" else
                        MAX_JOINT_PROBABILITY_DISTRIBUTION_PARSEABLE_INPUT_LENGTH
                        if algorithm == "joint_probability_distribution" else
                        ROTATION_MATRIX_MAX_PARSEABLE_INPUT_LENGTH
                        if algorithm == "rotation_matrix" else
                        LINEAR_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH
                        if algorithm == "linear_regression_vectorized" else
                        MD2_DIGEST_MAX_INPUT_LENGTH + 1 if algorithm == "md2_digest" else
                        MEDIAN_FILTER_MAX_INPUT_LENGTH if algorithm == "median_filter" else
                        MUTATE_MAX_INPUT_LENGTH if algorithm == "mutate" else
                        SINGLE_POINT_CROSSOVER_MAX_INPUT_LENGTH
                        if algorithm == "single_point_crossover" else
                        RHUMB_DISTANCE_MAX_PARSEABLE_INPUT_LENGTH if algorithm == "rhumb_distance" else
                        RHUMB_BEARING_MAX_PARSEABLE_INPUT_LENGTH if algorithm == "rhumb_bearing" else
                        RHUMB_DESTINATION_MAX_PARSEABLE_INPUT_LENGTH if algorithm == "rhumb_destination" else
                        MEDIAN_RUNNING_DOUBLE_MAX_PARSEABLE_INPUT_LENGTH
                        if algorithm == "median_of_running_array_double" else
                        MEDIAN_RUNNING_FLOAT_MAX_PARSEABLE_INPUT_LENGTH
                        if algorithm == "median_of_running_array_float" else 64)
    if algorithm == "pi_monte_carlo_estimation":
        max_input_length = PI_MONTE_CARLO_MAX_PARSEABLE_INPUT_LENGTH
    if algorithm == "mean_shift":
        max_input_length = MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH
    if algorithm == "perlin_noise":
        max_input_length = PERLIN_NOISE_MAX_PARSEABLE_INPUT_ELEMENTS
    elif algorithm == "quaternions":
        max_input_length = QUATERNIONS_MAX_INPUT_LENGTH
    if (not isinstance(raw_values, list) or case.get("input_length") != len(raw_values)
            or (not raw_values and algorithm != "md2_digest")
            or len(raw_values) > max_input_length
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in raw_values)):
        raise ValueError("float64-slice inputs must be finite arrays with a matching input_length")
    values = [float(value) for value in raw_values]
    if algorithm in {"joint_probability_distribution", "shreedharacharya", "rotation_matrix",
                     "rhumb_distance", "rhumb_bearing", "rhumb_destination",
                     "median_of_running_array_double", "median_of_running_array_float",
                     "mean_shift"}:
        expected_result, oracle_values = oracle(values)
        oracle_output = None if expected_result < 0 else oracle_values
    else:
        oracle_output = oracle(values)
        expected_result = len(oracle_output) if oracle_output is not None else -1
    expected_output = [] if oracle_output is None else [_output_token(value) for value in oracle_output]
    if case.get("expected_result") != expected_result:
        raise ValueError(f"{case.get('id')}: expected_result disagrees with the independent oracle")
    raw_expected = case.get("expected_output")
    if (not isinstance(raw_expected, list) or len(raw_expected) != len(expected_output)):
        raise ValueError(f"{case.get('id')}: expected_output must match the oracle output shape")
    actual_output = [_output_token(_output_value(value)) for value in raw_expected]
    if algorithm in {"median_of_running_array_double", "mean_shift"}:
        if not _same_float64_sequence(actual_output, expected_output):
            raise ValueError(f"{case.get('id')}: expected_output differs, including signed zero")
        return values, expected_result, actual_output
    if algorithm == "median_of_running_array_float":
        if not _same_float64_sequence(actual_output, expected_output):
            raise ValueError(f"{case.get('id')}: expected_output differs, including binary32 signed zero")
        return values, expected_result, actual_output
    for actual, expected in zip(actual_output, expected_output):
        if expected == "NaN":
            if actual != "NaN":
                raise ValueError(f"{case.get('id')}: expected_output disagrees with the independent oracle")
            continue
        actual_number = float(actual)
        expected_number = float(expected)
        allowed = absolute_tolerance + relative_tolerance * abs(expected_number)
        if abs(actual_number - expected_number) > allowed:
            raise ValueError(f"{case.get('id')}: expected_output disagrees with the independent oracle")
    return values, expected_result, actual_output


def _decode_k_d_tree_abi_values(raw_values: object) -> list[float]:
    """Translate the workload's JSON spellings for nonfinite ABI probe values."""
    if not isinstance(raw_values, list):
        raise ValueError("k_d_tree ABI probe input_values must be an array")
    nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf, "-Infinity": -math.inf}
    values: list[float] = []
    for value in raw_values:
        if isinstance(value, str):
            if value not in nonfinite_tokens:
                raise ValueError(f"unsupported k_d_tree nonfinite input token: {value}")
            values.append(nonfinite_tokens[value])
        elif type(value) in (int, float):
            values.append(float(value))
        else:
            raise ValueError("k_d_tree ABI probe values must be numbers or nonfinite tokens")
    return values


K_D_TREE_CASE_IDS = {
    "two-dimensional-near-branch", "two-dimensional-nearest-in-far-branch",
    "three-dimensional-single-point", "maximum-point-count-and-input-length",
    "invalid-tied-nearest-points", "invalid-axis-coordinate-tie", "invalid-dimension",
    "invalid-one-value-input", "invalid-empty-point-set", "invalid-fractional-coordinate",
    "invalid-coordinate-out-of-range", "invalid-truncated-point-record", "invalid-extra-value",
}
K_D_TREE_ABI_CASE_IDS = {
    "invalid-input-before-null-output", "valid-input-null-output",
    "valid-input-short-output-capacity", "nonfinite-nan-query-coordinate",
    "nonfinite-positive-infinity-point-coordinate", "nonfinite-negative-infinity-query-coordinate",
}


def validate_k_d_tree_workload(workload: dict) -> None:
    """Validate k_d_tree metadata, fixtures, and nonfinite ABI-only probes."""
    source = {
        "repository": "TheAlgorithms/Lua",
        "commit": "cedc141018ad48884318fe08a6db278664b17128",
        "path": "src/data_structures/k_d_tree.lua",
        "symbol": "new (default median-of-medians constructor) and nearest_neighbor",
        "url": "https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/k_d_tree.lua",
        "supporting_paths": [
            "src/sorting/quickselect_median_of_medians.lua",
            "src/sorting/quickselect.lua",
            "src/sorting/three_way_partition.lua",
        ],
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[dimension, point_count, query[dimension], point_0[dimension], ...]",
        "dimension_values": [K_D_TREE_MIN_DIMENSION, K_D_TREE_MAX_DIMENSION],
        "point_count_range": [K_D_TREE_MIN_POINT_COUNT, K_D_TREE_MAX_POINT_COUNT],
        "exact_length": "2 + dimension * (point_count + 1)",
        "coordinate_range": [K_D_TREE_MIN_COORDINATE, K_D_TREE_MAX_COORDINATE],
        "coordinate_requirement": "every input is finite and integral; point coordinates are distinct on each axis",
        "maximum_valid_input_length": K_D_TREE_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_length": K_D_TREE_MAX_INPUT_LENGTH,
        "invalid_input_result": K_D_TREE_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "definition": "[Euclidean distance, nearest point coordinates in source axis order]",
        "success_result": "dimension + 1 output values",
        "invalid_input_result": K_D_TREE_INVALID_RESULT,
        "invalid_output_buffer_result": K_D_TREE_OUTPUT_ERROR,
        "unique_nearest_point_required": True,
        "validation_order": "validate complete input and unique nearest point before checking output pointer or capacity",
        "error_output_behavior": "do not modify output on either error",
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "absolute_tolerance": 1e-12,
        "relative_tolerance": 1e-12,
        "sample_count": 7,
        "warmup_rounds": 2,
        "repetitions_per_sample": 1000,
    }
    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    abi_ids = [case.get("id") for case in abi_cases if isinstance(case, dict)] if isinstance(abi_cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "lua-k-d-tree-nearest-neighbor-f64-slice-v1"
            or workload.get("algorithm") != "k_d_tree"
            or workload.get("function_symbol") != "k_d_tree"
            or workload.get("workspace") != {"elements": K_D_TREE_MAX_OUTPUT_ELEMENTS}
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("measurement") != measurement
            or workload.get("pinned_source") != source
            or K_D_TREE_MAX_INPUT_LENGTH != 51
            or K_D_TREE_MAX_VALID_INPUT_LENGTH != 50
            or K_D_TREE_MAX_OUTPUT_ELEMENTS != 4
            or K_D_TREE_INVALID_RESULT != -1
            or K_D_TREE_OUTPUT_ERROR != -2
            or len(case_ids) != len(K_D_TREE_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != K_D_TREE_CASE_IDS
            or len(abi_ids) != len(K_D_TREE_ABI_CASE_IDS)
            or len(abi_ids) != len(set(abi_ids))
            or set(abi_ids) != K_D_TREE_ABI_CASE_IDS):
        raise ValueError("k_d_tree workload metadata or case IDs do not match the reviewed contract")

    readme = (ROOT / "benchmarks" / "k" / "k_d_tree" / "README.md").read_text(encoding="utf-8")
    if source["url"] not in readme:
        raise ValueError("k_d_tree README is missing its pinned source link")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case in cases:
        encode_case(case, "k_d_tree", absolute_tolerance, relative_tolerance)

    abi_by_id = {case["id"]: case for case in abi_cases}
    for case in abi_cases:
        values = _decode_k_d_tree_abi_values(case.get("input_values"))
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        if (not values or len(values) > K_D_TREE_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= K_D_TREE_MAX_OUTPUT_ELEMENTS
                or type(output_is_null) is not bool):
            raise ValueError(f"k_d_tree ABI input/output framing is invalid for {case.get('id')}")
        output = k_d_tree_oracle(values)
        expected_result = (K_D_TREE_INVALID_RESULT if output is None else
                           K_D_TREE_OUTPUT_ERROR if output_is_null or len(output) > capacity else
                           len(output))
        if type(case.get("expected_result")) is not int or case["expected_result"] != expected_result:
            raise ValueError(f"k_d_tree ABI probe mismatch: {case.get('id')}")
    if (abi_by_id["invalid-input-before-null-output"].get("output_is_null") is not True
            or abi_by_id["valid-input-null-output"].get("output_is_null") is not True
            or abi_by_id["valid-input-short-output-capacity"].get("output_capacity") != 2
            or any(abi_by_id[name]["expected_result"] != K_D_TREE_INVALID_RESULT for name in (
                "nonfinite-nan-query-coordinate", "nonfinite-positive-infinity-point-coordinate",
                "nonfinite-negative-infinity-query-coordinate"))):
        raise ValueError("k_d_tree ABI workload is missing reviewed null, capacity, or nonfinite cases")


def validate_linear_regression_vectorized_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "machine_learning/linear_regression_vectorized.py",
        "symbol": "gradient_descent",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/linear_regression_vectorized.py",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[m, d, iterations, alpha, X row-major (m*d values), y (m labels)]",
        "sample_count_range": [LINEAR_REGRESSION_MIN_SAMPLE_COUNT, LINEAR_REGRESSION_MAX_SAMPLE_COUNT],
        "feature_count_range": [LINEAR_REGRESSION_MIN_FEATURE_COUNT, LINEAR_REGRESSION_MAX_FEATURE_COUNT],
        "iteration_count_range": [LINEAR_REGRESSION_MIN_ITERATIONS, LINEAR_REGRESSION_MAX_ITERATIONS],
        "learning_rate_range": [LINEAR_REGRESSION_MIN_ALPHA, LINEAR_REGRESSION_MAX_ALPHA],
        "integer_valued_fields": ["m", "d", "iterations"],
        "intercept_rule": "The first feature in every row of X is exactly 1.0.",
        "feature_and_label_range": [LINEAR_REGRESSION_MIN_FEATURE_OR_LABEL,
                                    LINEAR_REGRESSION_MAX_FEATURE_OR_LABEL],
        "all_values_finite": True,
        "maximum_valid_input_length": LINEAR_REGRESSION_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": LINEAR_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 4 + m*d + m finite f64 values.",
        "invalid_input_result": -1,
        "null_input_result": -1,
    }
    output_spec = {
        "kind": "finite_float64_array",
        "encoding": "The d learned theta coefficients in feature order.",
        "maximum_output_elements": LINEAR_REGRESSION_MAX_OUTPUT_ELEMENTS,
        "success_result": "output element count",
        "absolute_tolerance": LINEAR_REGRESSION_ABSOLUTE_TOLERANCE,
        "relative_tolerance": LINEAR_REGRESSION_RELATIVE_TOLERANCE,
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_output_capacity_result": -2,
        "no_write_on_error": True,
        "error_precedence": "Invalid or null input is rejected before output pointer or capacity checks.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 3,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": LINEAR_REGRESSION_ABSOLUTE_TOLERANCE,
        "relative_tolerance": LINEAR_REGRESSION_RELATIVE_TOLERANCE,
    }
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-linear-regression-vectorized-float64-slice-v1"
            or workload.get("algorithm") != "linear_regression_vectorized"
            or workload.get("function_symbol") != "linear_regression_vectorized"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {"elements": LINEAR_REGRESSION_MAX_OUTPUT_ELEMENTS}
            or workload.get("measurement") != measurement
            or LINEAR_REGRESSION_MAX_SAMPLE_COUNT != 8
            or LINEAR_REGRESSION_MAX_FEATURE_COUNT != 4
            or LINEAR_REGRESSION_MAX_ITERATIONS != 128
            or LINEAR_REGRESSION_MAX_INPUT_LENGTH != 44
            or LINEAR_REGRESSION_MAX_PARSEABLE_INPUT_LENGTH != 45
            or LINEAR_REGRESSION_MAX_OUTPUT_ELEMENTS != 4
            or LINEAR_REGRESSION_ABSOLUTE_TOLERANCE != 1e-10
            or LINEAR_REGRESSION_RELATIVE_TOLERANCE != 1e-10
            or not isinstance(cases, list)
            or len(case_ids) != len(LINEAR_REGRESSION_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != LINEAR_REGRESSION_CASE_IDS):
        raise ValueError("linear_regression_vectorized workload metadata or case IDs do not match the reviewed contract")

    readme = (ROOT / "benchmarks" / "l" / "linear_regression_vectorized" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "gradient_descent" not in readme
            or "without rounding" not in readme):
        raise ValueError("linear_regression_vectorized README is missing its pinned source or update order")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case in cases:
        encode_case(case, "linear_regression_vectorized", absolute_tolerance, relative_tolerance)


PERLIN_NOISE_CASE_IDS = frozenset({
    "one_cell_seed_zero", "seeded_two_by_three_x_major",
    "one_by_eight_wraps_octave_periods", "eight_by_one_wraps_octave_periods",
    "single_octave", "persistence_half", "persistence_three_quarters", "persistence_one",
    "largest_seed", "maximum_grid_and_octaves", "zero_width_invalid",
    "fractional_width_invalid", "height_above_bound_invalid", "zero_octaves_invalid",
    "fractional_octaves_invalid", "unsupported_persistence_invalid", "zero_persistence_invalid",
    "negative_seed_invalid", "seed_above_i32_range_invalid", "fractional_seed_invalid",
    "trailing_element_invalid", "missing_seed_invalid",
})


def validate_perlin_noise_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Java",
        "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
        "path": "src/main/java/com/thealgorithms/others/PerlinNoise.java",
        "symbol": "generatePerlinNoise",
        "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/PerlinNoise.java",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[width, height, octave_count, persistence, seed]",
        "width_range": [PERLIN_NOISE_MIN_DIMENSION, PERLIN_NOISE_MAX_DIMENSION],
        "height_range": [PERLIN_NOISE_MIN_DIMENSION, PERLIN_NOISE_MAX_DIMENSION],
        "octave_count_range": [PERLIN_NOISE_MIN_OCTAVES, PERLIN_NOISE_MAX_OCTAVES],
        "persistence_values": list(PERLIN_NOISE_PERSISTENCE_VALUES),
        "seed_range": [PERLIN_NOISE_MIN_SEED, PERLIN_NOISE_MAX_SEED],
        "maximum_valid_input_length": PERLIN_NOISE_MAX_INPUT_ELEMENTS,
        "maximum_parseable_input_length": PERLIN_NOISE_MAX_PARSEABLE_INPUT_ELEMENTS,
        "exact_packed_shape": "Exactly five finite f64 elements; dimensions, octave count, and seed must be exact integers.",
        "invalid_input_result": PERLIN_NOISE_INVALID_RESULT,
        "null_input_result": PERLIN_NOISE_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "definition": "width*height values widened from the source float[width][height], in x-major then y-minor order.",
        "element_count": "width*height",
        "valid_output_elements_range": [1, PERLIN_NOISE_MAX_OUTPUT_ELEMENTS],
        "maximum_output_elements": PERLIN_NOISE_MAX_OUTPUT_ELEMENTS,
        "invalid_input_result": PERLIN_NOISE_INVALID_RESULT,
        "invalid_output_buffer_result": PERLIN_NOISE_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
        "success_result": "output element count",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 100,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    cases = workload.get("cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-java-perlin-noise-f64-slice-io-v1"
            or workload.get("algorithm") != "perlin_noise"
            or workload.get("function_symbol") != "perlin_noise"
            or workload.get("pinned_source") != source
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {"elements": PERLIN_NOISE_MAX_OUTPUT_ELEMENTS}
            or workload.get("measurement") != measurement
            or PERLIN_NOISE_MIN_DIMENSION != 1 or PERLIN_NOISE_MAX_DIMENSION != 8
            or PERLIN_NOISE_MIN_OCTAVES != 1 or PERLIN_NOISE_MAX_OCTAVES != 4
            or PERLIN_NOISE_MIN_SEED != 0 or PERLIN_NOISE_MAX_SEED != (1 << 31) - 1
            or PERLIN_NOISE_MAX_INPUT_ELEMENTS != 5
            or PERLIN_NOISE_MAX_PARSEABLE_INPUT_ELEMENTS != 6
            or PERLIN_NOISE_MAX_OUTPUT_ELEMENTS != 64
            or PERLIN_NOISE_INVALID_RESULT != -1 or PERLIN_NOISE_OUTPUT_ERROR != -2
            or tuple(PERLIN_NOISE_PERSISTENCE_VALUES) != (0.5, 0.75, 1.0)
            or not isinstance(cases, list)
            or len(case_ids) != len(PERLIN_NOISE_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != PERLIN_NOISE_CASE_IDS):
        raise ValueError("perlin_noise workload metadata or case IDs do not match the reviewed contract")

    readme = (ROOT / "benchmarks" / "p" / "perlin_noise" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or "Java Random" not in readme
            or "binary32 rounding" not in readme or "x-major" not in readme):
        raise ValueError("perlin_noise README is missing its pinned source or Java output semantics")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case in cases:
        encode_case(case, "perlin_noise", absolute_tolerance, relative_tolerance)


SINGLE_POINT_CROSSOVER_CASE_IDS = {
    "minimum_parent_length", "first_legal_cut", "middle_cut", "last_legal_cut",
    "signed_fractional_genes", "duplicates_and_signed_zero", "maximum_parent_length",
    "parent_length_below_minimum", "parent_length_above_maximum", "zero_prefix_length",
    "cut_at_parent_length", "fractional_parent_length", "fractional_cut_length",
    "truncated_parent_payload", "extra_parent_payload",
}
SINGLE_POINT_CROSSOVER_ABI_CASE_IDS = {
    "invalid_input_before_null_output", "valid_input_null_output",
    "valid_input_short_output_capacity", "nonfinite_nan_gene",
    "nonfinite_positive_infinity_gene", "nonfinite_negative_infinity_gene",
}
QUATERNIONS_CASE_IDS = {
    "euler_identity", "euler_roll_axis", "euler_pitch_axis", "euler_yaw_axis",
    "euler_combined", "euler_lower_angle_boundary", "euler_upper_angle_boundary",
    "euler_angle_out_of_range", "euler_wrong_length", "unknown_operation",
    "quaternion_identity", "quaternion_plus_sign_pitch_positive",
    "quaternion_plus_sign_pitch_negative", "quaternion_binary32_norm_rounding",
    "quaternion_unnormalized_rejected", "quaternion_component_out_of_range",
    "quaternion_pitch_argument_out_of_range", "quaternion_wrong_length",
    "hamilton_identity", "hamilton_noncommuting_basis", "hamilton_general_nonunit",
    "hamilton_component_bound_and_output_bound", "hamilton_component_out_of_range",
    "hamilton_extra_input_value",
}
QUATERNIONS_ABI_CASE_IDS = {
    "short_output_op0", "short_output_op1", "short_output_op2", "null_output_op1",
    "invalid_input_precedes_null_output", "null_input",
}


def _decode_single_point_crossover_abi_values(raw_values: object) -> list[float]:
    if not isinstance(raw_values, list):
        raise ValueError("single_point_crossover ABI input_values must be an array")
    nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf, "-Infinity": -math.inf}
    values: list[float] = []
    for value in raw_values:
        if isinstance(value, str):
            if value not in nonfinite_tokens:
                raise ValueError("unsupported single_point_crossover nonfinite input token")
            values.append(nonfinite_tokens[value])
        elif type(value) in (int, float):
            values.append(float(value))
        else:
            raise ValueError("single_point_crossover ABI values must be numbers or nonfinite tokens")
    return values


def validate_single_point_crossover_workload(workload: dict) -> None:
    """Validate the pinned deterministic crossover fixtures and ABI-only probes."""
    source = {
        "repository": "TheAlgorithms/MATLAB-Octave",
        "commit": "e150b77ad256de46c1ce3815c3d7945ac4fc28dc",
        "path": "algorithms/Genetic-Algorithm/Minimization of polynomial function/SinglePointCrossover.m",
        "url": "https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/SinglePointCrossover.m",
        "role": "algorithm",
    }
    contract = {
        "operation": "single-point crossover of equal-length numeric row vectors",
        "source_cut_range": "MATLAB randi([1,nVar-1])",
        "deterministic_cut_input": True,
        "cut_semantics": "prefix length j; copy indices [0,j) from each parent and swap suffixes [j,n)",
        "output_layout": "child1[0:n] followed by child2[0:n]",
        "gene_operation": "copy finite binary64 values without arithmetic",
        "random_number_generation_included": False,
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[n, j, x1[0:n], x2[0:n]]",
        "parent_length_range": [SINGLE_POINT_CROSSOVER_MIN_PARENT_LENGTH, 31],
        "cut_prefix_length_range": "1 <= j < n",
        "maximum_valid_input_length": SINGLE_POINT_CROSSOVER_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_length": SINGLE_POINT_CROSSOVER_MAX_INPUT_LENGTH,
        "invalid_input_result": SINGLE_POINT_CROSSOVER_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "definition": "child1[0:n] followed by child2[0:n]",
        "maximum_output_elements": SINGLE_POINT_CROSSOVER_MAX_OUTPUT_ELEMENTS,
        "success_result": "output element count (2*n)",
        "invalid_input_result": SINGLE_POINT_CROSSOVER_INVALID_RESULT,
        "invalid_output_buffer_result": SINGLE_POINT_CROSSOVER_OUTPUT_ERROR,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    abi_ids = [case.get("id") for case in abi_cases if isinstance(case, dict)] if isinstance(abi_cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-matlab-octave-single-point-crossover-f64-slice-io-v1"
            or workload.get("algorithm") != "single_point_crossover"
            or workload.get("function_symbol") != "single_point_crossover"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {"elements": 64}
            or workload.get("measurement") != measurement
            or SINGLE_POINT_CROSSOVER_MIN_PARENT_LENGTH != 2
            or SINGLE_POINT_CROSSOVER_MAX_VALID_INPUT_LENGTH != 64
            or SINGLE_POINT_CROSSOVER_MAX_INPUT_LENGTH != 66
            or SINGLE_POINT_CROSSOVER_MAX_OUTPUT_ELEMENTS != 62
            or SINGLE_POINT_CROSSOVER_INVALID_RESULT != -1
            or SINGLE_POINT_CROSSOVER_OUTPUT_ERROR != -2
            or not isinstance(cases, list)
            or len(case_ids) != len(SINGLE_POINT_CROSSOVER_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != SINGLE_POINT_CROSSOVER_CASE_IDS
            or not isinstance(abi_cases, list)
            or len(abi_ids) != len(SINGLE_POINT_CROSSOVER_ABI_CASE_IDS)
            or len(abi_ids) != len(set(abi_ids))
            or set(abi_ids) != SINGLE_POINT_CROSSOVER_ABI_CASE_IDS):
        raise ValueError("single_point_crossover workload metadata or case IDs do not match the reviewed contract")

    readme = (ROOT / "benchmarks" / "s" / "single_point_crossover" / "README.md").read_text(
        encoding="utf-8")
    if source["url"] not in readme or "random cut an input" not in readme:
        raise ValueError("single_point_crossover README is missing its pinned source or deterministic-cut semantics")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case in cases:
        encode_case(case, "single_point_crossover", absolute_tolerance, relative_tolerance)

    abi_by_id = {case["id"]: case for case in abi_cases}
    for case in abi_cases:
        values = _decode_single_point_crossover_abi_values(case.get("input_values"))
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        if (not values or len(values) > SINGLE_POINT_CROSSOVER_MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= 64
                or type(output_is_null) is not bool):
            raise ValueError(f"single_point_crossover ABI input/output framing is invalid for {case.get('id')}")
        expected_result, _expected_output = single_point_crossover_expected_abi_result(
            values, capacity, output_is_null)
        if type(case.get("expected_result")) is not int or case["expected_result"] != expected_result:
            raise ValueError(f"single_point_crossover ABI probe mismatch: {case.get('id')}")
    if (abi_by_id["invalid_input_before_null_output"].get("output_is_null") is not True
            or abi_by_id["valid_input_null_output"].get("output_is_null") is not True
            or abi_by_id["valid_input_short_output_capacity"].get("output_capacity") != 3
            or any(abi_by_id[name]["expected_result"] != SINGLE_POINT_CROSSOVER_INVALID_RESULT for name in (
                "nonfinite_nan_gene", "nonfinite_positive_infinity_gene",
                "nonfinite_negative_infinity_gene"))):
        raise ValueError("single_point_crossover ABI workload is missing reviewed invalid, null, capacity, or nonfinite cases")


def validate_quaternions_workload(workload: dict) -> None:
    """Validate the three pinned C quaternion operations and ABI probes."""
    source = {
        "repository": "TheAlgorithms/C",
        "commit": "e5dad3fa8def3726ec850ca66a7f51521f8ad393",
        "path": "geometry/quaternions.c",
        "header_path": "geometry/geometry_datatypes.h",
        "methods": ["quat_from_euler", "euler_from_quat", "quaternion_multiply"],
        "url": "https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/geometry/quaternions.c",
        "header_url": "https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/geometry/geometry_datatypes.h",
    }
    contract = {
        "operation_0_euler_to_quaternion": "Input [0, yaw, pitch, roll] in radians; assign the values by name to the C euler fields, cast each angle to binary32, and apply the pinned cosf/sinf half-angle formulas. Return [w, q1, q2, q3].",
        "operation_1_quaternion_to_euler": "Input [1, w, q1, q2, q3]; cast components to binary32; require each in [-1,1], squared norm within 1e-6 of one under binary32 sum/product steps, and the source binary32 pitch argument in [-1,1]. Return [roll, pitch, yaw] in radians.",
        "operation_1_pitch": "Preserve executable C expression asinf(2.f * (w*q2 + q1*q3)); this is a plus sign even though the adjacent Doxygen formula differs.",
        "operation_2_hamilton_product": "Input [2, aw, a1, a2, a3, bw, b1, b2, b3]; cast quaternion components to binary32 and return scalar-first [w, q1, q2, q3] using the pinned left-to-right Hamilton formulas. Operands need not be normalized.",
        "numeric_semantics": "The ABI transports finite binary64 numbers; operation data is rounded to binary32 before source calculations, all source-style arithmetic and trig results are binary32, then outputs are widened to binary64.",
        "errors": "Invalid input returns -1. Null or insufficient output capacity returns -2 after input validation. Errors write no output.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": {
            "operation_0": "[0, yaw, pitch, roll]",
            "operation_1": "[1, w, q1, q2, q3]",
            "operation_2": "[2, aw, a1, a2, a3, bw, b1, b2, b3]",
        },
        "operation_range": [0, 2],
        "operation_values": [0, 1, 2],
        "maximum_valid_length": 9,
        "maximum_parseable_length": QUATERNIONS_MAX_INPUT_LENGTH,
        "euler_angle_range_radians": [-3.0, 3.0],
        "product_component_range_before_binary32_cast": [-1.0, 1.0],
        "conversion_component_range_after_binary32_cast": [-1.0, 1.0],
        "conversion_squared_norm_tolerance": QUATERNIONS_NORMALIZATION_TOLERANCE,
        "conversion_pitch_argument_range_after_binary32_operations": [-1.0, 1.0],
        "invalid_input_result": QUATERNIONS_INVALID_RESULT,
        "null_input_result": QUATERNIONS_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "operation_output_lengths": {"0": 4, "1": 3, "2": 4},
        "maximum_elements": QUATERNIONS_MAX_OUTPUT_ELEMENTS,
        "encoding": "Widened binary32 source result values; operation 0 and 2 are [w,q1,q2,q3], operation 1 is [roll,pitch,yaw].",
        "success_result": "number of output float64 elements",
        "invalid_input_result": QUATERNIONS_INVALID_RESULT,
        "null_output_result": QUATERNIONS_OUTPUT_ERROR,
        "insufficient_output_capacity_result": QUATERNIONS_OUTPUT_ERROR,
        "error_precedence": "Input validation precedes output null/capacity checks.",
        "no_write_on_error": True,
        "absolute_tolerance": QUATERNIONS_ABSOLUTE_TOLERANCE,
        "relative_tolerance": QUATERNIONS_RELATIVE_TOLERANCE,
        "operation_2_result_range": [-4.0, 4.0],
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": QUATERNIONS_ABSOLUTE_TOLERANCE,
        "relative_tolerance": QUATERNIONS_RELATIVE_TOLERANCE,
    }
    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    case_ids = ([case.get("id") for case in cases if isinstance(case, dict)]
                if isinstance(cases, list) else [])
    abi_ids = ([case.get("id") for case in abi_cases if isinstance(case, dict)]
               if isinstance(abi_cases, list) else [])
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-c-quaternions-f64-slice-io-v1"
            or workload.get("algorithm") != "quaternions"
            or workload.get("function_symbol") != "quaternions"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {
                "elements": QUATERNIONS_MAX_OUTPUT_ELEMENTS,
                "meaning": "Largest result is a four-element widened binary32 quaternion.",
            }
            or workload.get("measurement") != measurement
            or QUATERNIONS_MAX_INPUT_LENGTH != 10
            or QUATERNIONS_MAX_OUTPUT_ELEMENTS != 4
            or QUATERNIONS_INVALID_RESULT != -1
            or QUATERNIONS_OUTPUT_ERROR != -2
            or QUATERNIONS_ABSOLUTE_TOLERANCE != 1e-6
            or QUATERNIONS_RELATIVE_TOLERANCE != 0.0
            or not isinstance(cases, list)
            or len(case_ids) != len(QUATERNIONS_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != QUATERNIONS_CASE_IDS
            or not isinstance(abi_cases, list)
            or len(abi_ids) != len(QUATERNIONS_ABI_CASE_IDS)
            or len(abi_ids) != len(set(abi_ids))
            or set(abi_ids) != QUATERNIONS_ABI_CASE_IDS):
        raise ValueError("quaternions workload metadata or case IDs differ from its contract")

    readme = (ROOT / "benchmarks" / "q" / "quaternions" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or source["header_url"] not in readme
            or "[0, yaw, pitch, roll]" not in readme
            or "[w, q1, q2, q3]" not in readme
            or "plus-sign" not in readme):
        raise ValueError("quaternions README is missing its pinned source or operation semantics")

    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case in cases:
        if type(case.get("expected_result")) is not int:
            raise ValueError(f"quaternions expected_result must be an integer: {case.get('id')}")
        encode_case(case, "quaternions", absolute_tolerance, relative_tolerance)

    abi_by_id = {case["id"]: case for case in abi_cases}
    for case in abi_cases:
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length", len(values) if isinstance(values, list) else None)
        expected_output = case.get("expected_output")
        if (not isinstance(values, list)
                or not 1 <= len(values) <= QUATERNIONS_MAX_INPUT_LENGTH
                or any(type(value) not in (int, float) or not math.isfinite(float(value))
                       for value in values)
                or type(capacity) is not int or not 0 <= capacity <= QUATERNIONS_MAX_OUTPUT_ELEMENTS
                or type(output_is_null) is not bool or type(input_is_null) is not bool
                or type(input_length) is not int or input_length != len(values)
                or type(case.get("expected_result")) is not int
                or not isinstance(expected_output, list)):
            raise ValueError(f"quaternions ABI framing is invalid: {case.get('id')}")
        result, output = quaternions_expected_abi_result(
            values, capacity, output_is_null, input_is_null, input_length)
        if (case["expected_result"] != result or len(expected_output) != len(output)
                or any(type(actual) not in (int, float)
                       or abs(float(actual) - expected)
                       > absolute_tolerance + relative_tolerance * abs(expected)
                       for actual, expected in zip(expected_output, output))):
            raise ValueError(f"quaternions ABI fixture mismatch: {case.get('id')}")

    if (abi_by_id["short_output_op0"].get("output_capacity") != 3
            or abi_by_id["short_output_op1"].get("output_capacity") != 2
            or abi_by_id["short_output_op2"].get("output_capacity") != 3
            or any(abi_by_id[name].get("expected_result") != QUATERNIONS_OUTPUT_ERROR
                   for name in ("short_output_op0", "short_output_op1", "short_output_op2",
                                "null_output_op1"))
            or abi_by_id["null_output_op1"].get("output_is_null") is not True
            or abi_by_id["invalid_input_precedes_null_output"].get("output_is_null") is not True
            or abi_by_id["invalid_input_precedes_null_output"].get("output_capacity") != 0
            or abi_by_id["invalid_input_precedes_null_output"].get("expected_result")
            != QUATERNIONS_INVALID_RESULT
            or abi_by_id["null_input"].get("input_is_null") is not True
            or abi_by_id["null_input"].get("expected_result") != QUATERNIONS_INVALID_RESULT):
        raise ValueError("quaternions ABI fixtures are missing operation-specific capacity or precedence cases")


RHUMB_DISTANCE_CASE_IDS = frozenset({
    "identical_point", "one_degree_equator", "east_west_at_45_degrees",
    "meridional_path", "diagonal_path", "antimeridian_eastward",
    "antimeridian_westward", "positive_half_turn_strict_boundary",
    "negative_half_turn_strict_boundary", "near_zero_mercator_delta_uses_cosine_branch",
    "mercator_delta_above_threshold", "latitude_and_longitude_boundaries",
    "latitude_above_domain", "longitude_above_domain", "short_input",
    "trailing_input_value",
})
RHUMB_DISTANCE_ABI_CASE_IDS = frozenset({
    "valid_input_null_output", "valid_input_short_output_capacity",
    "invalid_input_precedes_null_output", "null_input_positive_length",
})


def validate_rhumb_distance_workload(workload: dict) -> None:
    """Pin the Rust rhumb-line formula and null/error ABI probes."""
    source = {
        "repository": "TheAlgorithms/Rust",
        "commit": "fed66cb0c74c4a939ec5163648458a8c2b46fd4c",
        "path": "src/navigation/rhumbline.rs",
        "symbol": "rhumb_dist",
        "url": "https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs",
        "role": "algorithm",
    }
    contract = {
        "operation": "Compute the pinned rhumb-line distance in meters between two geographic coordinates.",
        "formula": "Preserve source operation order: radians; one longitude-delta wrap only when strictly outside +/-PI; Mercator latitude difference; q = del_phi/del_psi only when abs(del_psi) > 1e-12, otherwise cos(phi1); sqrt(del_phi^2 + (q*del_lambda)^2) * 6371000.0.",
        "distance_unit": "meters",
        "longitude_wrap": "One subtraction/addition of 2*PI for del_lambda strictly greater than PI or strictly less than -PI; exact +/-PI is unchanged.",
        "near_zero_mercator_delta": "Use cos(phi1) when abs(del_psi) <= 1e-12.",
        "errors": "Reject malformed, nonfinite, or out-of-domain input with -1 before output checks. A null output or capacity below one returns -2 and writes nothing.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[latitude1_degrees, longitude1_degrees, latitude2_degrees, longitude2_degrees]",
        "exact_length": RHUMB_DISTANCE_MAX_INPUT_LENGTH,
        "maximum_valid_input_length": RHUMB_DISTANCE_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": RHUMB_DISTANCE_MAX_PARSEABLE_INPUT_LENGTH,
        "latitude_range_degrees": [RHUMB_DISTANCE_MIN_LATITUDE, RHUMB_DISTANCE_MAX_LATITUDE],
        "longitude_range_degrees": [RHUMB_DISTANCE_MIN_LONGITUDE, RHUMB_DISTANCE_MAX_LONGITUDE],
        "all_values_finite": True,
        "invalid_input_result": RHUMB_DISTANCE_INVALID_RESULT,
        "null_input_result": RHUMB_DISTANCE_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "One rhumb-line distance in meters.",
        "maximum_elements": RHUMB_DISTANCE_MAX_OUTPUT_ELEMENTS,
        "success_result": RHUMB_DISTANCE_MAX_OUTPUT_ELEMENTS,
        "invalid_input_result": RHUMB_DISTANCE_INVALID_RESULT,
        "invalid_output_buffer_result": RHUMB_DISTANCE_OUTPUT_ERROR,
        "null_output_result": RHUMB_DISTANCE_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or out-of-domain input is rejected before output pointer or capacity checks.",
        "absolute_tolerance": 1e-7,
        "relative_tolerance": 1e-12,
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": 1e-7,
        "relative_tolerance": 1e-12,
    }
    cases, abi_cases = workload.get("cases"), workload.get("abi_cases")
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    abi_ids = [case.get("id") for case in abi_cases if isinstance(case, dict)] if isinstance(abi_cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-rust-rhumb-distance-float64-slice-io-v1"
            or workload.get("algorithm") != "rhumb_distance"
            or workload.get("function_symbol") != "rhumb_distance"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != {"elements": RHUMB_DISTANCE_MAX_OUTPUT_ELEMENTS,
                                               "meaning": "One output distance."}
            or workload.get("measurement") != measurement
            or RHUMB_DISTANCE_EARTH_RADIUS != 6_371_000.0
            or RHUMB_DISTANCE_MAX_INPUT_LENGTH != 4
            or RHUMB_DISTANCE_MAX_PARSEABLE_INPUT_LENGTH != 5
            or RHUMB_DISTANCE_MAX_OUTPUT_ELEMENTS != 1
            or RHUMB_DISTANCE_INVALID_RESULT != -1 or RHUMB_DISTANCE_OUTPUT_ERROR != -2
            or not isinstance(cases, list) or len(case_ids) != len(RHUMB_DISTANCE_CASE_IDS)
            or len(case_ids) != len(set(case_ids)) or set(case_ids) != RHUMB_DISTANCE_CASE_IDS
            or not isinstance(abi_cases, list) or len(abi_ids) != len(RHUMB_DISTANCE_ABI_CASE_IDS)
            or len(abi_ids) != len(set(abi_ids)) or set(abi_ids) != RHUMB_DISTANCE_ABI_CASE_IDS):
        raise ValueError("rhumb_distance workload metadata or case IDs differ from the reviewed contract")

    readme = (ROOT / "benchmarks" / "r" / "rhumb_distance" / "README.md").read_text(encoding="utf-8")
    if (source["url"] not in readme or "wrap the longitude delta once" not in readme
            or "abs(del_psi) > 1e-12" not in readme or "6,371,000" not in readme):
        raise ValueError("rhumb_distance README is missing its source or formula semantics")

    absolute_tolerance, relative_tolerance = tolerances(workload)
    if absolute_tolerance != 1e-7 or relative_tolerance != 1e-12:
        raise ValueError("rhumb_distance tolerances differ from the reviewed meter contract")
    for case in cases:
        encode_case(case, "rhumb_distance", absolute_tolerance, relative_tolerance)

    abi_by_id = {case["id"]: case for case in abi_cases}
    for case in abi_cases:
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        input_length = case.get("input_length")
        expected_output = case.get("expected_output", [])
        if (not isinstance(values, list)
                or type(input_length) is not int or not 0 <= input_length <= RHUMB_DISTANCE_MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= RHUMB_DISTANCE_MAX_OUTPUT_ELEMENTS
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and (values or input_length == 0)
                or not input_is_null and input_length != len(values)
                or input_is_null and output_is_null
                or any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values)
                or type(case.get("expected_result")) is not int
                or not isinstance(expected_output, list)):
            raise ValueError(f"rhumb_distance ABI framing is invalid: {case.get('id')}")
        result, output = rhumb_distance_oracle(values, capacity, output_is_null, input_is_null, input_length)
        if (case["expected_result"] != result or len(expected_output) != len(output)
                or any(abs(float(actual) - reference) > absolute_tolerance + relative_tolerance * abs(reference)
                       for actual, reference in zip(expected_output, output))):
            raise ValueError(f"rhumb_distance ABI fixture mismatch: {case.get('id')}")
    if (abi_by_id["null_input_positive_length"].get("input_values") != []
            or abi_by_id["null_input_positive_length"].get("input_length") != 4
            or abi_by_id["null_input_positive_length"].get("input_is_null") is not True
            or abi_by_id["invalid_input_precedes_null_output"].get("expected_result") != RHUMB_DISTANCE_INVALID_RESULT
            or abi_by_id["valid_input_null_output"].get("expected_result") != RHUMB_DISTANCE_OUTPUT_ERROR
            or abi_by_id["valid_input_short_output_capacity"].get("expected_result") != RHUMB_DISTANCE_OUTPUT_ERROR):
        raise ValueError("rhumb_distance ABI probes are missing null-pointer or error-precedence coverage")


RHUMB_BEARING_CASE_IDS = frozenset({
    "identical_point", "eastward_equator", "westward_equator", "northward_meridian",
    "southward_meridian", "diagonal_path", "antimeridian_eastward", "antimeridian_westward",
    "positive_half_turn_strict_boundary", "negative_half_turn_strict_boundary",
    "latitude_domain_boundaries", "latitude_above_domain", "longitude_above_domain",
    "short_input", "trailing_input_value",
})
RHUMB_DESTINATION_CASE_IDS = frozenset({
    "zero_distance_identity", "northward_equator", "eastward_equator_unnormalized_longitude",
    "southward_from_midlatitude", "westward_from_midlatitude", "diagonal_destination",
    "near_zero_del_psi_fallback", "east_west_at_high_latitude", "bearing_360_source_trigonometry",
    "maximum_distance_and_latitude", "latitude_above_domain", "longitude_above_domain",
    "negative_distance", "distance_above_domain", "bearing_above_domain", "short_input",
    "trailing_input_value",
})
RHUMB_SIBLING_ABI_CASE_IDS = frozenset({
    "valid_input_null_output", "valid_input_short_output_capacity",
    "invalid_input_before_null_output", "null_input_positive_length",
})


def _validate_rhumb_sibling_workload(workload: dict, algorithm: str) -> None:
    source_symbol = algorithm
    source_url = ("https://github.com/TheAlgorithms/Rust/blob/"
                  "fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs")
    source = {
        "repository": "TheAlgorithms/Rust",
        "commit": "fed66cb0c74c4a939ec5163648458a8c2b46fd4c",
        "path": "src/navigation/rhumbline.rs",
        "url": source_url,
        "role": "algorithm",
        "symbol": source_symbol,
    }
    if algorithm == "rhumb_bearing":
        case_ids = RHUMB_BEARING_CASE_IDS
        absolute_tolerance, relative_tolerance = 1e-10, 1e-12
        contract = {
            "operation": "Compute the pinned rhumb-line bearing in degrees between two geographic coordinates.",
            "formula": "Convert latitudes to radians; compute longitude delta in radians and wrap it once only when strictly outside +/-PI; compute del_psi = ln(tan(phi2/2+PI/4)/tan(phi1/2+PI/4)); bearing = atan2(del_lambda, del_psi) * 180 / PI; return (bearing + 360) % 360.",
            "bearing_range_degrees": "[0,360)",
            "longitude_wrap": "Strict one-wrap; exact +/-PI is unchanged.",
            "errors": "Malformed, nonfinite, or out-of-domain input returns -1 before output checks. Null or insufficient output returns -2 without writes.",
        }
        input_spec = {
            "kind": "finite_float64_array",
            "encoding": "[latitude1_degrees, longitude1_degrees, latitude2_degrees, longitude2_degrees]",
            "exact_length": RHUMB_BEARING_MAX_INPUT_LENGTH,
            "maximum_valid_input_length": RHUMB_BEARING_MAX_INPUT_LENGTH,
            "maximum_parseable_input_length": RHUMB_BEARING_MAX_PARSEABLE_INPUT_LENGTH,
            "latitude_range_degrees": [RHUMB_BEARING_MIN_LATITUDE, RHUMB_BEARING_MAX_LATITUDE],
            "longitude_range_degrees": [RHUMB_BEARING_MIN_LONGITUDE, RHUMB_BEARING_MAX_LONGITUDE],
            "all_values_finite": True,
            "invalid_input_result": RHUMB_BEARING_INVALID_RESULT,
            "null_input_result": RHUMB_BEARING_INVALID_RESULT,
        }
        output_spec = {
            "kind": "float64_array",
            "encoding": "One rhumb bearing in degrees normalized into [0,360).",
            "maximum_elements": RHUMB_BEARING_MAX_OUTPUT_ELEMENTS,
            "success_result": RHUMB_BEARING_MAX_OUTPUT_ELEMENTS,
            "invalid_input_result": RHUMB_BEARING_INVALID_RESULT,
            "invalid_output_buffer_result": RHUMB_BEARING_OUTPUT_ERROR,
            "null_output_result": RHUMB_BEARING_OUTPUT_ERROR,
            "no_write_on_error": True,
            "error_precedence": "Malformed or out-of-domain input is rejected before output pointer or capacity checks.",
            "absolute_tolerance": absolute_tolerance,
            "relative_tolerance": relative_tolerance,
        }
        workspace = {"elements": RHUMB_BEARING_MAX_OUTPUT_ELEMENTS, "meaning": "One output bearing."}
        readme_phrases = ("wrap the longitude delta once", "Exact half-turn deltas remain",
                          "(bearing + 360) % 360")
        expected_id = "thealgorithms-rust-rhumb-bearing-float64-slice-io-v1"
        max_input, max_output = RHUMB_BEARING_MAX_INPUT_LENGTH, RHUMB_BEARING_MAX_OUTPUT_ELEMENTS
        repetitions = 1000
        constants_ok = (max_input == 4 and RHUMB_BEARING_MAX_PARSEABLE_INPUT_LENGTH == 5
                        and max_output == 1 and RHUMB_BEARING_INVALID_RESULT == -1
                        and RHUMB_BEARING_OUTPUT_ERROR == -2)
    elif algorithm == "rhumb_destination":
        case_ids = RHUMB_DESTINATION_CASE_IDS
        absolute_tolerance, relative_tolerance = 1e-10, 1e-12
        contract = {
            "operation": "Compute the destination latitude and longitude after traveling a distance at a bearing along a rhumb line.",
            "formula": "Preserve source order: del=distance/6371000; radians; del_phi=del*cos(theta); clamp phi1+del_phi to +/-PI/2; compute del_psi; q=del_phi/del_psi only when abs(del_psi)>1e-12, otherwise cos(phi1); del_lambda=del*sin(theta)/q; add to lambda1; return [phi2*180/PI,lambda2*180/PI].",
            "destination_longitude": "Return the source longitude result without normalization.",
            "safe_domain_note": "The bounded latitude and distance ranges keep the computed latitude within +/-82.7 degrees, so the source clamp is present but inactive and the Mercator terms remain finite.",
            "errors": "Malformed, nonfinite, or out-of-domain input returns -1 before output checks. Null or insufficient output returns -2 without writes.",
        }
        input_spec = {
            "kind": "finite_float64_array",
            "encoding": "[latitude_degrees, longitude_degrees, distance_meters, bearing_degrees]",
            "exact_length": RHUMB_DESTINATION_MAX_INPUT_LENGTH,
            "maximum_valid_input_length": RHUMB_DESTINATION_MAX_INPUT_LENGTH,
            "maximum_parseable_input_length": RHUMB_DESTINATION_MAX_PARSEABLE_INPUT_LENGTH,
            "latitude_range_degrees": [RHUMB_DESTINATION_MIN_LATITUDE, RHUMB_DESTINATION_MAX_LATITUDE],
            "longitude_range_degrees": [RHUMB_DESTINATION_MIN_LONGITUDE, RHUMB_DESTINATION_MAX_LONGITUDE],
            "distance_range_meters": [RHUMB_DESTINATION_MIN_DISTANCE, RHUMB_DESTINATION_MAX_DISTANCE],
            "bearing_range_degrees": [RHUMB_DESTINATION_MIN_BEARING, RHUMB_DESTINATION_MAX_BEARING],
            "all_values_finite": True,
            "invalid_input_result": RHUMB_DESTINATION_INVALID_RESULT,
            "null_input_result": RHUMB_DESTINATION_INVALID_RESULT,
        }
        output_spec = {
            "kind": "float64_array",
            "encoding": "[destination_latitude_degrees, destination_longitude_degrees]; longitude is not normalized.",
            "maximum_elements": RHUMB_DESTINATION_MAX_OUTPUT_ELEMENTS,
            "success_result": RHUMB_DESTINATION_MAX_OUTPUT_ELEMENTS,
            "invalid_input_result": RHUMB_DESTINATION_INVALID_RESULT,
            "invalid_output_buffer_result": RHUMB_DESTINATION_OUTPUT_ERROR,
            "null_output_result": RHUMB_DESTINATION_OUTPUT_ERROR,
            "no_write_on_error": True,
            "error_precedence": "Malformed or out-of-domain input is rejected before output pointer or capacity checks.",
            "absolute_tolerance": absolute_tolerance,
            "relative_tolerance": relative_tolerance,
        }
        workspace = {"elements": RHUMB_DESTINATION_MAX_OUTPUT_ELEMENTS,
                     "meaning": "Destination latitude and longitude."}
        readme_phrases = ("longitude left unnormalized", "keeps the computed latitude",
                          "capacity below two")
        expected_id = "thealgorithms-rust-rhumb-destination-float64-slice-io-v1"
        max_input, max_output = RHUMB_DESTINATION_MAX_INPUT_LENGTH, RHUMB_DESTINATION_MAX_OUTPUT_ELEMENTS
        repetitions = 1000
        constants_ok = (RHUMB_DESTINATION_EARTH_RADIUS == 6_371_000.0 and max_input == 4
                        and RHUMB_DESTINATION_MAX_PARSEABLE_INPUT_LENGTH == 5 and max_output == 2
                        and RHUMB_DESTINATION_INVALID_RESULT == -1
                        and RHUMB_DESTINATION_OUTPUT_ERROR == -2)
    else:
        raise ValueError(f"no rhumb sibling validator for {algorithm}")

    cases, abi_cases = workload.get("cases"), workload.get("abi_cases")
    case_id_list = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    abi_id_list = [case.get("id") for case in abi_cases if isinstance(case, dict)] if isinstance(abi_cases, list) else []
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": repetitions,
        "absolute_tolerance": absolute_tolerance,
        "relative_tolerance": relative_tolerance,
    }
    if (workload.get("schema_version") != 1 or workload.get("id") != expected_id
            or workload.get("algorithm") != algorithm or workload.get("function_symbol") != algorithm
            or workload.get("pinned_source") != source or workload.get("contract") != contract
            or workload.get("input") != input_spec or workload.get("output") != output_spec
            or workload.get("workspace") != workspace or workload.get("measurement") != measurement
            or not constants_ok or not isinstance(cases, list) or len(case_id_list) != len(case_ids)
            or len(case_id_list) != len(set(case_id_list)) or set(case_id_list) != case_ids
            or not isinstance(abi_cases, list) or len(abi_id_list) != len(RHUMB_SIBLING_ABI_CASE_IDS)
            or len(abi_id_list) != len(set(abi_id_list)) or set(abi_id_list) != RHUMB_SIBLING_ABI_CASE_IDS):
        raise ValueError(f"{algorithm} workload metadata or case IDs differ from its reviewed contract")

    readme = (ROOT / "benchmarks" / "r" / algorithm / "README.md").read_text(encoding="utf-8")
    if source_url not in readme or any(phrase.lower() not in readme.lower() for phrase in readme_phrases):
        raise ValueError(f"{algorithm} README is missing its pinned source or formula semantics")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case in cases:
        encode_case(case, algorithm, absolute_tolerance, relative_tolerance)

    abi_by_id = {case["id"]: case for case in abi_cases}
    for case in abi_cases:
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        input_length = case.get("input_length")
        expected_output = case.get("expected_output", [])
        if (not isinstance(values, list) or type(input_length) is not int
                or not 0 <= input_length <= max_input + 1
                or type(capacity) is not int or not 0 <= capacity <= max_output
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and (values or input_length == 0)
                or not input_is_null and input_length != len(values)
                or input_is_null and output_is_null
                or any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values)
                or type(case.get("expected_result")) is not int or not isinstance(expected_output, list)):
            raise ValueError(f"{algorithm} ABI framing is invalid: {case.get('id')}")
        result, output = ORACLES[algorithm](values, capacity, output_is_null, input_is_null, input_length)
        if (case["expected_result"] != result or len(expected_output) != len(output)
                or any(abs(float(actual) - reference)
                       > absolute_tolerance + relative_tolerance * abs(reference)
                       for actual, reference in zip(expected_output, output))):
            raise ValueError(f"{algorithm} ABI fixture mismatch: {case.get('id')}")
    if (abi_by_id["null_input_positive_length"].get("input_values") != []
            or abi_by_id["null_input_positive_length"].get("input_length") != max_input
            or abi_by_id["null_input_positive_length"].get("input_is_null") is not True
            or abi_by_id["invalid_input_before_null_output"].get("expected_result") != -1
            or abi_by_id["valid_input_null_output"].get("expected_result") != -2
            or abi_by_id["valid_input_short_output_capacity"].get("expected_result") != -2):
        raise ValueError(f"{algorithm} ABI probes are missing null-pointer or error-precedence coverage")


def validate_rhumb_bearing_workload(workload: dict) -> None:
    _validate_rhumb_sibling_workload(workload, "rhumb_bearing")


def validate_rhumb_destination_workload(workload: dict) -> None:
    _validate_rhumb_sibling_workload(workload, "rhumb_destination")


def validate_median_of_running_array_double_workload(workload: dict) -> None:
    source_commit = "e43ec3897e48f23843972d02cd05a5bb1b6864a2"
    source_base = "https://github.com/TheAlgorithms/Java/blob/" + source_commit + "/"
    pinned_sources = [
        {
            "repository": "TheAlgorithms/Java", "commit": source_commit,
            "path": "src/main/java/com/thealgorithms/misc/MedianOfRunningArrayDouble.java",
            "symbol": "MedianOfRunningArrayDouble.calculateAverage",
            "url": source_base + "src/main/java/com/thealgorithms/misc/MedianOfRunningArrayDouble.java",
        },
        {
            "repository": "TheAlgorithms/Java", "commit": source_commit,
            "path": "src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java",
            "symbol": "MedianOfRunningArray.insert/getMedian",
            "url": source_base + "src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java",
        },
    ]
    contract = {
        "operation": "Return the median after every insertion into a fresh stream.",
        "insertion": "If minHeap is nonempty and sample < minHeap.peek(), insert into maxHeap; otherwise insert into minHeap.",
        "rebalancing": "Move one root only when one heap has more than one extra element.",
        "odd_prefix": "Return the root of the larger heap; heap ordering and the size difference of one make it the sorted center.",
        "even_prefix": "Compute (maxHeap.peek() + minHeap.peek()) / 2.0d in that operation order.",
        "double_ordering": "Use Java Double.compare ordering for finite values, including -0.0 < +0.0; reject NaN and infinities.",
        "oracle": "Sort each prefix by Java finite Double order, including signed-zero ordering, then select the center or apply the pinned even average.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[sample_count, sample_0, ..., sample_(sample_count-1)]",
        "sample_count_range": [MEDIAN_RUNNING_DOUBLE_MIN_SAMPLE_COUNT,
                               MEDIAN_RUNNING_DOUBLE_MAX_SAMPLE_COUNT],
        "sample_range": [MEDIAN_RUNNING_DOUBLE_MIN_SAMPLE, MEDIAN_RUNNING_DOUBLE_MAX_SAMPLE],
        "maximum_valid_input_length": 65,
        "maximum_parseable_input_length": MEDIAN_RUNNING_DOUBLE_MAX_PARSEABLE_INPUT_LENGTH,
        "exact_packed_shape": "Exactly 1 + sample_count binary64 values; sample_count is an exact integer.",
        "headers_must_be_exact_integers": True,
        "samples_must_be_finite": True,
        "invalid_input_result": MEDIAN_RUNNING_DOUBLE_INVALID_RESULT,
        "null_input_result": MEDIAN_RUNNING_DOUBLE_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "One prefix median per sample, in insertion order.",
        "maximum_elements": MEDIAN_RUNNING_DOUBLE_MAX_OUTPUT_ELEMENTS,
        "success_result": "sample_count",
        "invalid_input_result": MEDIAN_RUNNING_DOUBLE_INVALID_RESULT,
        "invalid_output_buffer_result": MEDIAN_RUNNING_DOUBLE_OUTPUT_ERROR,
        "null_output_result": MEDIAN_RUNNING_DOUBLE_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    workspace = {"elements": MEDIAN_RUNNING_DOUBLE_MAX_OUTPUT_ELEMENTS,
                 "meaning": "One median per input sample."}
    measurement = {
        "comparison_model": "float64_slice_io_call", "sample_count": 5,
        "warmup_rounds": 1, "repetitions_per_sample": 1000,
        "absolute_tolerance": 0.0, "relative_tolerance": 0.0,
    }
    case_ids = {
        "single_value", "increasing_stream", "decreasing_stream", "negative_even_average",
        "positive_even_average", "odd_prefix_upper_heap_root", "odd_prefix_lower_heap_root",
        "negative_zero_sorts_below_positive_zero", "signed_zero_even_average", "duplicates",
        "sample_boundaries", "maximum_stream_length", "empty_stream", "fractional_count_header",
        "count_above_limit", "missing_sample", "trailing_input_value", "sample_below_domain",
        "sample_above_domain",
    }
    abi_ids = {"valid_input_null_output", "valid_input_short_output_capacity",
               "invalid_input_before_null_output", "null_input_positive_length"}
    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    case_keys = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    abi_keys = [case.get("id") for case in abi_cases if isinstance(case, dict)] if isinstance(abi_cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-java-median-of-running-array-double-float64-slice-io-v1"
            or workload.get("algorithm") != "median_of_running_array_double"
            or workload.get("function_symbol") != "median_of_running_array_double"
            or workload.get("pinned_sources") != pinned_sources
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or MEDIAN_RUNNING_DOUBLE_MIN_SAMPLE_COUNT != 1
            or MEDIAN_RUNNING_DOUBLE_MAX_SAMPLE_COUNT != 64
            or MEDIAN_RUNNING_DOUBLE_MIN_SAMPLE != -1_000_000.0
            or MEDIAN_RUNNING_DOUBLE_MAX_SAMPLE != 1_000_000.0
            or MEDIAN_RUNNING_DOUBLE_MAX_PARSEABLE_INPUT_LENGTH != 66
            or len(case_keys) != len(case_ids) or len(set(case_keys)) != len(case_keys)
            or set(case_keys) != case_ids
            or len(abi_keys) != len(abi_ids) or len(set(abi_keys)) != len(abi_keys)
            or set(abi_keys) != abi_ids):
        raise ValueError("median_of_running_array_double metadata differs from its reviewed contract")
    readme = (ROOT / "benchmarks" / "m" / "median_of_running_array_double" / "README.md").read_text(
        encoding="utf-8")
    if any(source["url"] not in readme for source in pinned_sources):
        raise ValueError("median_of_running_array_double README is missing its pinned source links")

    for key, fixtures in (("cases", cases), ("abi_cases", abi_cases)):
        for case in fixtures:
            case_id = case["id"]
            raw_values = case.get("input_values")
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(raw_values) if isinstance(raw_values, list) else None)
            capacity = case.get("output_capacity", MEDIAN_RUNNING_DOUBLE_MAX_OUTPUT_ELEMENTS)
            if (not isinstance(raw_values, list)
                    or len(raw_values) > MEDIAN_RUNNING_DOUBLE_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in raw_values)
                    or type(input_is_null) is not bool or type(output_is_null) is not bool
                    or type(input_length) is not int or type(capacity) is not int
                    or not 0 <= capacity <= MEDIAN_RUNNING_DOUBLE_MAX_OUTPUT_ELEMENTS):
                raise ValueError(f"median_of_running_array_double framing is invalid: {case_id}")
            values = [float(value) for value in raw_values]
            if any(not math.isfinite(value) for value in values):
                raise ValueError(f"median_of_running_array_double input must be finite: {case_id}")
            result, expected = median_of_running_array_double_oracle(
                values, capacity, output_is_null, input_is_null, input_length)
            raw_expected = case.get("expected_output")
            if (type(case.get("expected_result")) is not int or case["expected_result"] != result
                    or not isinstance(raw_expected, list)
                    or not _same_float64_sequence(raw_expected, expected)):
                raise ValueError(f"median_of_running_array_double fixture mismatch: {case_id}")
            if key == "cases" and (input_is_null or output_is_null
                                    or capacity != MEDIAN_RUNNING_DOUBLE_MAX_OUTPUT_ELEMENTS
                                    or input_length != len(raw_values)):
                raise ValueError(f"median_of_running_array_double semantic framing changed: {case_id}")
            if case_id == "null_input_positive_length" and (
                    not input_is_null or raw_values or input_length <= 0):
                raise ValueError("median_of_running_array_double null-input ABI probe changed")


def validate_median_of_running_array_float_workload(workload: dict) -> None:
    source_commit = "e43ec3897e48f23843972d02cd05a5bb1b6864a2"
    source_base = "https://github.com/TheAlgorithms/Java/blob/" + source_commit + "/"
    pinned_sources = [
        {
            "repository": "TheAlgorithms/Java", "commit": source_commit,
            "path": "src/main/java/com/thealgorithms/misc/MedianOfRunningArrayFloat.java",
            "symbol": "MedianOfRunningArrayFloat.calculateAverage",
            "url": source_base + "src/main/java/com/thealgorithms/misc/MedianOfRunningArrayFloat.java",
        },
        {
            "repository": "TheAlgorithms/Java", "commit": source_commit,
            "path": "src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java",
            "symbol": "MedianOfRunningArray.insert/getMedian",
            "url": source_base + "src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java",
        },
    ]
    contract = {
        "operation": "Return the median after every insertion into a fresh stream.",
        "insertion": "If minHeap is nonempty and sample.compareTo(minHeap.peek()) < 0, insert into maxHeap; otherwise insert into minHeap.",
        "rebalancing": "Move one root only when one heap has more than one extra element.",
        "odd_prefix": "Return the root of the larger heap; heap ordering and size difference of one make it the sorted center.",
        "even_prefix": "Compute (maxHeap.peek() + minHeap.peek()) / 2.0f in that operation order, with binary32 rounding after addition and division.",
        "float_ordering": "Use Java Float.compare ordering for finite values, including -0.0f < +0.0f; reject NaN and infinities.",
        "input_representation": "Every sample is transported as binary64 but must be exactly representable as binary32, preserving signed zero.",
        "oracle": "Sort each prefix by Java finite Float order, including signed-zero ordering; select the center or apply the pinned float32 average.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[sample_count, sample_0, ..., sample_(sample_count-1)]",
        "sample_count_range": [MEDIAN_RUNNING_FLOAT_MIN_SAMPLE_COUNT,
                               MEDIAN_RUNNING_FLOAT_MAX_SAMPLE_COUNT],
        "sample_range": [MEDIAN_RUNNING_FLOAT_MIN_SAMPLE, MEDIAN_RUNNING_FLOAT_MAX_SAMPLE],
        "samples_must_be_finite": True,
        "samples_must_be_exact_binary32": True,
        "exact_packed_shape": "Exactly 1 + sample_count binary64 values; sample_count is an exact integer.",
        "maximum_valid_input_length": 65,
        "maximum_parseable_input_length": MEDIAN_RUNNING_FLOAT_MAX_PARSEABLE_INPUT_LENGTH,
        "headers_must_be_exact_integers": True,
        "invalid_input_result": MEDIAN_RUNNING_FLOAT_INVALID_RESULT,
        "null_input_result": MEDIAN_RUNNING_FLOAT_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "One widened binary32 median per sample, in insertion order.",
        "maximum_elements": MEDIAN_RUNNING_FLOAT_MAX_OUTPUT_ELEMENTS,
        "success_result": "sample_count",
        "invalid_input_result": MEDIAN_RUNNING_FLOAT_INVALID_RESULT,
        "invalid_output_buffer_result": MEDIAN_RUNNING_FLOAT_OUTPUT_ERROR,
        "null_output_result": MEDIAN_RUNNING_FLOAT_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
        "signed_zero_oracle_preserved": True,
    }
    workspace = {"elements": MEDIAN_RUNNING_FLOAT_MAX_OUTPUT_ELEMENTS,
                 "meaning": "One median per input sample."}
    measurement = {
        "comparison_model": "float64_slice_io_call", "sample_count": 5,
        "warmup_rounds": 1, "repetitions_per_sample": 1000,
        "absolute_tolerance": 0.0, "relative_tolerance": 0.0,
    }
    case_ids = {
        "single_value", "increasing_stream", "decreasing_stream", "negative_even_average",
        "positive_even_average", "odd_prefix_upper_heap_root", "odd_prefix_lower_heap_root",
        "negative_zero_sorts_below_positive_zero", "signed_zero_even_average",
        "negative_zero_even_average", "float32_average_rounding", "float32_tie_to_even_average",
        "float32_next_average", "subnormal_average_tie", "sample_boundaries",
        "maximum_stream_length", "maximum_parseable_trailing_value", "empty_stream",
        "fractional_count_header", "count_above_limit",
        "missing_sample", "trailing_input_value", "non_binary32_sample", "sample_below_domain",
        "sample_above_domain",
    }
    abi_ids = {"valid_input_null_output", "valid_input_short_output_capacity",
               "invalid_input_before_null_output", "null_input_positive_length"}
    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    case_keys = [case.get("id") for case in cases if isinstance(case, dict)] if isinstance(cases, list) else []
    abi_keys = [case.get("id") for case in abi_cases if isinstance(case, dict)] if isinstance(abi_cases, list) else []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-java-median-of-running-array-float-float64-slice-io-v1"
            or workload.get("algorithm") != "median_of_running_array_float"
            or workload.get("function_symbol") != "median_of_running_array_float"
            or workload.get("pinned_sources") != pinned_sources
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or MEDIAN_RUNNING_FLOAT_MIN_SAMPLE_COUNT != 1
            or MEDIAN_RUNNING_FLOAT_MAX_SAMPLE_COUNT != 64
            or MEDIAN_RUNNING_FLOAT_MIN_SAMPLE != -1_000_000.0
            or MEDIAN_RUNNING_FLOAT_MAX_SAMPLE != 1_000_000.0
            or MEDIAN_RUNNING_FLOAT_MAX_PARSEABLE_INPUT_LENGTH != 66
            or len(case_keys) != len(case_ids) or len(set(case_keys)) != len(case_keys)
            or set(case_keys) != case_ids
            or len(abi_keys) != len(abi_ids) or len(set(abi_keys)) != len(abi_keys)
            or set(abi_keys) != abi_ids):
        raise ValueError("median_of_running_array_float metadata differs from its reviewed contract")
    readme = (ROOT / "benchmarks" / "m" / "median_of_running_array_float" / "README.md").read_text(
        encoding="utf-8")
    if any(source["url"] not in readme for source in pinned_sources):
        raise ValueError("median_of_running_array_float README is missing its pinned source links")

    for key, fixtures in (("cases", cases), ("abi_cases", abi_cases)):
        for case in fixtures:
            case_id = case["id"]
            raw_values = case.get("input_values")
            input_is_null = case.get("input_is_null", False)
            output_is_null = case.get("output_is_null", False)
            input_length = case.get("input_length", len(raw_values) if isinstance(raw_values, list) else None)
            capacity = case.get("output_capacity", MEDIAN_RUNNING_FLOAT_MAX_OUTPUT_ELEMENTS)
            if (not isinstance(raw_values, list)
                    or len(raw_values) > MEDIAN_RUNNING_FLOAT_MAX_PARSEABLE_INPUT_LENGTH
                    or any(type(value) not in (int, float) for value in raw_values)
                    or type(input_is_null) is not bool or type(output_is_null) is not bool
                    or type(input_length) is not int or type(capacity) is not int
                    or not 0 <= capacity <= MEDIAN_RUNNING_FLOAT_MAX_OUTPUT_ELEMENTS):
                raise ValueError(f"median_of_running_array_float framing is invalid: {case_id}")
            values = [float(value) for value in raw_values]
            if any(not math.isfinite(value) for value in values):
                raise ValueError(f"median_of_running_array_float input must be finite: {case_id}")
            result, expected = median_of_running_array_float_oracle(
                values, capacity, output_is_null, input_is_null, input_length)
            raw_expected = case.get("expected_output")
            if (type(case.get("expected_result")) is not int or case["expected_result"] != result
                    or not isinstance(raw_expected, list)
                    or not _same_float64_sequence(raw_expected, expected)):
                raise ValueError(f"median_of_running_array_float fixture mismatch: {case_id}")
            if key == "cases" and (input_is_null or output_is_null
                                    or capacity != MEDIAN_RUNNING_FLOAT_MAX_OUTPUT_ELEMENTS
                                    or input_length != len(raw_values)):
                raise ValueError(f"median_of_running_array_float semantic framing changed: {case_id}")
            if case_id == "null_input_positive_length" and (
                    not input_is_null or raw_values or input_length <= 0):
                raise ValueError("median_of_running_array_float null-input ABI probe changed")


def validate_mean_shift_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "machine_learning/mean_shift.py",
        "symbol": "mean_shift",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/mean_shift.py",
        "role": "algorithm",
    }
    contract = {
        "operation": "Return one zero-based mean-shift cluster label per input point.",
        "input_layout": "[point_count, dimension, bandwidth, max_iterations, tolerance, point-major flattened coordinates...]",
        "point_order": "Preserve input order when scanning points, updating candidates, merging candidates, and emitting labels.",
        "distance": "sum((a-b)**2 for dimensions) ** 0.5 using binary64 operations and coordinate order.",
        "window_membership": "Include original data points whose distance to a candidate is <= bandwidth.",
        "mean": "For each dimension, sum neighboring coordinates in source point order and divide by the neighbor count.",
        "convergence": "A candidate is converged only when its movement distance is strictly less than tolerance.",
        "convergence_loop": "Check candidate movement in order and stop at the first non-converged candidate, matching all() short-circuiting. If all candidates converge, break before replacing candidates with the newly computed points; merge the previous candidates.",
        "merge": "Visit candidates in order and retain one only when its distance to every previously retained centroid is >= bandwidth.",
        "labels": "Assign each original point to the nearest retained centroid; equal distances select the first retained centroid.",
        "threshold_margin": "Every neighbor-membership, centroid-merge, and convergence distance comparison reached by source control flow must be at least 1e-6 away from its bandwidth or tolerance threshold. Each non-equal nearest-centroid distance compared with the current best must also differ by at least 1e-6; exact ties remain valid and retain the first centroid.",
        "errors": "Invalid input returns -1 before output checks. A null output or capacity below point_count returns -2 without writes.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[point_count, dimension, bandwidth, max_iterations, tolerance, coordinates...]",
        "point_count_range": [1, 16],
        "dimension_range": [1, 3],
        "coordinate_range": [-10.0, 10.0],
        "bandwidth_range": [0.5, 20.0],
        "max_iterations_range": [1, 64],
        "tolerance_range": [1e-5, 1e-2],
        "headers_must_be_exact_integers": ["point_count", "dimension", "max_iterations"],
        "exact_packed_shape": "Exactly 5 + point_count * dimension finite binary64 values.",
        "maximum_valid_input_length": MEAN_SHIFT_MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_input_length": MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH,
        "threshold_margin": 1e-6,
        "nearest_centroid_margin": "For each point, source-order min evaluation allows exact equal distances; any nonzero difference from the current best below 1e-6 is invalid.",
        "invalid_input_result": -1,
        "null_input_result": -1,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "One exact binary64 integer label per original point, in input order.",
        "maximum_elements": MEAN_SHIFT_WORKSPACE_ELEMENTS,
        "workspace_elements": MEAN_SHIFT_WORKSPACE_ELEMENTS,
        "success_result": "point_count",
        "invalid_input_result": -1,
        "invalid_output_buffer_result": -2,
        "null_output_result": -2,
        "no_write_on_error": True,
        "error_precedence": "Malformed, null, out-of-range, or threshold-margin-invalid input is rejected before output pointer or capacity checks.",
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    workspace = {
        "elements": MEAN_SHIFT_WORKSPACE_ELEMENTS,
        "meaning": "One label per input point.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1000,
        "absolute_tolerance": 0.0,
        "relative_tolerance": 0.0,
    }
    case_ids = {
        "single_point", "two_separated_clusters", "window_member_inside_threshold_margin",
        "window_member_outside_threshold_margin", "two_dimensional_euclidean_clusters",
        "greedy_first_retained_merge_and_nearest_tie", "iteration_limit_uses_last_updated_candidates",
        "convergence_all_short_circuits_after_first_movement", "maximum_points_dimensions_and_output",
        "zero_point_count_invalid", "nonintegral_point_count_invalid", "trailing_coordinate_invalid",
        "coordinate_out_of_range_invalid", "bandwidth_below_contract_range_invalid",
        "iteration_count_above_contract_range_invalid", "bandwidth_threshold_margin_violation_invalid",
        "convergence_threshold_margin_violation_invalid",
        "nearest_centroid_near_tie_margin_violation_invalid",
    }
    abi_ids = {
        "valid_input_null_output", "valid_input_short_output_capacity",
        "invalid_input_precedes_null_output", "null_input_positive_length",
    }
    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    case_keys = ([case.get("id") for case in cases if isinstance(case, dict)]
                 if isinstance(cases, list) else [])
    abi_keys = ([case.get("id") for case in abi_cases if isinstance(case, dict)]
                if isinstance(abi_cases, list) else [])
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-mean-shift-float64-slice-io-v1"
            or workload.get("algorithm") != "mean_shift"
            or workload.get("function_symbol") != "mean_shift"
            or workload.get("description") != "Shift points to neighborhood means, greedily merge centroids, and return stable zero-based cluster labels."
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or MEAN_SHIFT_MAX_VALID_INPUT_LENGTH != 53
            or MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH != 54
            or MEAN_SHIFT_WORKSPACE_ELEMENTS != 16
            or not isinstance(cases, list)
            or len(case_keys) != len(case_ids) or len(set(case_keys)) != len(case_keys)
            or set(case_keys) != case_ids
            or not isinstance(abi_cases, list)
            or len(abi_keys) != len(abi_ids) or len(set(abi_keys)) != len(abi_keys)
            or set(abi_keys) != abi_ids):
        raise ValueError("mean_shift metadata or case IDs differ from its reviewed contract")

    readme = (ROOT / "benchmarks" / "m" / "mean_shift" / "README.md").read_text(
        encoding="utf-8")
    if (source["url"] not in readme or source["commit"] not in readme
            or "all() short-circuiting" not in readme
            or "nearest-centroid assignment" not in readme
            or "exact ties remain valid" not in readme):
        raise ValueError("mean_shift README is missing its pinned source or reviewed semantics")

    absolute_tolerance, relative_tolerance = tolerances(workload)
    if absolute_tolerance != 0.0 or relative_tolerance != 0.0:
        raise ValueError("mean_shift labels require exact float64 comparison")
    for case in cases:
        values, _result, _output = encode_case(
            case, "mean_shift", absolute_tolerance, relative_tolerance)
        if len(values) > MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError(f"mean_shift input exceeds the parseable bound: {case.get('id')}")

    nonfinite_tokens = {"NaN": math.nan, "Infinity": math.inf, "-Infinity": -math.inf}
    for case in abi_cases:
        raw_values = case.get("input_values")
        if not isinstance(raw_values, list):
            raise ValueError(f"mean_shift ABI input must be an array: {case.get('id')}")
        values: list[float] = []
        for value in raw_values:
            if isinstance(value, str) and value in nonfinite_tokens:
                values.append(nonfinite_tokens[value])
            elif type(value) in (int, float):
                values.append(float(value))
            else:
                raise ValueError(f"mean_shift ABI input token is invalid: {case.get('id')}")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        input_length = case.get("input_length", len(values))
        if (len(values) > MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MEAN_SHIFT_WORKSPACE_ELEMENTS
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and output_is_null
                or type(input_length) is not int
                or not 0 <= input_length <= MEAN_SHIFT_MAX_PARSEABLE_INPUT_LENGTH
                or input_is_null and (values or input_length <= 0)
                or not input_is_null and input_length != len(values)):
            raise ValueError(f"mean_shift ABI framing is invalid: {case.get('id')}")
        result, output = mean_shift_oracle(
            values, capacity, output_is_null, input_is_null, input_length)
        expected_output = case.get("expected_output")
        if (case.get("expected_result") != result
                or not isinstance(expected_output, list)
                or not _same_float64_sequence(expected_output, output)):
            raise ValueError(f"mean_shift ABI workload mismatch: {case.get('id')}")


PI_MONTE_CARLO_ESTIMATION_CASE_IDS = frozenset({
    "one_trial_seed_zero", "eight_trials_seed_one", "source_example_one_hundred_seed_one",
    "source_example_one_thousand_seed_eleven", "maximum_trials_seed_zero",
    "maximum_trials_maximum_seed", "zero_trials_invalid", "fractional_trial_count_invalid",
    "trial_count_above_limit_invalid", "negative_seed_invalid", "seed_above_u32_invalid",
    "fractional_seed_invalid", "missing_seed_invalid", "trailing_input_value_invalid",
})


def validate_pi_monte_carlo_estimation_workload(workload: dict) -> None:
    source = {
        "repository": "TheAlgorithms/Python",
        "commit": "e1a2a8b016001309a73d5fec4818c35cca139795",
        "path": "maths/pi_monte_carlo_estimation.py",
        "symbol": "estimate_pi",
        "url": "https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pi_monte_carlo_estimation.py",
    }
    contract = {
        "operation": "estimate pi from seeded uniform points in the unit square",
        "input_encoding": "[number_of_simulations, seed]",
        "random_implementation_reference": "CPython 3.12.0 Modules/_randommodule.c",
        "random_generator": "Fresh CPython-compatible MT19937 per call; seed is one little-endian 32-bit word, including [0] for seed zero, passed to init_by_array.",
        "random_float": "For each draw, consume two tempered uint32 words a and b and return (a*2^26+b)/2^53, where a is the first word shifted right 5 and b is the second shifted right 6.",
        "draw_order": "Draw x then y for every trial.",
        "hit_predicate": "Use the benchmark's canonical binary64 multiplication projection x*x + y*y <= 1.0, evaluated left to right and including the circle boundary; it may differ from CPython pow at rare rounding-boundary inputs.",
        "result": "4 * hits / number_of_simulations as one binary64 value.",
        "state": "No generator state is shared between calls.",
    }
    input_spec = {
        "kind": "finite_float64_array",
        "encoding": "[number_of_simulations, seed]",
        "number_of_simulations_range": [PI_MONTE_CARLO_MIN_SIMULATIONS,
                                        PI_MONTE_CARLO_MAX_SIMULATIONS],
        "seed_range": [PI_MONTE_CARLO_MIN_SEED, PI_MONTE_CARLO_MAX_SEED],
        "maximum_valid_input_length": PI_MONTE_CARLO_MAX_INPUT_LENGTH,
        "maximum_parseable_input_length": PI_MONTE_CARLO_MAX_PARSEABLE_INPUT_LENGTH,
        "exact_packed_shape": "Exactly two finite binary64 values, each an exact integer in its declared range.",
        "invalid_input_result": PI_MONTE_CARLO_INVALID_RESULT,
        "null_input_result": PI_MONTE_CARLO_INVALID_RESULT,
    }
    output_spec = {
        "kind": "float64_array",
        "encoding": "[4 * hits / number_of_simulations]",
        "maximum_elements": PI_MONTE_CARLO_MAX_OUTPUT_ELEMENTS,
        "success_result": "number of output float64 elements (1)",
        "invalid_input_result": PI_MONTE_CARLO_INVALID_RESULT,
        "invalid_output_buffer_result": PI_MONTE_CARLO_OUTPUT_ERROR,
        "null_output_result": PI_MONTE_CARLO_OUTPUT_ERROR,
        "no_write_on_error": True,
        "error_precedence": "Malformed or null input is rejected before output pointer or capacity checks.",
        "absolute_tolerance": PI_MONTE_CARLO_ABSOLUTE_TOLERANCE,
        "relative_tolerance": PI_MONTE_CARLO_RELATIVE_TOLERANCE,
    }
    workspace = {
        "elements": PI_MONTE_CARLO_MAX_OUTPUT_ELEMENTS,
        "meaning": "The single binary64 estimate.",
    }
    measurement = {
        "comparison_model": "float64_slice_io_call",
        "sample_count": 5,
        "warmup_rounds": 1,
        "repetitions_per_sample": 1,
        "absolute_tolerance": PI_MONTE_CARLO_ABSOLUTE_TOLERANCE,
        "relative_tolerance": PI_MONTE_CARLO_RELATIVE_TOLERANCE,
    }
    cases = workload.get("cases")
    case_ids = ([case.get("id") for case in cases if isinstance(case, dict)]
                if isinstance(cases, list) else [])
    if (workload.get("schema_version") != 1
            or workload.get("id") != "thealgorithms-python-pi-monte-carlo-estimation-f64-slice-io-v1"
            or workload.get("algorithm") != "pi_monte_carlo_estimation"
            or workload.get("function_symbol") != "pi_monte_carlo_estimation"
            or workload.get("pinned_source") != source
            or workload.get("contract") != contract
            or workload.get("input") != input_spec
            or workload.get("output") != output_spec
            or workload.get("workspace") != workspace
            or workload.get("measurement") != measurement
            or PI_MONTE_CARLO_MIN_SIMULATIONS != 1
            or PI_MONTE_CARLO_MAX_SIMULATIONS != 100_000
            or PI_MONTE_CARLO_MIN_SEED != 0
            or PI_MONTE_CARLO_MAX_SEED != (1 << 32) - 1
            or PI_MONTE_CARLO_MAX_INPUT_LENGTH != 2
            or PI_MONTE_CARLO_MAX_PARSEABLE_INPUT_LENGTH != 3
            or PI_MONTE_CARLO_MAX_OUTPUT_ELEMENTS != 1
            or PI_MONTE_CARLO_INVALID_RESULT != -1
            or PI_MONTE_CARLO_OUTPUT_ERROR != -2
            or PI_MONTE_CARLO_ABSOLUTE_TOLERANCE != 0.0
            or PI_MONTE_CARLO_RELATIVE_TOLERANCE != 0.0
            or not isinstance(cases, list)
            or len(case_ids) != len(PI_MONTE_CARLO_ESTIMATION_CASE_IDS)
            or len(case_ids) != len(set(case_ids))
            or set(case_ids) != PI_MONTE_CARLO_ESTIMATION_CASE_IDS):
        raise ValueError("pi_monte_carlo_estimation metadata or case IDs differ from its reviewed contract")

    readme = (ROOT / "benchmarks" / "p" / "pi_monte_carlo_estimation" / "README.md").read_text(
        encoding="utf-8")
    normalized_readme = " ".join(readme.split())
    cpython_url = "https://github.com/python/cpython/blob/v3.12.0/Modules/_randommodule.c"
    if (source["url"] not in readme or cpython_url not in readme
            or "canonical binary64 multiplication projection" not in normalized_readme
            or "may differ from CPython's platform `pow` result" not in normalized_readme
            or "upper 27 bits" not in normalized_readme
            or "upper 26 bits" not in normalized_readme
            or "Each trial draws x first and y second" not in normalized_readme):
        raise ValueError("pi_monte_carlo_estimation README is missing its pinned source or RNG semantics")

    absolute_tolerance, relative_tolerance = tolerances(workload)
    if (absolute_tolerance != PI_MONTE_CARLO_ABSOLUTE_TOLERANCE
            or relative_tolerance != PI_MONTE_CARLO_RELATIVE_TOLERANCE):
        raise ValueError("pi_monte_carlo_estimation requires exact binary64 output comparison")
    indexed_cases = {case.get("id"): case for case in cases}
    for case in cases:
        values, result, output = encode_case(
            case, "pi_monte_carlo_estimation", absolute_tolerance, relative_tolerance)
        if (len(values) > PI_MONTE_CARLO_MAX_PARSEABLE_INPUT_LENGTH
                or result != case.get("expected_result")
                or not _same_float64_sequence(output, case.get("expected_output"))):
            raise ValueError(f"pi_monte_carlo_estimation fixture mismatch: {case.get('id')}")

    maximum_zero_seed = indexed_cases["maximum_trials_seed_zero"]
    maximum_seed = indexed_cases["maximum_trials_maximum_seed"]
    trailing_case = indexed_cases["trailing_input_value_invalid"]
    if (maximum_zero_seed.get("input_values") != [PI_MONTE_CARLO_MAX_SIMULATIONS, 0]
            or maximum_seed.get("input_values")
            != [PI_MONTE_CARLO_MAX_SIMULATIONS, PI_MONTE_CARLO_MAX_SEED]
            or len(trailing_case.get("input_values", [])) != PI_MONTE_CARLO_MAX_PARSEABLE_INPUT_LENGTH
            or trailing_case.get("expected_result") != PI_MONTE_CARLO_INVALID_RESULT):
        raise ValueError("pi_monte_carlo_estimation workload is missing its endpoint cases")


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
    if manifest.get("family") != "float64_slice_io" or algorithm not in ORACLES:
        parser.error("build manifest must declare a registered float64_slice_io algorithm")
    language = manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    runner_binary = manifest["binaries"]["float64_slice_io_runner"]
    executable = Path(runner_binary["path"])
    runner_source = ROOT / "benchmarks/harness/float64_slice_io_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != runner_binary["sha256"]
            or sha256_file(runner_source) != runner_binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = algorithm[0]
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "float64_slice_io_call"):
        parser.error("workload does not match the float64_slice_io algorithm")
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
    elif algorithm == "piecewise_without_inbuilt":
        validate_piecewise_without_inbuilt_workload(workload)
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
    elif algorithm == "rhumb_distance":
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
    absolute_tolerance, relative_tolerance = tolerances(workload)
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed runner limits")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases or len({case.get("id") for case in cases}) != len(cases):
        parser.error("workload requires unique case IDs")
    workspace = workload.get("workspace", {}).get("elements")
    if type(workspace) is not int or not 1 <= workspace <= 64:
        parser.error("workload workspace.elements must be an integer from 1 through 64")
    encoded_cases = [
        (case, *encode_case(case, algorithm, absolute_tolerance, relative_tolerance))
        for case in cases
    ]
    for case, _values, expected_result, expected_output in encoded_cases:
        if expected_result >= 0 and (expected_result > workspace or expected_result != len(expected_output)):
            parser.error(f"workspace is too small for {case['id']}")

    checker = manifest["binaries"].get("float64_slice_io_check")
    if checker is not None:
        checker_binary = Path(checker["path"])
        checker_source = ROOT / "benchmarks/harness/float64_slice_io_check.c"
        if (sha256_file(checker_binary) != checker["sha256"]
                or sha256_file(checker_source) != checker["harness_sha256"]):
            parser.error("checker or checker binary changed since the recorded build; rebuild first")

    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": runner_binary["harness_sha256"],
                           "binary_sha256": runner_binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case, values, expected_result, expected_output in encoded_cases:
        header = (f"{len(values)} {expected_result} {len(expected_output)} {workspace} "
                  f"{absolute_tolerance:.17g} {relative_tolerance:.17g}\n")
        payload = (" ".join(format(value, ".17g") for value in values) + " " +
                   " ".join(_format_output(value) for value in expected_output) + "\n")
        completed = subprocess.run(
            [str(executable), "--stdin", str(samples), str(warmups), str(repetitions)],
            input=header + payload, capture_output=True, text=True, check=False,
        )
        if completed.returncode:
            raise SystemExit(f"float64-slice runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed_result = raw.get("observed_result")
        observed_output = raw.get("observed_output")
        output_matches = (
            isinstance(observed_output, list) and len(observed_output) == len(expected_output)
            and all((expected == "NaN" and value == "NaN") or
                    (expected != "NaN" and type(value) in (int, float)
                     and math.isfinite(_output_value(value))
                     and abs(_output_value(value) - float(expected))
                     <= absolute_tolerance + relative_tolerance * abs(float(expected)))
                    for value, expected in zip(observed_output, expected_output))
        )
        if algorithm in {"median_of_running_array_double", "median_of_running_array_float",
                         "mean_shift"}:
            output_matches = _same_float64_sequence(observed_output, expected_output)
        if (observed_result != expected_result or not isinstance(observed_output, list)
                or not output_matches
                or len(raw.get("samples_ns", [])) != samples):
            raise ValueError(f"float64-slice runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id,
                        "algorithm": algorithm, "implementation": implementation,
                        "environment": environment,
                        "workload": {"id": workload["id"], "case_id": case["id"],
                                     "input_length": len(values), "input_values": values,
                                     "expected_result": expected_result,
                                     "expected_output": expected_output},
                        "measurement": {"comparison_model": "float64_slice_io_call",
                                        "observed_result": observed_result,
                                        "observed_output": observed_output,
                                        "samples_ns": raw["samples_ns"],
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "sample_count": samples, "warmup_rounds": warmups,
                                        "repetitions_per_sample": repetitions,
                                        "absolute_tolerance": absolute_tolerance,
                                        "relative_tolerance": relative_tolerance}})
    destination = args.output or ROOT / "benchmarks" / "results" / f"{algorithm}-{language}.jsonl"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("".join(json.dumps(record, sort_keys=True) + "\n" for record in records),
                           encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
