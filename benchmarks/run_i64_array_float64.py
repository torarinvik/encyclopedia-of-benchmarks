#!/usr/bin/env python3
"""Record a built binary64-result benchmark over a signed 64-bit input array."""

from __future__ import annotations

import argparse
import datetime as dt
from fractions import Fraction
import json
import math
import os
from pathlib import Path
import platform
import shlex
import subprocess
import struct
import sys

from build_abi import ROOT, sha256_file
from gradient_descent_oracle import expected_result as gradient_descent_expected
from complementary_filter_oracle import INVALID_RESULT as COMPLEMENTARY_FILTER_INVALID_RESULT
from complementary_filter_oracle import expected_result as complementary_filter_expected
from comp_filt_oracle import INVALID_RESULT as COMP_FILT_INVALID_RESULT
from comp_filt_oracle import expected_result as comp_filt_expected
from apparent_power_oracle import INVALID_RESULT as APPARENT_POWER_INVALID_RESULT
from apparent_power_oracle import expected_result as apparent_power_expected
from capacitor_equivalence_oracle import INVALID_RESULT as CAPACITOR_EQUIVALENCE_INVALID_RESULT
from capacitor_equivalence_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_CAPACITOR_EQUIVALENCE_INPUT_LENGTH
from capacitor_equivalence_oracle import expected_result as capacitor_equivalence_expected
from archimedes_principle_of_buoyant_force_oracle import (
    INVALID_RESULT as ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT,
    expected_result as archimedes_principle_of_buoyant_force_expected,
)
from centripetal_force_oracle import INVALID_RESULT as CENTRIPETAL_FORCE_INVALID_RESULT
from centripetal_force_oracle import expected_result as centripetal_force_expected
from cone_oracle import INVALID_RESULT as CONE_INVALID_RESULT
from cone_oracle import expected_result as cone_expected
from cohen_sutherland_oracle import INVALID_RESULT as COHEN_SUTHERLAND_INVALID_RESULT
from cohen_sutherland_oracle import expected_result as cohen_sutherland_expected
from lamberts_ellipsoidal_distance_oracle import INVALID_RESULT as LAMBERTS_ELLIPSOIDAL_DISTANCE_INVALID_RESULT
from lamberts_ellipsoidal_distance_oracle import MAX_INPUT_LENGTH as MAX_LAMBERTS_ELLIPSOIDAL_DISTANCE_INPUT_LENGTH
from lamberts_ellipsoidal_distance_oracle import expected_result as lamberts_ellipsoidal_distance_expected
from reverse_polish_notation_oracle import INVALID_RESULT as REVERSE_POLISH_NOTATION_INVALID_RESULT
from reverse_polish_notation_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_REVERSE_POLISH_NOTATION_PARSEABLE_INPUT_LENGTH
from reverse_polish_notation_oracle import expected_result as reverse_polish_notation_expected
from prefix_evaluation_oracle import INVALID_RESULT as PREFIX_EVALUATION_INVALID_RESULT
from prefix_evaluation_oracle import MAX_INPUT_LENGTH as MAX_PREFIX_EVALUATION_INPUT_LENGTH
from prefix_evaluation_oracle import expected_result as prefix_evaluation_expected
from units_converter_oracle import INVALID_RESULT as UNITS_CONVERTER_INVALID_RESULT
from units_converter_oracle import MAX_INPUT_LENGTH as MAX_UNITS_CONVERTER_INPUT_LENGTH
from units_converter_oracle import expected_result as units_converter_expected
from peak_signal_to_noise_ratio_oracle import INVALID_RESULT as PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT
from peak_signal_to_noise_ratio_oracle import MAX_INPUT_LENGTH as MAX_PEAK_SIGNAL_TO_NOISE_RATIO_INPUT_LENGTH
from peak_signal_to_noise_ratio_oracle import expected_result as peak_signal_to_noise_ratio_expected
from p2_quantile_estimator_oracle import INVALID_RESULT as P2_QUANTILE_INVALID_RESULT
from p2_quantile_estimator_oracle import MAX_INPUT_LENGTH as MAX_P2_QUANTILE_INPUT_LENGTH
from p2_quantile_estimator_oracle import expected_result as p2_quantile_expected
from kinetic_energy_oracle import INVALID_RESULT as KINETIC_ENERGY_INVALID_RESULT
from kinetic_energy_oracle import expected_result as kinetic_energy_expected
from potential_energy_oracle import INVALID_RESULT as POTENTIAL_ENERGY_INVALID_RESULT
from potential_energy_oracle import expected_result as potential_energy_expected
from sum_of_arithmetic_series_oracle import INVALID_RESULT as SUM_OF_ARITHMETIC_SERIES_INVALID_RESULT
from sum_of_arithmetic_series_oracle import expected_result as sum_of_arithmetic_series_expected
from euclidean_distance_oracle import INVALID_RESULT as EUCLIDEAN_DISTANCE_INVALID_RESULT
from euclidean_distance_oracle import expected_result as euclidean_distance_expected
from dynamic_time_warping_oracle import INVALID_RESULT as DYNAMIC_TIME_WARPING_INVALID_RESULT
from dynamic_time_warping_oracle import expected_result as dynamic_time_warping_expected
from yin_oracle import INVALID_RESULT as YIN_INVALID_RESULT
from yin_oracle import expected_result as yin_expected
from boyles_law_oracle import INVALID_RESULT as BOYLES_LAW_INVALID_RESULT
from boyles_law_oracle import expected_result as boyles_law_expected
from harmonic_mean_oracle import INVALID_RESULT as HARMONIC_MEAN_INVALID_RESULT
from harmonic_mean_oracle import expected_result as harmonic_mean_expected
from is_harmonic_series_oracle import INVALID_RESULT as IS_HARMONIC_SERIES_INVALID_RESULT
from is_harmonic_series_oracle import expected_result as is_harmonic_series_expected
from quadratic_mean_oracle import INVALID_RESULT as QUADRATIC_MEAN_INVALID_RESULT
from quadratic_mean_oracle import expected_result as quadratic_mean_expected
from distance_between_two_points_oracle import INVALID_RESULT as DISTANCE_BETWEEN_TWO_POINTS_INVALID_RESULT
from distance_between_two_points_oracle import expected_result as distance_between_two_points_expected
from arithmetic_mean_oracle import INVALID_RESULT as ARITHMETIC_MEAN_INVALID_RESULT
from arithmetic_mean_oracle import expected_result as arithmetic_mean_expected
from gaussian_oracle import INVALID_RESULT as GAUSSIAN_INVALID_RESULT
from gaussian_oracle import expected_result as gaussian_expected
from hubble_parameter_oracle import INVALID_RESULT as HUBBLE_PARAMETER_INVALID_RESULT
from hubble_parameter_oracle import expected_result as hubble_parameter_expected
from light_aberration_oracle import INVALID_RESULT as LIGHT_ABERRATION_INVALID_RESULT
from light_aberration_oracle import expected_result as light_aberration_expected
from variance_oracle import INVALID_RESULT as VARIANCE_INVALID_RESULT
from variance_oracle import MAX_INPUT_LENGTH as MAX_VARIANCE_INPUT_LENGTH
from median_two_array_oracle import MAX_INPUT_LENGTH as MAX_MEDIAN_TWO_ARRAY_INPUT_LENGTH
from median_two_array_oracle import expected_result as median_two_array_expected
from variance_oracle import expected_result as variance_expected
from dice_coefficient_oracle import INVALID_RESULT as DICE_COEFFICIENT_INVALID_RESULT
from dice_coefficient_oracle import MAX_INPUT_LENGTH as MAX_DICE_COEFFICIENT_INPUT_LENGTH
from dice_coefficient_oracle import expected_result as dice_coefficient_expected
from density_oracle import INVALID_RESULT as DENSITY_INVALID_RESULT
from density_oracle import MAX_INPUT_LENGTH as MAX_DENSITY_INPUT_LENGTH
from density_oracle import expected_result as density_expected
from hinge_loss_oracle import INVALID_RESULT as HINGE_LOSS_INVALID_RESULT
from hinge_loss_oracle import MAX_INPUT_LENGTH as MAX_HINGE_LOSS_INPUT_LENGTH
from hinge_loss_oracle import expected_result as hinge_loss_expected
from collaborative_filtering_oracle import MAX_PEARSON_INPUT_LENGTH
from collaborative_filtering_oracle import MAX_PREDICTION_INPUT_LENGTH
from collaborative_filtering_oracle import PEARSON_INVALID_RESULT
from collaborative_filtering_oracle import PREDICTION_INVALID_RESULT
from collaborative_filtering_oracle import expected_pearson_similarity
from collaborative_filtering_oracle import expected_prediction
from maclaurin_series_oracle import INVALID_RESULT as MACLAURIN_SERIES_INVALID_RESULT
from maclaurin_series_oracle import expected_result as maclaurin_series_expected
from automatic_differentiation_oracle import automatic_differentiation
from butterworth_filter_oracle import expected_result as butterworth_filter_expected
from charging_capacitor_oracle import expected_result as charging_capacitor_expected
from charging_inductor_oracle import expected_result as charging_inductor_expected
from center_of_mass_oracle import expected_result as center_of_mass_expected
from color_contrast_ratio_oracle import INVALID_RESULT as COLOR_CONTRAST_INVALID_RESULT
from color_contrast_ratio_oracle import expected_result as color_contrast_ratio_expected
from grahams_law_oracle import grahams_law as grahams_law_result
from rainfall_intensity_oracle import rainfall_intensity
from rotating_calipers_oracle import rotating_calipers
from standard_deviation_oracle import INVALID_RESULT as STANDARD_DEVIATION_INVALID_RESULT
from standard_deviation_oracle import expected_result as standard_deviation_expected
from speed_oracle import expected_result as speed_expected
from ground_to_ground_projectile_motion_oracle import INVALID_RESULT as GROUND_PROJECTILE_INVALID_RESULT
from ground_to_ground_projectile_motion_oracle import MAX_INPUT_LENGTH as MAX_GROUND_PROJECTILE_INPUT_LENGTH
from ground_to_ground_projectile_motion_oracle import expected_result as ground_projectile_expected
from huber_loss_oracle import INVALID_RESULT as HUBER_LOSS_INVALID_RESULT
from huber_loss_oracle import MAX_INPUT_LENGTH as MAX_HUBER_LOSS_INPUT_LENGTH
from huber_loss_oracle import expected_result as huber_loss_expected
from huber_loss_math_oracle import INVALID_RESULT as HUBER_LOSS_MATH_INVALID_RESULT
from huber_loss_math_oracle import MAX_INPUT_LENGTH as MAX_HUBER_LOSS_MATH_INPUT_LENGTH
from huber_loss_math_oracle import expected_result as huber_loss_math_expected
from exponential_dist_oracle import INVALID_RESULT as EXPONENTIAL_DIST_INVALID_RESULT
from exponential_dist_oracle import MAX_INPUT_LENGTH as MAX_EXPONENTIAL_DIST_INPUT_LENGTH
from exponential_dist_oracle import expected_result as exponential_dist_expected
from expected_shortfall_oracle import INVALID_RESULT as EXPECTED_SHORTFALL_INVALID_RESULT
from expected_shortfall_oracle import MAX_INPUT_LENGTH as MAX_EXPECTED_SHORTFALL_INPUT_LENGTH
from expected_shortfall_oracle import expected_result as expected_shortfall_expected
from time_converter_oracle import INVALID_RESULT as TIME_CONVERTER_INVALID_RESULT
from time_converter_oracle import MAX_INPUT_LENGTH as MAX_TIME_CONVERTER_INPUT_LENGTH
from time_converter_oracle import expected_result as time_converter_expected
from temperature_converter_oracle import INVALID_RESULT as TEMPERATURE_CONVERTER_INVALID_RESULT
from temperature_converter_oracle import MAX_INPUT_LENGTH as MAX_TEMPERATURE_CONVERTER_INPUT_LENGTH
from temperature_converter_oracle import expected_result as temperature_converter_expected
from value_at_risk_oracle import INVALID_RESULT as VALUE_AT_RISK_INVALID_RESULT
from value_at_risk_oracle import MAX_INPUT_LENGTH as MAX_VALUE_AT_RISK_INPUT_LENGTH
from value_at_risk_oracle import expected_result as value_at_risk_expected
from energy_oracle import INVALID_RESULT as ENERGY_INVALID_RESULT
from energy_oracle import MAX_INPUT_LENGTH as MAX_ENERGY_INPUT_LENGTH
from energy_oracle import expected_result as energy_expected
from trapezoidal_integration_oracle import INVALID_RESULT as TRAPEZOIDAL_INTEGRATION_INVALID_RESULT
from trapezoidal_integration_oracle import MAX_INPUT_LENGTH as MAX_TRAPEZOIDAL_INTEGRATION_INPUT_LENGTH
from trapezoidal_integration_oracle import expected_result as trapezoidal_integration_expected
from neville_oracle import INVALID_RESULT as NEVILLE_INVALID_RESULT
from neville_oracle import MAX_INPUT_LENGTH as MAX_NEVILLE_INPUT_LENGTH
from neville_oracle import expected_result as neville_expected
from midpoint_integral_method_oracle import INVALID_RESULT as MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT
from midpoint_integral_method_oracle import MAX_INPUT_LENGTH as MAX_MIDPOINT_INTEGRAL_METHOD_INPUT_LENGTH
from midpoint_integral_method_oracle import expected_result as midpoint_integral_method_expected
from weddles_rule_oracle import INVALID_RESULT as WEDDLES_RULE_INVALID_RESULT
from weddles_rule_oracle import MAX_INPUT_LENGTH as MAX_WEDDLES_RULE_INPUT_LENGTH
from weddles_rule_oracle import expected_result as weddles_rule_expected
from ternary_search_min_max_recursive_oracle import INVALID_RESULT as TERNARY_SEARCH_MIN_MAX_INVALID_RESULT
from ternary_search_min_max_recursive_oracle import MAX_INPUT_LENGTH as MAX_TERNARY_SEARCH_MIN_MAX_INPUT_LENGTH
from ternary_search_min_max_recursive_oracle import expected_result as ternary_search_min_max_expected
from cosine_similarity_oracle import INVALID_RESULT as COSINE_SIMILARITY_INVALID_RESULT
from cosine_similarity_oracle import MAX_INPUT_LENGTH as MAX_COSINE_SIMILARITY_INPUT_LENGTH
from cosine_similarity_oracle import expected_output as cosine_similarity_expected
from quadratic_equation_solver_oracle import INVALID_RESULT as QUADRATIC_EQUATION_SOLVER_INVALID_RESULT
from quadratic_equation_solver_oracle import MAX_INPUT_LENGTH as MAX_QUADRATIC_EQUATION_SOLVER_INPUT_LENGTH
from quadratic_equation_solver_oracle import expected_result as quadratic_equation_solver_expected
from durand_kerner_roots_oracle import expected_result as durand_kerner_expected
from linear_regression_cost_oracle import INVALID_RESULT as LINEAR_REGRESSION_COST_INVALID_RESULT
from linear_regression_cost_oracle import MAX_INPUT_LENGTH as MAX_LINEAR_REGRESSION_COST_INPUT_LENGTH
from linear_regression_cost_oracle import expected_result as linear_regression_cost_expected
from price_plus_tax_oracle import INVALID_RESULT as PRICE_PLUS_TAX_INVALID_RESULT
from price_plus_tax_oracle import MAX_INPUT_LENGTH as MAX_PRICE_PLUS_TAX_INPUT_LENGTH
from price_plus_tax_oracle import expected_result as price_plus_tax_expected
from macaulay_duration_oracle import INVALID_RESULT as MACAULAY_DURATION_INVALID_RESULT
from macaulay_duration_oracle import MAX_INPUT_LENGTH as MAX_MACAULAY_DURATION_INPUT_LENGTH
from macaulay_duration_oracle import expected_result as macaulay_duration_expected
from kelly_criterion_oracle import INVALID_RESULT as KELLY_CRITERION_INVALID_RESULT
from kelly_criterion_oracle import MAX_INPUT_LENGTH as MAX_KELLY_CRITERION_INPUT_LENGTH
from kelly_criterion_oracle import expected_result as kelly_criterion_expected
from present_value_oracle import INVALID_RESULT as PRESENT_VALUE_INVALID_RESULT
from present_value_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_PRESENT_VALUE_PARSEABLE_INPUT_LENGTH
from present_value_oracle import expected_result as present_value_expected
from present_value_rust_oracle import INVALID_RESULT as PRESENT_VALUE_RUST_INVALID_RESULT
from present_value_rust_oracle import MAX_INPUT_LENGTH as MAX_PRESENT_VALUE_RUST_PARSEABLE_INPUT_LENGTH
from present_value_rust_oracle import expected_result as present_value_rust_expected
from resonant_frequency_oracle import INVALID_RESULT as RESONANT_FREQUENCY_INVALID_RESULT
from resonant_frequency_oracle import MAX_INPUT_LENGTH as MAX_RESONANT_FREQUENCY_INPUT_LENGTH
from resonant_frequency_oracle import expected_result as resonant_frequency_expected
from rms_speed_of_molecule_oracle import INVALID_RESULT as RMS_SPEED_OF_MOLECULE_INVALID_RESULT
from rms_speed_of_molecule_oracle import MAX_INPUT_LENGTH as MAX_RMS_SPEED_OF_MOLECULE_INPUT_LENGTH
from rms_speed_of_molecule_oracle import expected_result as rms_speed_of_molecule_expected
from newtons_second_law_of_motion_oracle import INVALID_RESULT as NEWTONS_SECOND_LAW_INVALID_RESULT
from newtons_second_law_of_motion_oracle import MAX_INPUT_LENGTH as MAX_NEWTONS_SECOND_LAW_INPUT_LENGTH
from newtons_second_law_of_motion_oracle import expected_result as newtons_second_law_expected
from speed_of_sound_oracle import INVALID_RESULT as SPEED_OF_SOUND_INVALID_RESULT
from speed_of_sound_oracle import MAX_INPUT_LENGTH as MAX_SPEED_OF_SOUND_INPUT_LENGTH
from speed_of_sound_oracle import expected_result as speed_of_sound_expected
from terminal_velocity_oracle import INVALID_RESULT as TERMINAL_VELOCITY_INVALID_RESULT
from terminal_velocity_oracle import MAX_INPUT_LENGTH as MAX_TERMINAL_VELOCITY_INPUT_LENGTH
from terminal_velocity_oracle import expected_result as terminal_velocity_expected
from newtons_law_of_gravitation_oracle import INVALID_RESULT as NEWTONS_GRAVITATION_INVALID_RESULT
from newtons_law_of_gravitation_oracle import MAX_INPUT_LENGTH as MAX_NEWTONS_GRAVITATION_INPUT_LENGTH
from newtons_law_of_gravitation_oracle import expected_result as newtons_gravitation_expected
from ideal_gas_law_oracle import INVALID_RESULT as IDEAL_GAS_LAW_INVALID_RESULT
from ideal_gas_law_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_IDEAL_GAS_LAW_INPUT_LENGTH
from ideal_gas_law_oracle import expected_result as ideal_gas_law_expected
from poisson_dist_oracle import INVALID_RESULT as POISSON_DIST_INVALID_RESULT
from poisson_dist_oracle import MAX_INPUT_LENGTH as MAX_POISSON_DIST_INPUT_LENGTH
from poisson_dist_oracle import expected_result as poisson_dist_expected
from doppler_frequency_oracle import INVALID_RESULT as DOPPLER_FREQUENCY_INVALID_RESULT
from doppler_frequency_oracle import MAX_INPUT_LENGTH as MAX_DOPPLER_FREQUENCY_INPUT_LENGTH
from doppler_frequency_oracle import expected_result as doppler_frequency_expected
from pearson_correlation_oracle import INVALID_RESULT as PEARSON_CORRELATION_INVALID_RESULT
from pearson_correlation_oracle import MAX_INPUT_LENGTH as MAX_PEARSON_CORRELATION_INPUT_LENGTH
from pearson_correlation_oracle import expected_result as pearson_correlation_expected
from kendall_rank_correlation_coefficient_oracle import INVALID_RESULT as KENDALL_RANK_CORRELATION_INVALID_RESULT
from kendall_rank_correlation_coefficient_oracle import MAX_INPUT_LENGTH as MAX_KENDALL_RANK_CORRELATION_INPUT_LENGTH
from kendall_rank_correlation_coefficient_oracle import expected_result as kendall_rank_correlation_expected
from spearman_average_rank_correlation_oracle import INVALID_RESULT as SPEARMAN_AVERAGE_RANK_INVALID_RESULT
from spearman_average_rank_correlation_oracle import MAX_INPUT_LENGTH as MAX_SPEARMAN_AVERAGE_RANK_INPUT_LENGTH
from spearman_average_rank_correlation_oracle import expected_result as spearman_average_rank_expected
from secant_method_oracle import INVALID_RESULT as SECANT_METHOD_INVALID_RESULT
from secant_method_oracle import MAX_INPUT_LENGTH as MAX_SECANT_METHOD_INPUT_LENGTH
from secant_method_oracle import expected_result as secant_method_expected
from newton_raphson_method_oracle import INVALID_RESULT as NEWTON_RAPHSON_METHOD_INVALID_RESULT
from newton_raphson_method_oracle import MAX_INPUT_LENGTH as MAX_NEWTON_RAPHSON_METHOD_INPUT_LENGTH
from newton_raphson_method_oracle import expected_result as newton_raphson_method_expected
from newton_raphson_oracle import INVALID_RESULT as NEWTON_RAPHSON_INVALID_RESULT
from newton_raphson_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_NEWTON_RAPHSON_PARSEABLE_INPUT_LENGTH
from newton_raphson_oracle import expected_result as newton_raphson_expected
from reynolds_number_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_REYNOLDS_NUMBER_PARSEABLE_INPUT_LENGTH
from integral_approximation_oracle import INVALID_RESULT as INTEGRAL_APPROXIMATION_INVALID_RESULT
from integral_approximation_oracle import MAX_INPUT_LENGTH as MAX_INTEGRAL_APPROXIMATION_INPUT_LENGTH
from integral_approximation_oracle import expected_result as integral_approximation_expected
from integration_by_simpson_approx_oracle import INVALID_RESULT as SIMPSON_APPROX_INVALID_RESULT
from integration_by_simpson_approx_oracle import MAX_INPUT_LENGTH as SIMPSON_APPROX_MAX_INPUT_LENGTH
from integration_by_simpson_approx_oracle import expected_result as simpson_approx_expected
from jaro_similarity_oracle import INVALID_RESULT as JARO_SIMILARITY_INVALID_RESULT
from jaro_similarity_oracle import MAX_INPUT_LENGTH as JARO_SIMILARITY_MAX_INPUT_LENGTH
from jaro_similarity_oracle import expected_result as jaro_similarity_expected
from jaro_winkler_oracle import INVALID_RESULT as JARO_WINKLER_INVALID_RESULT
from jaro_winkler_oracle import MAX_INPUT_LENGTH as JARO_WINKLER_MAX_INPUT_LENGTH
from jaro_winkler_oracle import expected_result as jaro_winkler_expected
from ic_555_timer_oracle import INVALID_RESULT as IC_555_TIMER_INVALID_RESULT
from ic_555_timer_oracle import MAX_INPUT_LENGTH as IC_555_TIMER_MAX_INPUT_LENGTH
from ic_555_timer_oracle import expected_result as ic_555_timer_expected
from pythagoras_oracle import INVALID_RESULT as PYTHAGORAS_INVALID_RESULT
from pythagoras_oracle import MAX_INPUT_LENGTH as PYTHAGORAS_MAX_INPUT_LENGTH
from pythagoras_oracle import expected_result as pythagoras_expected
from pow_oracle import INVALID_RESULT as POW_INVALID_RESULT
from pow_oracle import MAX_INPUT_LENGTH as POW_MAX_INPUT_LENGTH
from pow_oracle import expected_result as pow_expected

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_INPUT_LENGTH = 4096


def encode_case(case: dict, algorithm: str) -> tuple[list[int], float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    max_input_length = (MAX_LINEAR_REGRESSION_COST_INPUT_LENGTH if algorithm == "linear_regression_cost" else
                        MAX_MEDIAN_TWO_ARRAY_INPUT_LENGTH if algorithm == "median_two_array" else
                        MAX_KELLY_CRITERION_INPUT_LENGTH if algorithm == "kelly_criterion" else
                        MAX_PRESENT_VALUE_PARSEABLE_INPUT_LENGTH if algorithm == "present_value" else
                        MAX_PRESENT_VALUE_RUST_PARSEABLE_INPUT_LENGTH if algorithm == "present_value_rust" else
                        MAX_RESONANT_FREQUENCY_INPUT_LENGTH if algorithm == "resonant_frequency" else
                        MAX_RMS_SPEED_OF_MOLECULE_INPUT_LENGTH if algorithm == "rms_speed_of_molecule" else
                        MAX_NEWTONS_SECOND_LAW_INPUT_LENGTH if algorithm == "newtons_second_law_of_motion" else
                        MAX_SPEED_OF_SOUND_INPUT_LENGTH if algorithm == "speed_of_sound" else
                        MAX_TERMINAL_VELOCITY_INPUT_LENGTH if algorithm == "terminal_velocity" else
                        MAX_NEWTONS_GRAVITATION_INPUT_LENGTH if algorithm == "newtons_law_of_gravitation" else
                        MAX_IDEAL_GAS_LAW_INPUT_LENGTH if algorithm == "ideal_gas_law" else
                        MAX_POISSON_DIST_INPUT_LENGTH if algorithm == "poisson_dist" else
                        MAX_DOPPLER_FREQUENCY_INPUT_LENGTH if algorithm == "doppler_frequency" else
                        MAX_CAPACITOR_EQUIVALENCE_INPUT_LENGTH if algorithm == "capacitor_equivalence" else
                        MAX_MACAULAY_DURATION_INPUT_LENGTH if algorithm == "macaulay_duration" else
                        MAX_PRICE_PLUS_TAX_INPUT_LENGTH if algorithm == "price_plus_tax" else
                        MAX_PEARSON_CORRELATION_INPUT_LENGTH if algorithm == "pearson_correlation" else
                        MAX_KENDALL_RANK_CORRELATION_INPUT_LENGTH if algorithm == "kendall_rank_correlation_coefficient" else
                        MAX_SPEARMAN_AVERAGE_RANK_INPUT_LENGTH if algorithm == "spearman_average_rank_correlation" else
                        MAX_VARIANCE_INPUT_LENGTH if algorithm in {"variance", "welfords_variance"} else
                        MAX_DICE_COEFFICIENT_INPUT_LENGTH if algorithm == "dice_coefficient" else
                        MAX_DENSITY_INPUT_LENGTH if algorithm == "density" else
                        MAX_HINGE_LOSS_INPUT_LENGTH if algorithm == "hinge_loss" else
                        MAX_PREDICTION_INPUT_LENGTH + 1 if algorithm == "collaborative_filtering" else
                        MAX_PEARSON_INPUT_LENGTH + 1 if algorithm == "collaborative_filtering_pearson_similarity" else
                        MAX_QUADRATIC_EQUATION_SOLVER_INPUT_LENGTH
                        if algorithm == "quadratic_equation_solver_complex_roots" else
                        4 if algorithm == "durand_kerner_roots" else
                        MAX_GROUND_PROJECTILE_INPUT_LENGTH
                        if algorithm == "ground_to_ground_projectile_motion" else
                        MAX_HUBER_LOSS_INPUT_LENGTH
                        if algorithm == "huber_loss" else
                        MAX_HUBER_LOSS_MATH_INPUT_LENGTH
                        if algorithm == "huber_loss_math" else
                        MAX_EXPONENTIAL_DIST_INPUT_LENGTH
                        if algorithm == "exponential_dist" else
                        MAX_EXPECTED_SHORTFALL_INPUT_LENGTH
                        if algorithm == "expected_shortfall" else
                        MAX_TIME_CONVERTER_INPUT_LENGTH
                        if algorithm == "time_converter" else
                        MAX_TEMPERATURE_CONVERTER_INPUT_LENGTH
                        if algorithm == "temperature_converter" else
                        MAX_VALUE_AT_RISK_INPUT_LENGTH
                        if algorithm == "value_at_risk" else
                        MAX_ENERGY_INPUT_LENGTH
                        if algorithm == "energy" else
                        MAX_TRAPEZOIDAL_INTEGRATION_INPUT_LENGTH
                        if algorithm == "trapezoidal_integration" else
                        MAX_NEVILLE_INPUT_LENGTH
                        if algorithm == "neville" else
                        MAX_MIDPOINT_INTEGRAL_METHOD_INPUT_LENGTH
                        if algorithm == "midpoint_integral_method" else
                        MAX_WEDDLES_RULE_INPUT_LENGTH
                        if algorithm == "weddles_rule" else
                        MAX_UNITS_CONVERTER_INPUT_LENGTH if algorithm == "units_converter" else
                        MAX_TERNARY_SEARCH_MIN_MAX_INPUT_LENGTH
                        if algorithm == "ternary_search_min_max_recursive" else
                        MAX_COSINE_SIMILARITY_INPUT_LENGTH
                        if algorithm == "cosine_similarity" else
                        MAX_SECANT_METHOD_INPUT_LENGTH if algorithm == "secant_method" else
                        MAX_NEWTON_RAPHSON_PARSEABLE_INPUT_LENGTH if algorithm == "newton_raphson" else
                        MAX_REVERSE_POLISH_NOTATION_PARSEABLE_INPUT_LENGTH
                        if algorithm == "reverse_polish_notation" else
                        MAX_P2_QUANTILE_INPUT_LENGTH if algorithm == "p2_quantile_estimator" else
                        MAX_PEAK_SIGNAL_TO_NOISE_RATIO_INPUT_LENGTH if algorithm == "peak_signal_to_noise_ratio" else
                        MAX_LAMBERTS_ELLIPSOIDAL_DISTANCE_INPUT_LENGTH
                        if algorithm == "lamberts_ellipsoidal_distance" else
                        MAX_PREFIX_EVALUATION_INPUT_LENGTH if algorithm == "prefix_evaluation" else
                        MAX_NEWTON_RAPHSON_METHOD_INPUT_LENGTH if algorithm == "newton_raphson_method" else
                        MAX_REYNOLDS_NUMBER_PARSEABLE_INPUT_LENGTH if algorithm == "reynolds_number" else
                        MAX_INTEGRAL_APPROXIMATION_INPUT_LENGTH if algorithm == "integral_approximation" else
                        SIMPSON_APPROX_MAX_INPUT_LENGTH if algorithm == "integration_by_simpson_approx" else
                        JARO_SIMILARITY_MAX_INPUT_LENGTH if algorithm == "jaro_similarity" else
                        JARO_WINKLER_MAX_INPUT_LENGTH if algorithm == "jaro_winkler" else
                        IC_555_TIMER_MAX_INPUT_LENGTH if algorithm == "ic_555_timer" else
                        PYTHAGORAS_MAX_INPUT_LENGTH if algorithm == "pythagoras" else
                        POW_MAX_INPUT_LENGTH if algorithm == "pow" else
                        MAX_INPUT_LENGTH)
    if (not isinstance(values, list) or len(values) > max_input_length
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(expected) not in (int, float) or not math.isfinite(expected)):
        raise ValueError("array-float64 cases require up to 4096 signed 64-bit values and a finite result")
    if algorithm == "charging_capacitor":
        source_result = charging_capacitor_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid charging_capacitor inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-15, abs_tol=1e-12):
            raise ValueError("charging_capacitor expected_result must match the rounded RC voltage formula")
    elif algorithm == "integral_approximation":
        source_result = integral_approximation_expected(values)
        if source_result == INTEGRAL_APPROXIMATION_INVALID_RESULT:
            if expected != INTEGRAL_APPROXIMATION_INVALID_RESULT:
                raise ValueError("invalid integral_approximation inputs must use the -1e300 result sentinel")
        elif expected == INTEGRAL_APPROXIMATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("integral_approximation expected_result must match the source-ordered Riemann sum")
    elif algorithm == "integration_by_simpson_approx":
        source_result = simpson_approx_expected(values)
        if source_result == SIMPSON_APPROX_INVALID_RESULT:
            if expected != SIMPSON_APPROX_INVALID_RESULT:
                raise ValueError("invalid integration_by_simpson_approx inputs must use the -1e300 result sentinel")
        elif expected == SIMPSON_APPROX_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("integration_by_simpson_approx expected_result must match the rounded Simpson sum")
    elif algorithm == "ic_555_timer":
        source_result = ic_555_timer_expected(values)
        if source_result == IC_555_TIMER_INVALID_RESULT:
            if expected != IC_555_TIMER_INVALID_RESULT:
                raise ValueError("invalid ic_555_timer inputs must use the -1e300 result sentinel")
        elif expected == IC_555_TIMER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("ic_555_timer expected_result must match the pinned frequency or duty-cycle formula")
    elif algorithm == "jaro_similarity":
        source_result = jaro_similarity_expected(values)
        if source_result == JARO_SIMILARITY_INVALID_RESULT:
            if expected != JARO_SIMILARITY_INVALID_RESULT:
                raise ValueError("invalid jaro_similarity inputs must use the -1e300 result sentinel")
        elif expected == JARO_SIMILARITY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("jaro_similarity expected_result must match the pinned matching-window algorithm")
    elif algorithm == "jaro_winkler":
        source_result = jaro_winkler_expected(values)
        if source_result == JARO_WINKLER_INVALID_RESULT:
            if expected != JARO_WINKLER_INVALID_RESULT:
                raise ValueError("invalid jaro_winkler inputs must use the -1e300 result sentinel")
        elif expected == JARO_WINKLER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("jaro_winkler expected_result must match the pinned Python matching-window algorithm")
    elif algorithm == "arithmetic_mean":
        source_result = arithmetic_mean_expected(values)
        if source_result == ARITHMETIC_MEAN_INVALID_RESULT:
            if expected != ARITHMETIC_MEAN_INVALID_RESULT:
                raise ValueError("invalid arithmetic_mean inputs must use the -1e300 result sentinel")
        elif expected == ARITHMETIC_MEAN_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("arithmetic_mean expected_result must equal sum(values) / length")
    elif algorithm == "gaussian":
        source_result = gaussian_expected(values)
        if source_result == GAUSSIAN_INVALID_RESULT:
            if expected != GAUSSIAN_INVALID_RESULT:
                raise ValueError("invalid gaussian inputs must use the -1e300 result sentinel")
        elif expected == GAUSSIAN_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("gaussian expected_result must match the source-ordered density formula")
    elif algorithm == "maclaurin_series":
        source_result = maclaurin_series_expected(values)
        if source_result == MACLAURIN_SERIES_INVALID_RESULT:
            if expected != MACLAURIN_SERIES_INVALID_RESULT:
                raise ValueError("invalid maclaurin_series inputs must use the -1e300 result sentinel")
        elif expected == MACLAURIN_SERIES_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("maclaurin_series expected_result must match the source-ordered partial sum")
    elif algorithm == "hubble_parameter":
        source_result = hubble_parameter_expected(values)
        if source_result == HUBBLE_PARAMETER_INVALID_RESULT:
            if expected != HUBBLE_PARAMETER_INVALID_RESULT:
                raise ValueError("invalid hubble_parameter inputs must use the -1e300 result sentinel")
        elif expected == HUBBLE_PARAMETER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("hubble_parameter expected_result must match the source-ordered expansion formula")
    elif algorithm == "light_aberration":
        source_result = light_aberration_expected(values)
        if source_result == LIGHT_ABERRATION_INVALID_RESULT:
            if expected != LIGHT_ABERRATION_INVALID_RESULT:
                raise ValueError("invalid light_aberration inputs must use the -1e300 result sentinel")
        elif expected == LIGHT_ABERRATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=5e-12):
            raise ValueError("light_aberration expected_result must match the rounded source formula")
    elif algorithm == "half_wave_rectifier":
        if (len(values) != 5 or any(value < -1_000_000 or value > 1_000_000 for value in values[1:])):
            source_result = -1.0e300
        else:
            operation, a, b, c, d = values
            if operation == 0 and a >= 0 and b >= 0 and c >= 0 and a + b + c > 0:
                source_result = d / (a + b + c)
            elif operation in (1, 2) and b == c == d == 0:
                source_result = a * 0.318
            elif operation == 3 and b > 0 and c == d == 0:
                source_result = a / b
            elif operation in (4, 5) and b == c == d == 0:
                source_result = a / 2.0
            else:
                source_result = -1.0e300
        if source_result == -1.0e300:
            if expected != -1.0e300:
                raise ValueError("invalid half_wave_rectifier inputs must use the -1e300 result sentinel")
        elif expected == -1.0e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("half_wave_rectifier expected_result must match the selected pinned formula")
    elif algorithm == "variance":
        source_result = variance_expected(values)
        if source_result == VARIANCE_INVALID_RESULT:
            if expected != VARIANCE_INVALID_RESULT:
                raise ValueError("invalid variance inputs must use the -1e300 result sentinel")
        elif expected == VARIANCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("variance expected_result must match the source-ordered sample formula")
    elif algorithm == "welfords_variance":
        if len(values) < 2 or len(values) > 64 or any(value < -1_000_000 or value > 1_000_000 for value in values):
            source_result = VARIANCE_INVALID_RESULT
        else:
            count = 0
            mean = 0.0
            m2 = 0.0
            for value in values:
                count += 1
                delta = float(value) - mean
                mean += delta / count
                m2 += delta * (float(value) - mean)
            source_result = m2 / (count - 1)
        if source_result == VARIANCE_INVALID_RESULT:
            if expected != VARIANCE_INVALID_RESULT:
                raise ValueError("invalid welfords_variance inputs must use the -1e300 result sentinel")
        elif expected == VARIANCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("welfords_variance expected_result must match the source-order Welford recurrence")
    elif algorithm == "dice_coefficient":
        source_result = dice_coefficient_expected(values)
        if source_result == DICE_COEFFICIENT_INVALID_RESULT:
            if expected != DICE_COEFFICIENT_INVALID_RESULT:
                raise ValueError("invalid dice_coefficient inputs must use the -1e300 result sentinel")
        elif expected == DICE_COEFFICIENT_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("dice_coefficient expected_result must match the source bigram scan")
    elif algorithm == "density":
        source_result = density_expected(values)
        if source_result == DENSITY_INVALID_RESULT:
            if expected != DENSITY_INVALID_RESULT:
                raise ValueError("invalid density inputs must use the -1e300 result sentinel")
        elif expected == DENSITY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("density expected_result must match the source formula")
    elif algorithm == "hinge_loss":
        source_result = hinge_loss_expected(values)
        if source_result == HINGE_LOSS_INVALID_RESULT:
            if expected != HINGE_LOSS_INVALID_RESULT:
                raise ValueError("invalid hinge_loss inputs must use the -1e300 result sentinel")
        elif expected == HINGE_LOSS_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("hinge_loss expected_result must match the ordered average hinge loss")
    elif algorithm == "collaborative_filtering":
        source_result = expected_prediction(values)
        if source_result == PREDICTION_INVALID_RESULT:
            if expected != PREDICTION_INVALID_RESULT:
                raise ValueError("invalid collaborative_filtering inputs must use the -1e300 result sentinel")
        elif expected == PREDICTION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("collaborative_filtering expected_result must match the injected-similarity prediction")
    elif algorithm == "collaborative_filtering_pearson_similarity":
        source_result = expected_pearson_similarity(values)
        if source_result == PEARSON_INVALID_RESULT:
            if expected != PEARSON_INVALID_RESULT:
                raise ValueError("invalid collaborative_filtering_pearson_similarity inputs must use the -2 result sentinel")
        elif expected == PEARSON_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("collaborative_filtering_pearson_similarity expected_result must match Pearson correlation")
    elif algorithm == "complementary_filter":
        source_result = complementary_filter_expected(values)
        if source_result == COMPLEMENTARY_FILTER_INVALID_RESULT:
            if expected != COMPLEMENTARY_FILTER_INVALID_RESULT:
                raise ValueError("invalid complementary_filter inputs must use the -1e300 result sentinel")
        elif expected == COMPLEMENTARY_FILTER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("complementary_filter expected_result must match the seeded source update order")
    elif algorithm == "comp_filt":
        source_result = comp_filt_expected(values)
        if source_result == COMP_FILT_INVALID_RESULT:
            if expected != COMP_FILT_INVALID_RESULT:
                raise ValueError("invalid comp_filt inputs must use the -1e300 result sentinel")
        elif expected == COMP_FILT_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("comp_filt expected_result must match the selected scanl trace value")
    elif algorithm == "standard_deviation":
        source_result = standard_deviation_expected(values)
        if source_result == STANDARD_DEVIATION_INVALID_RESULT:
            if expected != STANDARD_DEVIATION_INVALID_RESULT:
                raise ValueError("invalid standard_deviation inputs must use the -1e300 result sentinel")
        elif expected == STANDARD_DEVIATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("standard_deviation expected_result must match the two-pass population formula")
    elif algorithm == "euclidean_distance":
        source_result = euclidean_distance_expected(values)
        if source_result == EUCLIDEAN_DISTANCE_INVALID_RESULT:
            if expected != EUCLIDEAN_DISTANCE_INVALID_RESULT:
                raise ValueError("invalid euclidean_distance inputs must use the -1e300 result sentinel")
        elif expected == EUCLIDEAN_DISTANCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("euclidean_distance expected_result must match sqrt of summed squared differences")
    elif algorithm == "dynamic_time_warping":
        source_result = dynamic_time_warping_expected(values)
        if source_result == DYNAMIC_TIME_WARPING_INVALID_RESULT:
            if expected != DYNAMIC_TIME_WARPING_INVALID_RESULT:
                raise ValueError("invalid dynamic_time_warping inputs must use the -1e300 result sentinel")
        elif expected == DYNAMIC_TIME_WARPING_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("dynamic_time_warping expected_result must match the source banded recurrence")
    elif algorithm == "yin":
        source_result = yin_expected(values)
        if source_result == YIN_INVALID_RESULT:
            if expected != YIN_INVALID_RESULT:
                raise ValueError("invalid yin inputs must use the -1e300 result sentinel")
        elif expected == YIN_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("yin expected_result must match the source-order interpolated pitch estimate")
    elif algorithm == "apparent_power":
        source_result = apparent_power_expected(values)
        if source_result == APPARENT_POWER_INVALID_RESULT:
            if expected != APPARENT_POWER_INVALID_RESULT:
                raise ValueError("invalid apparent_power inputs must use the -1e300 result sentinel")
        elif expected == APPARENT_POWER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("apparent_power expected_result must match the selected phasor product component")
    elif algorithm == "distance_between_two_points":
        source_result = distance_between_two_points_expected(values)
        if source_result == DISTANCE_BETWEEN_TWO_POINTS_INVALID_RESULT:
            if expected != DISTANCE_BETWEEN_TWO_POINTS_INVALID_RESULT:
                raise ValueError("invalid distance_between_two_points inputs must use the -1e300 result sentinel")
        elif expected == DISTANCE_BETWEEN_TWO_POINTS_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("distance_between_two_points expected_result must match the 2D Euclidean formula")
    elif algorithm == "archimedes_principle_of_buoyant_force":
        source_result = archimedes_principle_of_buoyant_force_expected(values)
        if source_result == ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT:
            if expected != ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT:
                raise ValueError("invalid Archimedes inputs must use the -1e300 result sentinel")
        elif expected == ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("Archimedes expected_result must match density * default gravity * volume")
    elif algorithm == "potential_energy":
        source_result = potential_energy_expected(values)
        if source_result == POTENTIAL_ENERGY_INVALID_RESULT:
            if expected != POTENTIAL_ENERGY_INVALID_RESULT:
                raise ValueError("invalid potential_energy inputs must use the -1e300 result sentinel")
        elif expected == POTENTIAL_ENERGY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("potential_energy expected_result must match mass * default gravity * height")
    elif algorithm == "sum_of_arithmetic_series":
        source_result = sum_of_arithmetic_series_expected(values)
        if source_result == SUM_OF_ARITHMETIC_SERIES_INVALID_RESULT:
            if expected != SUM_OF_ARITHMETIC_SERIES_INVALID_RESULT:
                raise ValueError("invalid sum_of_arithmetic_series inputs must use the -1e300 result sentinel")
        elif expected == SUM_OF_ARITHMETIC_SERIES_INVALID_RESULT or expected != source_result:
            raise ValueError("sum_of_arithmetic_series expected_result must match the finite-series formula")
    elif algorithm == "centripetal_force":
        source_result = centripetal_force_expected(values)
        if source_result == CENTRIPETAL_FORCE_INVALID_RESULT:
            if expected != CENTRIPETAL_FORCE_INVALID_RESULT:
                raise ValueError("invalid centripetal_force inputs must use the -1e300 result sentinel")
        elif expected == CENTRIPETAL_FORCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("centripetal_force expected_result must match (mass * velocity^2) / radius")
    elif algorithm == "cone":
        source_result = cone_expected(values)
        if source_result == CONE_INVALID_RESULT:
            if expected != CONE_INVALID_RESULT:
                raise ValueError("invalid cone inputs must use the -1e300 result sentinel")
        elif expected == CONE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("cone expected_result must match the selected source volume or surface-area formula")
    elif algorithm == "cohen_sutherland":
        source_result = cohen_sutherland_expected(values)
        if source_result == COHEN_SUTHERLAND_INVALID_RESULT:
            if expected != COHEN_SUTHERLAND_INVALID_RESULT:
                raise ValueError("invalid cohen_sutherland inputs must use the -1e300 result sentinel")
        elif expected == COHEN_SUTHERLAND_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-9):
            raise ValueError("cohen_sutherland expected_result must match the selected clipped coordinate or acceptance flag")
    elif algorithm == "lamberts_ellipsoidal_distance":
        source_result = lamberts_ellipsoidal_distance_expected(values)
        if source_result == LAMBERTS_ELLIPSOIDAL_DISTANCE_INVALID_RESULT:
            if expected != LAMBERTS_ELLIPSOIDAL_DISTANCE_INVALID_RESULT:
                raise ValueError("invalid lamberts_ellipsoidal_distance inputs must use the -1e300 result sentinel")
        elif expected == LAMBERTS_ELLIPSOIDAL_DISTANCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-6):
            raise ValueError("lamberts_ellipsoidal_distance expected_result must match the bounded WGS-84 Lambert distance in meters")
    elif algorithm == "p2_quantile_estimator":
        source_result = p2_quantile_expected(values)
        if source_result == P2_QUANTILE_INVALID_RESULT:
            if expected != P2_QUANTILE_INVALID_RESULT:
                raise ValueError("invalid p2_quantile_estimator inputs must use the -1e300 result sentinel")
        elif expected == P2_QUANTILE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("p2_quantile_estimator expected_result must match the bounded Java P² median updates")
    elif algorithm == "peak_signal_to_noise_ratio":
        source_result = peak_signal_to_noise_ratio_expected(values)
        if source_result == PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT:
            if expected != PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT:
                raise ValueError("invalid peak_signal_to_noise_ratio inputs must use the -1e300 result sentinel")
        elif expected == PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("peak_signal_to_noise_ratio expected_result must match the bounded non-identical image formula")
    elif algorithm == "prefix_evaluation":
        source_result = prefix_evaluation_expected(values)
        if source_result == PREFIX_EVALUATION_INVALID_RESULT:
            if expected != PREFIX_EVALUATION_INVALID_RESULT:
                raise ValueError("invalid prefix_evaluation input must use the -1e300 result sentinel")
        elif expected == PREFIX_EVALUATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("prefix_evaluation expected_result must match the bounded prefix stack evaluation")
    elif algorithm == "reverse_polish_notation":
        source_result = reverse_polish_notation_expected(values)
        if source_result == REVERSE_POLISH_NOTATION_INVALID_RESULT:
            if expected != REVERSE_POLISH_NOTATION_INVALID_RESULT:
                raise ValueError("invalid reverse_polish_notation inputs must use the -1e300 result sentinel")
        elif expected == REVERSE_POLISH_NOTATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("reverse_polish_notation expected_result must match the bounded source-order stack evaluation")
    elif algorithm == "kinetic_energy":
        source_result = kinetic_energy_expected(values)
        if source_result == KINETIC_ENERGY_INVALID_RESULT:
            if expected != KINETIC_ENERGY_INVALID_RESULT:
                raise ValueError("invalid kinetic_energy inputs must use the -1e300 result sentinel")
        elif expected == KINETIC_ENERGY_INVALID_RESULT or expected != source_result:
            raise ValueError("kinetic_energy expected_result must match 0.5 * mass * abs(velocity)^2")
    elif algorithm == "boyles_law":
        source_result = boyles_law_expected(values)
        if source_result == BOYLES_LAW_INVALID_RESULT:
            if expected != BOYLES_LAW_INVALID_RESULT:
                raise ValueError("invalid boyles_law inputs must use the -1e300 result sentinel")
        elif expected == BOYLES_LAW_INVALID_RESULT or expected != source_result:
            raise ValueError("boyles_law expected_result must match the selected exact-rational ties-to-even result")
    elif algorithm == "harmonic_mean":
        source_result = harmonic_mean_expected(values)
        if source_result == HARMONIC_MEAN_INVALID_RESULT:
            if expected != HARMONIC_MEAN_INVALID_RESULT:
                raise ValueError("invalid harmonic_mean inputs must use the -1e300 result sentinel")
        elif expected == HARMONIC_MEAN_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("harmonic_mean expected_result must match the ordered reciprocal-sum formula")
    elif algorithm == "is_harmonic_series":
        source_result = is_harmonic_series_expected(values)
        if source_result == IS_HARMONIC_SERIES_INVALID_RESULT:
            if expected != IS_HARMONIC_SERIES_INVALID_RESULT:
                raise ValueError("invalid is_harmonic_series inputs must use the -1e300 result sentinel")
        elif expected != source_result:
            raise ValueError("is_harmonic_series expected_result must match the exact reciprocal-difference predicate")
    elif algorithm == "quadratic_mean":
        source_result = quadratic_mean_expected(values)
        if source_result == QUADRATIC_MEAN_INVALID_RESULT:
            if expected != QUADRATIC_MEAN_INVALID_RESULT:
                raise ValueError("invalid quadratic_mean inputs must use the -1e300 result sentinel")
        elif expected == QUADRATIC_MEAN_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("quadratic_mean expected_result must match the ordered squared-value mean")
    elif algorithm == "charging_inductor":
        source_result = charging_inductor_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid charging_inductor inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-15, abs_tol=1e-12):
            raise ValueError("charging_inductor expected_result must match the rounded RL current formula")
    elif algorithm == "speed":
        source_result = speed_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid speed inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-16, abs_tol=1e-12):
            raise ValueError("speed expected_result must match the seven-unit Rust conversion and ties-away rounding")
    elif algorithm == "color_contrast_ratio":
        source_result = color_contrast_ratio_expected(values)
        if source_result == COLOR_CONTRAST_INVALID_RESULT:
            if expected != COLOR_CONTRAST_INVALID_RESULT:
                raise ValueError("invalid color_contrast_ratio inputs must use the -1e300 result sentinel")
        elif expected == COLOR_CONTRAST_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("color_contrast_ratio expected_result must match the pinned luminance calculation")
    elif algorithm == "butterworth_filter":
        source_result = butterworth_filter_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid butterworth_filter inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("butterworth_filter expected_result must match the selected biquad coefficient")
    elif algorithm == "center_of_mass":
        source_result = center_of_mass_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid center_of_mass inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("center_of_mass expected_result must match the selected rounded weighted coordinate")
    elif algorithm == "automatic_differentiation":
        source_result = automatic_differentiation(values)
        if expected == -1e300:
            if source_result != -1e300:
                raise ValueError("automatic_differentiation input is valid but workload uses the invalid/disconnected sentinel")
        elif source_result == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("automatic_differentiation expected_result must match scalar reverse accumulation")
    elif algorithm == "quadratic_equation_solver_complex_roots":
        source_result = quadratic_equation_solver_expected(values)
        if source_result == QUADRATIC_EQUATION_SOLVER_INVALID_RESULT:
            if expected != QUADRATIC_EQUATION_SOLVER_INVALID_RESULT:
                raise ValueError("invalid quadratic-equation inputs must use the -1e300 result sentinel")
        elif expected == QUADRATIC_EQUATION_SOLVER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("quadratic-equation expected_result must match the selected source-ordered root component")
    elif algorithm == "durand_kerner_roots":
        source_result = durand_kerner_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid Durand–Kerner inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("Durand–Kerner expected_result must match the selected root component")
    elif algorithm == "ground_to_ground_projectile_motion":
        source_result = ground_projectile_expected(values)
        if source_result == GROUND_PROJECTILE_INVALID_RESULT:
            if expected != GROUND_PROJECTILE_INVALID_RESULT:
                raise ValueError("invalid projectile-motion inputs must use the -1e300 result sentinel")
        elif expected == GROUND_PROJECTILE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("projectile-motion expected_result must match the selected source formula")
    elif algorithm == "huber_loss":
        source_result = huber_loss_expected(values)
        if source_result == HUBER_LOSS_INVALID_RESULT:
            if expected != HUBER_LOSS_INVALID_RESULT:
                raise ValueError("invalid huber_loss inputs must use the -1e300 result sentinel")
        elif expected == HUBER_LOSS_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("huber_loss expected_result must match the mean paired Huber loss")
    elif algorithm == "huber_loss_math":
        source_result = huber_loss_math_expected(values)
        if source_result == HUBER_LOSS_MATH_INVALID_RESULT:
            if expected != HUBER_LOSS_MATH_INVALID_RESULT:
                raise ValueError("invalid huber_loss_math inputs must use the -1e300 result sentinel")
        elif expected == HUBER_LOSS_MATH_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("huber_loss_math expected_result must match the source's summed zip loss")
    elif algorithm == "exponential_dist":
        source_result = exponential_dist_expected(values)
        if source_result == EXPONENTIAL_DIST_INVALID_RESULT:
            if expected != EXPONENTIAL_DIST_INVALID_RESULT:
                raise ValueError("invalid exponential_dist inputs must use the -1e300 result sentinel")
        elif expected == EXPONENTIAL_DIST_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("exponential_dist expected_result must match the selected distribution statistic")
    elif algorithm == "expected_shortfall":
        source_result = expected_shortfall_expected(values)
        if source_result == EXPECTED_SHORTFALL_INVALID_RESULT:
            if expected != EXPECTED_SHORTFALL_INVALID_RESULT:
                raise ValueError("invalid expected_shortfall inputs must use the -1e300 result sentinel")
        elif expected == EXPECTED_SHORTFALL_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("expected_shortfall expected_result must match the interpolated lower-tail mean")
    elif algorithm == "time_converter":
        source_result = time_converter_expected(values)
        if source_result == TIME_CONVERTER_INVALID_RESULT:
            if expected != TIME_CONVERTER_INVALID_RESULT:
                raise ValueError("invalid time_converter inputs must use the -1e300 result sentinel")
        elif expected == TIME_CONVERTER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("time_converter expected_result must match the selected factors and three-place rounding")
    elif algorithm == "temperature_converter":
        source_result = temperature_converter_expected(values)
        if source_result == TEMPERATURE_CONVERTER_INVALID_RESULT:
            if expected != TEMPERATURE_CONVERTER_INVALID_RESULT:
                raise ValueError("invalid temperature_converter inputs must use the -1e300 result sentinel")
        elif expected == TEMPERATURE_CONVERTER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("temperature_converter expected_result must match the selected direct Java expression")
    elif algorithm == "value_at_risk":
        source_result = value_at_risk_expected(values)
        if source_result == VALUE_AT_RISK_INVALID_RESULT:
            if expected != VALUE_AT_RISK_INVALID_RESULT:
                raise ValueError("invalid value_at_risk inputs must use the -1e300 result sentinel")
        elif expected == VALUE_AT_RISK_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("value_at_risk expected_result must match the interpolated negative quantile")
    elif algorithm == "energy":
        source_result = energy_expected(values)
        if source_result == ENERGY_INVALID_RESULT:
            if expected != ENERGY_INVALID_RESULT:
                raise ValueError("invalid energy inputs must use the -1e300 result sentinel")
        elif expected == ENERGY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=0.0):
            raise ValueError("energy expected_result must match the source-ordered joule conversion")
    elif algorithm == "trapezoidal_integration":
        source_result = trapezoidal_integration_expected(values)
        if source_result == TRAPEZOIDAL_INTEGRATION_INVALID_RESULT:
            if expected != TRAPEZOIDAL_INTEGRATION_INVALID_RESULT:
                raise ValueError("invalid trapezoidal_integration inputs must use the -1e300 result sentinel")
        elif expected == TRAPEZOIDAL_INTEGRATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("trapezoidal_integration expected_result must match the oriented source-order trapezoid sum")
    elif algorithm == "neville":
        source_result = neville_expected(values)
        if source_result == NEVILLE_INVALID_RESULT:
            if expected != NEVILLE_INVALID_RESULT:
                raise ValueError("invalid neville inputs must use the -1e300 result sentinel")
        elif expected == NEVILLE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("neville expected_result must match the source-ordered interpolation recurrence")
    elif algorithm == "midpoint_integral_method":
        source_result = midpoint_integral_method_expected(values)
        if source_result == MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT:
            if expected != MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT:
                raise ValueError("invalid midpoint_integral_method inputs must use the -1e300 result sentinel")
        elif expected == MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("midpoint_integral_method expected_result must match the source-order midpoint sum")
    elif algorithm == "weddles_rule":
        source_result = weddles_rule_expected(values)
        if source_result == WEDDLES_RULE_INVALID_RESULT:
            if expected != WEDDLES_RULE_INVALID_RESULT:
                raise ValueError("invalid weddles_rule inputs must use the -1e300 result sentinel")
        elif expected == WEDDLES_RULE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("weddles_rule expected_result must match the source-order weighted sample sum")
    elif algorithm == "units_converter":
        source_result = units_converter_expected(values)
        if source_result == UNITS_CONVERTER_INVALID_RESULT:
            if expected != UNITS_CONVERTER_INVALID_RESULT:
                raise ValueError("invalid units_converter inputs must use the -1e300 result sentinel")
        elif expected == UNITS_CONVERTER_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("units_converter expected_result must match the bounded affine conversion closure")
    elif algorithm == "ternary_search_min_max_recursive":
        source_result = ternary_search_min_max_expected(values)
        if source_result == TERNARY_SEARCH_MIN_MAX_INVALID_RESULT:
            if expected != TERNARY_SEARCH_MIN_MAX_INVALID_RESULT:
                raise ValueError("invalid ternary_search_min_max_recursive inputs must use the -1e300 result sentinel")
        elif expected == TERNARY_SEARCH_MIN_MAX_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("ternary_search_min_max_recursive expected_result must match the binary32 recursive search")
    elif algorithm == "cosine_similarity":
        source_result = cosine_similarity_expected(values)
        if source_result == COSINE_SIMILARITY_INVALID_RESULT:
            if expected != COSINE_SIMILARITY_INVALID_RESULT:
                raise ValueError("invalid cosine_similarity inputs must use the -1e300 result sentinel")
        elif expected == COSINE_SIMILARITY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("cosine_similarity expected_result must match the case-folded printable-ASCII frequency cosine")
    elif algorithm == "interquartile_range":
        valid = (2 <= len(values) <= 64
                 and all(-1_000_000 <= value <= 1_000_000 for value in values))
        source_result = -1e300
        if valid:
            ordered = sorted(values)
            half = len(ordered) // 2
            upper_start = half + len(ordered) % 2

            def median(part: list[int]) -> float:
                middle = len(part) // 2
                if len(part) % 2:
                    return float(part[middle])
                return (part[middle - 1] + part[middle]) / 2.0

            source_result = median(ordered[upper_start:]) - median(ordered[:half])
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid interquartile_range inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("interquartile_range expected result must match the source lower/upper-half median rule")
    elif algorithm == "treynor_ratio":
        valid = (len(values) == 3 and all(-1000 <= value <= 1000 for value in values)
                 and values[2] != 0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid treynor_ratio inputs must use the -1e300 result sentinel")
        else:
            portfolio_return, risk_free_rate, beta = values
            source_result = (portfolio_return - risk_free_rate) / beta
            if expected == -1e300 or not math.isclose(
                    expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("treynor_ratio expected_result must match (portfolio_return - risk_free_rate) / beta")
    elif algorithm == "logistic_regression_csharp_binary_gd":
        valid = len(values) >= 4
        source_result = -1e300
        if valid:
            sample_count, feature_count, epochs, rate_q = values[:4]
            valid = (1 <= sample_count <= 32 and 1 <= feature_count <= 8
                     and 0 <= epochs <= 128 and 1 <= rate_q <= 100_000
                     and len(values) == 4 + sample_count * (feature_count + 1) + feature_count)
        if valid:
            feature_end = 4 + sample_count * feature_count
            label_end = feature_end + sample_count
            raw_features = values[4:feature_end]
            labels = values[feature_end:label_end]
            raw_query = values[label_end:]
            valid = (all(-1_000_000 <= value <= 1_000_000 for value in raw_features)
                     and all(label in (0, 1) for label in labels)
                     and len(raw_query) == feature_count
                     and all(-1_000_000 <= value <= 1_000_000 for value in raw_query))
        if valid:
            scale = 1_000_000.0
            samples = [raw_features[row * feature_count:(row + 1) * feature_count]
                       for row in range(sample_count)]
            samples = [[value / scale for value in row] for row in samples]
            query = [value / scale for value in raw_query]
            learning_rate = rate_q / scale
            weights = [0.0] * feature_count
            bias = 0.0
            for _ in range(epochs):
                weight_gradient = [0.0] * feature_count
                bias_gradient = 0.0
                for row, label in zip(samples, labels):
                    linear = sum(feature * weight for feature, weight in zip(row, weights)) + bias
                    probability = 1.0 / (1.0 + math.exp(-linear))
                    error = probability - label
                    for column, feature in enumerate(row):
                        weight_gradient[column] += error * feature
                    bias_gradient += error
                weights = [weight - learning_rate * gradient / sample_count
                           for weight, gradient in zip(weights, weight_gradient)]
                bias -= learning_rate * bias_gradient / sample_count
            query_linear = sum(feature * weight for feature, weight in zip(query, weights)) + bias
            source_result = 1.0 / (1.0 + math.exp(-query_linear))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid logistic_regression_csharp_binary_gd inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("logistic_regression_csharp_binary_gd expected_result must match the C# batch weight/bias updates and query probability")
    elif algorithm == "negative_log_likelihood":
        valid = (len(values) >= 1 and 1 <= values[0] <= 64
                 and len(values) == 1 + 2 * values[0])
        source_result = -1e300
        if valid:
            n = values[0]
            actual = values[1:1 + n]
            predicted = values[1 + n:]
            valid = (all(0 <= value <= 1_000_000 for value in actual)
                     and all(1 <= value <= 999_999 for value in predicted))
            if valid:
                scale = 1_000_000.0
                total = 0.0
                for actual_value, predicted_value in zip(actual, predicted):
                    actual_probability = actual_value / scale
                    predicted_probability = predicted_value / scale
                    total += (-actual_probability * math.log(predicted_probability)
                              - (1.0 - actual_probability) * math.log(1.0 - predicted_probability))
                source_result = total / n
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid negative_log_likelihood inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("negative_log_likelihood expected_result must match the pinned source-ordered mean")
    elif algorithm == "cross_entropy_loss":
        valid = (len(values) >= 1 and 1 <= values[0] <= 64
                 and len(values) == 1 + 2 * values[0])
        source_result = -1e300
        if valid:
            n = values[0]
            actual = values[1:1 + n]
            predicted = values[1 + n:]
            valid = (all(0 <= value <= 1_000_000 for value in actual)
                     and all(1 <= value <= 1_000_000 for value in predicted))
            if valid:
                scale = 1_000_000.0
                terms = [-(value / scale) * math.log(probability / scale)
                         for value, probability in zip(actual, predicted)]
                source_result = 0.0
                for term in terms:
                    source_result += term
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid cross_entropy_loss inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("cross_entropy_loss expected_result must match the pinned source-ordered term sum")
    elif algorithm == "anova_oneway":
        valid = len(values) >= 3
        source_result = -1e300
        if valid:
            selector, observation_count, group_count = values[:3]
            valid = (selector in range(8) and 3 <= observation_count <= 128
                     and 2 <= group_count <= 8 and observation_count > group_count
                     and len(values) == 3 + 2 * observation_count)
            if valid:
                observations = values[3:3 + observation_count]
                labels = values[3 + observation_count:]
                valid = (all(-1_000_000 <= value <= 1_000_000 for value in observations)
                         and all(0 <= label < group_count for label in labels)
                         and all(label in labels for label in range(group_count)))
                if valid:
                    sums = [0.0] * group_count
                    sizes = [0] * group_count
                    for observation, label in zip(observations, labels):
                        sums[label] += observation
                        sizes[label] += 1
                    means = [sums[group] / sizes[group] for group in range(group_count)]
                    grand_mean = sum(observations) / observation_count
                    ss_between = sum(sizes[group] * (means[group] - grand_mean) ** 2
                                     for group in range(group_count))
                    ss_within = sum((observation - means[label]) ** 2
                                    for observation, label in zip(observations, labels))
                    valid = ss_within > 0.0
                    if valid:
                        df_between = float(group_count - 1)
                        df_within = float(observation_count - group_count)
                        ms_between = ss_between / df_between
                        ms_within = ss_within / df_within
                        f_statistic = ms_between / ms_within
                        beta_x = df_within / (df_within + df_between * f_statistic)

                        def beta_fraction(a: float, b: float, x: float) -> float:
                            qab, qap, qam = a + b, a + 1.0, a - 1.0

                            def safe_denominator(value: float) -> float:
                                if abs(value) >= 1e-300:
                                    return value
                                return -1e-300 if value < 0.0 else 1e-300

                            c = 1.0
                            d = 1.0 / safe_denominator(1.0 - qab * x / qap)
                            result = d
                            for iteration in range(1, 201):
                                m = float(iteration)
                                m2 = 2.0 * m
                                coefficient = m * (b - m) * x / ((qam + m2) * (a + m2))
                                d = 1.0 + coefficient * d
                                if abs(d) < 1e-300:
                                    d = 1e-300
                                c = 1.0 + coefficient / c
                                if abs(c) < 1e-300:
                                    c = 1e-300
                                d = 1.0 / d
                                result *= d * c
                                coefficient = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
                                d = 1.0 + coefficient * d
                                if abs(d) < 1e-300:
                                    d = 1e-300
                                c = 1.0 + coefficient / c
                                if abs(c) < 1e-300:
                                    c = 1e-300
                                d = 1.0 / d
                                change = d * c
                                result *= change
                                if abs(change - 1.0) <= 3e-14:
                                    break
                            return result

                        def regularized_beta(x: float, a: float, b: float) -> float:
                            if x <= 0.0:
                                return 0.0
                            if x >= 1.0:
                                return 1.0
                            front = math.exp(a * math.log(x) + b * math.log1p(-x)
                                             + math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b))
                            if x < (a + 1.0) / (a + b + 2.0):
                                return front * beta_fraction(a, b, x) / a
                            return 1.0 - front * beta_fraction(b, a, 1.0 - x) / b

                        p_value = regularized_beta(beta_x, df_within / 2.0, df_between / 2.0)
                        source_result = (df_between, df_within, ss_between, ss_within,
                                         ms_between, ms_within, f_statistic, p_value)[selector]
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid anova_oneway inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("anova_oneway expected_result must match the selected one-way ANOVA statistic")
    elif algorithm == "ant_colony_optimization":
        valid = (len(values) == 8 and 1 <= values[0] <= 64 and 1 <= values[1] <= 64
                 and all(-100_000 <= value <= 100_000 for value in values[2:]))
        source_result = -1e300
        if valid:
            cities = [(values[index], values[index + 1]) for index in (2, 4, 6)]
            valid = len(set(cities)) == 3
            if valid:
                def city_distance(first: tuple[int, int], second: tuple[int, int]) -> float:
                    dx = first[0] - second[0]
                    dy = first[1] - second[1]
                    return math.sqrt(dx * dx + dy * dy)

                source_result = (city_distance(cities[0], cities[1])
                                 + city_distance(cities[1], cities[2])
                                 + city_distance(cities[2], cities[0]))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid ant_colony_optimization inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("ant_colony_optimization expected_result must match the three-city closed tour length")
    if algorithm == "electrical_impedance":
        valid = (len(values) == 3 and all(0 <= value <= 1000 for value in values)
                 and sum(value == 0 for value in values) == 1)
        if valid:
            resistance, reactance, impedance = values
            if resistance == 0:
                valid = impedance >= reactance
                expected_from_source = (math.sqrt(impedance * impedance - reactance * reactance)
                                        if valid else -1e300)
            elif reactance == 0:
                valid = impedance >= resistance
                expected_from_source = (math.sqrt(impedance * impedance - resistance * resistance)
                                        if valid else -1e300)
            else:
                expected_from_source = math.sqrt(resistance * resistance + reactance * reactance)
        else:
            expected_from_source = -1e300
        if expected == -1e300:
            if valid:
                raise ValueError("valid electrical_impedance inputs cannot use the invalid sentinel")
        elif (not valid or not math.isclose(expected, expected_from_source,
                                            rel_tol=1e-12, abs_tol=1e-12)):
            raise ValueError("electrical_impedance expected_result must match its selected impedance formula")
    elif algorithm in {"average_absolute_deviation", "average_absolute_deviation_rounded"}:
        valid = (1 <= len(values) <= 256
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values))
        if not valid:
            if expected != -1e300:
                raise ValueError(f"invalid {algorithm} inputs must use the -1e300 result sentinel")
        else:
            mean = sum(values) / len(values)
            source_result = sum(abs(value - mean) for value in values) / len(values)
            if algorithm == "average_absolute_deviation_rounded":
                source_result = round(source_result, 2)
            if not math.isclose(expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError(f"{algorithm} expected_result must match the source mean-deviation formula")
    elif algorithm == "median_two_array":
        expected_from_source = median_two_array_expected(values)
        if not math.isclose(expected, expected_from_source, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("median_two_array expected_result must match the merged sorted median")
    elif algorithm == "manhattan_distance":
        valid = (len(values) >= 1 and 1 <= values[0] <= 16
                 and len(values) == 1 + 2 * values[0]
                 and all(-1_000_000 <= value <= 1_000_000 for value in values[1:]))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid manhattan_distance inputs must use the -1e300 result sentinel")
        else:
            dimension = values[0]
            source_result = sum(abs(values[1 + index] - values[1 + dimension + index])
                                for index in range(dimension))
            if not math.isclose(expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("manhattan_distance expected_result must match the n-dimensional L1 sum")
    elif algorithm == "wheatstone_bridge":
        valid = len(values) == 3 and all(1 <= value <= 1_000_000 for value in values)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid wheatstone_bridge inputs must use the -1e300 result sentinel")
        else:
            resistance_1, resistance_2, resistance_3 = values
            source_result = (resistance_2 / resistance_1) * resistance_3
            if not math.isclose(expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("wheatstone_bridge expected_result must match (R2 / R1) * R3")
    elif algorithm == "dodecahedron":
        valid = (len(values) == 2 and 1 <= values[0] <= 1_000_000
                 and values[1] in (0, 1))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid dodecahedron inputs must use the -1e300 result sentinel")
        else:
            edge, quantity = values
            if quantity == 0:
                source_result = (3 * ((25 + 10 * (5 ** (1 / 2))) ** (1 / 2))
                                 * (edge ** 2))
            else:
                source_result = ((15 + (7 * (5 ** (1 / 2)))) / 4) * (edge ** 3)
            if expected == -1e300 or not math.isclose(
                    expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("dodecahedron expected_result must match the selected source formula")
    elif algorithm == "jaccard_similarity":
        valid = (len(values) >= 2 and 0 <= values[0] <= 64 and 0 <= values[1] <= 64
                 and values[0] + values[1] > 0
                 and len(values) == 2 + values[0] + values[1])
        if valid:
            left = values[2:2 + values[0]]
            right = values[2 + values[0]:]
            valid = (all(32 <= value <= 126 for value in left + right)
                     and len(set(left)) == len(left) and len(set(right)) == len(right))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid jaccard_similarity inputs must use the -1e300 result sentinel")
        else:
            intersection = len(set(left) & set(right))
            source_result = intersection / (len(left) + len(right) - intersection)
            if expected == -1e300 or not math.isclose(
                    expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("jaccard_similarity expected_result must match intersection over union")
    elif algorithm == "distance_formula":
        valid = (len(values) == 4 and all(-1_000_000 <= value <= 1_000_000 for value in values))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid distance_formula inputs must use the -1e300 result sentinel")
        else:
            x1, _y1, x2, y2 = values
            dx = x2 - x1
            dy = y2 - x1
            source_result = math.sqrt(dx ** 2 + dy ** 2)
            if expected == -1e300 or not math.isclose(
                    expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("distance_formula expected_result must match the pinned Java expression")
    elif algorithm == "thin_lens":
        valid = (len(values) == 3 and values[0] in (0, 1, 2)
                 and all(-1000 <= value <= 1000 for value in values[1:]))
        if valid:
            operation, first, second = values
            if operation == 0:
                valid = first != 0 and second != 0 and first != second
                if valid:
                    source_result = 1.0 / ((1.0 / first) - (1.0 / second))
            elif operation == 1:
                valid = second != 0
                if valid:
                    source_result = first / second
            else:
                valid = second == 0
                if valid:
                    source_result = float(first > 0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid thin_lens inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("thin_lens expected_result must match the selected pinned Java operation")
    elif algorithm == "geometric_dist":
        def f32(value: float) -> float:
            return struct.unpack("<f", struct.pack("<f", float(value)))[0]

        valid = len(values) >= 2 and values[0] in range(7) and values[1] in range(3)
        source_result = -1.0e300
        if valid:
            operation, p_code = values[:2]
            probability = f32((0.25, 0.5, 0.75)[p_code])
            complement = f32(1.0 - probability)
            expected_length = 2 if operation in (0, 1, 2) else (4 if operation == 6 else 3)
            valid = len(values) == expected_length
            if valid and operation == 0:
                source_result = f32(1.0 / probability)
            elif valid and operation in (1, 2):
                variance = f32(f32(1.0 - probability) / f32(probability * probability))
                source_result = variance if operation == 1 else f32(math.sqrt(variance))
            elif valid and operation in (3, 4):
                k = values[2]
                valid = (1 <= k <= 16) if operation == 3 else (0 <= k <= 16)
                if valid and operation == 3:
                    power = f32(math.pow(complement, f32(k - 1)))
                    source_result = f32(power * probability)
                elif valid:
                    power = f32(math.pow(complement, f32(k)))
                    source_result = f32(1.0 - power)
            elif valid and operation == 5:
                cdf_code = values[2]
                valid = cdf_code in range(3)
                if valid:
                    cdf = f32((0.25, 0.5, 0.75)[cdf_code])
                    numerator = f32(math.log(f32(1.0 - cdf)))
                    denominator = f32(math.log(complement))
                    source_result = f32(numerator / denominator)
            elif valid and operation == 6:
                minimum, maximum = values[2:]
                valid = 1 <= minimum <= maximum <= 16
                if valid:
                    lower_power = f32(math.pow(complement, f32(minimum - 1)))
                    upper_power = f32(math.pow(complement, f32(maximum)))
                    lower = f32(1.0 - lower_power)
                    upper = f32(1.0 - upper_power)
                    source_result = f32(upper - lower)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid geometric_dist inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=3e-6, abs_tol=1e-12):
            raise ValueError("geometric_dist expected_result must match the source-ordered float32 operation")
    elif algorithm == "geometric":
        valid = len(values) >= 2 and values[0] in (0, 1)
        source_result = -1.0e300
        if valid:
            operation = values[0]
            sequence = values[1:]
            if operation == 0:
                valid = (1 <= len(sequence) <= 16
                         and all(-100 <= value <= 100 for value in sequence))
                if valid and len(sequence) == 1:
                    source_result = 1.0
                elif valid:
                    if sequence[0] == 0:
                        source_result = 0.0
                    else:
                        common_ratio = sequence[1] / sequence[0]
                        source_result = 1.0
                        for index in range(len(sequence) - 1):
                            if sequence[index] == 0 or sequence[index + 1] / sequence[index] != common_ratio:
                                source_result = 0.0
                                break
            else:
                valid = (1 <= len(sequence) <= 7
                         and all(0 <= value <= 100 for value in sequence))
                if valid:
                    product = 1
                    for value in sequence:
                        product *= value
                    source_result = math.pow(product, 1.0 / len(sequence))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid geometric inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("geometric expected_result must match the selected source operation")
    elif algorithm == "linear_regression_cost":
        source_result = linear_regression_cost_expected(values)
        if source_result == LINEAR_REGRESSION_COST_INVALID_RESULT:
            if expected != LINEAR_REGRESSION_COST_INVALID_RESULT:
                raise ValueError("invalid linear_regression_cost inputs must use the -1e300 result sentinel")
        elif expected == LINEAR_REGRESSION_COST_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("linear_regression_cost expected_result must match the bounded half-MSE formula")
    elif algorithm == "linear_regression_ols":
        valid = (len(values) >= 1 and 2 <= values[0] <= 128
                 and len(values) == 1 + 2 * values[0])
        source_result = -1e300
        if valid:
            observation_count = values[0]
            x_values = values[1::2]
            y_values = values[2::2]
            valid = (all(-1_000_000 <= value <= 1_000_000 for value in x_values + y_values)
                     and len(set(x_values)) > 1 and len(set(y_values)) > 1)
            if valid:
                mean_x = sum(x_values) / observation_count
                mean_y = sum(y_values) / observation_count
                covariance = sum((x - mean_x) * (y - mean_y)
                                 for x, y in zip(x_values, y_values))
                variance_x = sum((x - mean_x) ** 2 for x in x_values)
                source_result = covariance / variance_x
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid linear_regression_ols inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("linear_regression_ols expected_result must match the bounded OLS slope")
    elif algorithm == "gradient_descent":
        source_result = gradient_descent_expected(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid gradient_descent inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("gradient_descent expected_result must match the pinned quadratic-gradient updates")
    elif algorithm == "linear_regression_gradient_descent":
        valid = (len(values) >= 3 and 2 <= values[0] <= 64
                 and 1 <= values[1] <= 1000 and 1 <= values[2] <= 10_000
                 and len(values) == 3 + 2 * values[0])
        source_result = -1e300
        if valid:
            observation_count, rate_microunits, epochs = values[:3]
            observations = list(zip(values[3::2], values[4::2]))
            valid = (all(-10 <= x_value <= 10 for x_value, _ in observations)
                     and all(-100 <= y_value <= 100 for _, y_value in observations))
            if valid:
                alpha = rate_microunits / 1_000_000.0
                learning_rate = alpha / 2.0
                gradient_factor = 2.0 / observation_count
                slope = 0.0
                intercept = 0.0
                for _ in range(epochs):
                    slope_gradient = 0.0
                    intercept_gradient = 0.0
                    for x_value, y_value in observations:
                        residual = slope * x_value + intercept - y_value
                        slope_gradient += residual * x_value
                        intercept_gradient += residual
                    slope -= gradient_factor * slope_gradient * learning_rate
                    intercept -= gradient_factor * intercept_gradient * learning_rate
                source_result = slope
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid linear_regression_gradient_descent inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("linear_regression_gradient_descent expected_result must match the source-ordered batch updates")
    elif algorithm == "kendall_rank_correlation_coefficient":
        source_result = kendall_rank_correlation_expected(values)
        if source_result == KENDALL_RANK_CORRELATION_INVALID_RESULT:
            if expected != KENDALL_RANK_CORRELATION_INVALID_RESULT:
                raise ValueError("invalid kendall_rank_correlation_coefficient inputs must use the -1e300 result sentinel")
        elif expected == KENDALL_RANK_CORRELATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("kendall_rank_correlation_coefficient expected_result must match Kendall tau-b")
    elif algorithm == "spearman_average_rank_correlation":
        source_result = spearman_average_rank_expected(values)
        if source_result == SPEARMAN_AVERAGE_RANK_INVALID_RESULT:
            if expected != SPEARMAN_AVERAGE_RANK_INVALID_RESULT:
                raise ValueError("invalid spearman_average_rank_correlation inputs must use the -1e300 result sentinel")
        elif expected == SPEARMAN_AVERAGE_RANK_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("spearman_average_rank_correlation expected_result must match Pearson correlation over average ranks")
    elif algorithm == "pearson_correlation":
        source_result = pearson_correlation_expected(values)
        if source_result == PEARSON_CORRELATION_INVALID_RESULT:
            if expected != PEARSON_CORRELATION_INVALID_RESULT:
                raise ValueError("invalid pearson_correlation inputs must use the -1e300 result sentinel")
        elif expected == PEARSON_CORRELATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("pearson_correlation expected_result must match the centered-sum Pearson coefficient")
    elif algorithm == "correlation":
        valid = (len(values) >= 1 and 1 <= values[0] <= 128
                 and len(values) == 1 + 2 * values[0])
        source_result = -1e300
        if valid:
            sample_count = values[0]
            x_values = values[1:1 + sample_count]
            y_values = values[1 + sample_count:]
            valid = all(-1000 <= value <= 1000 for value in x_values + y_values)
            if valid:
                expected_xy = expected_x = expected_xx = expected_y = expected_yy = 0.0
                for x_value, y_value in zip(x_values, y_values):
                    expected_xy += x_value * y_value
                    expected_x += x_value
                    expected_xx += x_value * x_value
                    expected_y += y_value
                    expected_yy += y_value * y_value
                expected_xy /= sample_count
                expected_x /= sample_count
                expected_xx /= sample_count
                expected_y /= sample_count
                expected_yy /= sample_count
                covariance = expected_xy - expected_x * expected_y
                variance_x = math.sqrt(expected_xx - expected_x * expected_x)
                variance_y = math.sqrt(expected_yy - expected_y * expected_y)
                variance_product = variance_x * variance_y
                source_result = (0.0 if variance_product < 1e-9
                                 else covariance / math.sqrt(variance_product))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid correlation inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("correlation expected_result must match the ordered pinned Java formula")
    elif algorithm == "spearman_rank_correlation_coefficient":
        valid = (len(values) >= 1 and 2 <= values[0] <= 3
                 and len(values) == 1 + 2 * values[0])
        source_result = -1e300
        if valid:
            sample_count = values[0]
            x_values = values[1:1 + sample_count]
            y_values = values[1 + sample_count:]
            valid = all(-1000 <= value <= 1000 for value in x_values + y_values)
            if valid:
                def average_ranks(samples: list[int]) -> list[Fraction]:
                    order = sorted(range(len(samples)), key=samples.__getitem__)
                    ranks = [Fraction(0)] * len(samples)
                    start = 0
                    while start < len(order):
                        end = start + 1
                        while end < len(order) and samples[order[end]] == samples[order[start]]:
                            end += 1
                        average_rank = Fraction(start + 1 + end, 2)
                        for position in range(start, end):
                            ranks[order[position]] = average_rank
                        start = end
                    return ranks

                x_ranks = average_ranks(x_values)
                y_ranks = average_ranks(y_values)
                squared_rank_difference = sum(
                    (x_rank - y_rank) ** 2 for x_rank, y_rank in zip(x_ranks, y_ranks)
                )
                rho = 1 - 6 * squared_rank_difference / (sample_count * (sample_count**2 - 1))
                source_result = round(float(rho), 1)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid spearman_rank_correlation_coefficient inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("spearman_rank_correlation_coefficient expected_result must match average ranks and Python one-decimal rounding")
    elif algorithm == "npv":
        valid = (len(values) >= 2 and 0 <= values[0] <= 64
                 and 0 <= values[1] <= 1000 and len(values) == values[0] + 2)
        source_result = -1e300
        if valid:
            cash_flows = values[2:]
            valid = all(-1_000_000 <= cash_flow <= 1_000_000 for cash_flow in cash_flows)
            if valid:
                rate = values[1] / 10_000.0
                source_result = 0.0
                for period, cash_flow in enumerate(cash_flows):
                    source_result += cash_flow / math.pow(1.0 + rate, period)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid npv inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("npv expected_result must match the zero-based source-ordered discounted sum")
    elif algorithm == "meter_to_feet_conversion":
        valid = (len(values) == 2 and values[0] in (0, 1)
                 and -1_000_000_000 <= values[1] <= 1_000_000_000)
        source_result = -1e300
        if valid:
            operation, milliunits = values
            value = milliunits / 1000.0
            source_result = value * 0.3048 if operation == 0 else value / 0.3048
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid meter_to_feet_conversion inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("meter_to_feet_conversion expected_result must match the source conversion expression")
    elif algorithm == "real_and_reactive_power":
        valid = (len(values) == 3 and values[0] in (0, 1)
                 and -1_000_000_000 <= values[1] <= 1_000_000_000
                 and -10_000 <= values[2] <= 10_000)
        source_result = -1e300
        if valid:
            operation, apparent_power, factor_basis_points = values
            power_factor = factor_basis_points / 10_000.0
            if operation == 0:
                source_result = apparent_power * power_factor
            else:
                source_result = apparent_power * math.sqrt(1.0 - power_factor**2)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid real_and_reactive_power inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("real_and_reactive_power expected_result must match the selected source expression")
    elif algorithm == "power_factor_correction":
        valid = (len(values) == 6 and values[0] in (0, 1)
                 and 1 <= values[1] <= 1000 and 1 <= values[2] <= 1000
                 and -1_000_000 <= values[3] <= 1_000_000
                 and -10_000 <= values[4] <= 10_000
                 and -10_000 <= values[5] <= 10_000
                 and values[4] != 0 and values[5] != 0)
        source_result = -1e300
        if valid:
            operation, voltage, frequency, real_power, current_units, expected_units = values
            if operation == 1 and (current_units == expected_units or real_power == 0):
                valid = False
            else:
                current = current_units / 10_000.0
                expected_factor = expected_units / 10_000.0
                current_q = (real_power / current) * math.sin(math.acos(current))
                expected_q = (real_power / expected_factor) * math.sin(math.acos(expected_factor))
                change_q = current_q - expected_q
                if operation == 0:
                    source_result = change_q / (2 * math.pi * frequency * (voltage**2))
                else:
                    source_result = (voltage**2) / (2 * math.pi * frequency * change_q)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid power_factor_correction inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("power_factor_correction expected_result must match the source-ordered correction formula")
    elif algorithm == "carrier_concentration":
        valid = (len(values) == 3 and all(0 <= concentration <= 1_000_000 for concentration in values)
                 and values.count(0) == 1)
        source_result = -1e300
        if valid:
            electron_concentration, hole_concentration, intrinsic_concentration = values
            if electron_concentration == 0:
                source_result = intrinsic_concentration**2 / hole_concentration
            elif hole_concentration == 0:
                source_result = intrinsic_concentration**2 / electron_concentration
            else:
                source_result = (electron_concentration * hole_concentration) ** 0.5
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid carrier_concentration inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("carrier_concentration expected_result must match the source-selected missing field")
    elif algorithm == "casimir_effect":
        valid = (len(values) == 3 and all(0 <= value <= 1_000_000 for value in values)
                 and values.count(0) == 1)
        source_result = -1e300
        if valid:
            force = values[0] * 1e-12
            area = values[1] * 1e-6
            distance = values[2] * 1e-6
            reduced_planck_constant = 1.054571817e-34
            speed_of_light = 3e8
            pi = math.pi
            if force == 0:
                source_result = (reduced_planck_constant * speed_of_light * pi**2 * area) / (
                    240 * distance**4
                )
            elif area == 0:
                source_result = (240 * force * distance**4) / (
                    reduced_planck_constant * speed_of_light * pi**2
                )
            else:
                source_result = (
                    (reduced_planck_constant * speed_of_light * pi**2 * area) / (240 * force)
                ) ** (1 / 4)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid casimir_effect inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-30):
            raise ValueError("casimir_effect expected_result must match the source-ordered SI branch")
    elif algorithm == "bisection_2":
        valid = (len(values) == 2 and all(-100_000 <= value <= 100_000 for value in values))
        source_result = -1e300
        if valid:
            left_milli, right_milli = values
            a, b = left_milli / 1000.0, right_milli / 1000.0

            def source_function(x: float) -> float:
                return 10.0 - x * x

            valid = a < b and source_function(a) * source_function(b) < 0.0
            if valid:
                c = a
                while b - a >= 0.01:
                    c = (a + b) / 2.0
                    if source_function(c) == 0.0:
                        break
                    if source_function(c) * source_function(a) < 0.0:
                        b = c
                    else:
                        a = c
                source_result = c
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid bisection_2 inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("bisection_2 expected_result must match the source-ordered bisection loop")
    elif algorithm == "magnetic_flux":
        valid = (len(values) == 3 and 0 <= values[0] <= 10_000
                 and 0 <= values[1] <= 10_000
                 and values[2] in (0, 60, 90, 120, 180))
        source_result = -1e300
        if valid:
            magnetic_field, area, angle = values
            source_result = round(magnetic_field * area * math.cos(math.radians(angle)), 1)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid magnetic_flux inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("magnetic_flux expected_result must match the source-ordered rounded flux formula")
    elif algorithm == "coulombs_law":
        valid = (len(values) == 3
                 and all(-1_000_000 <= charge <= 1_000_000 and charge != 0
                         for charge in values[:2])
                 and 1 <= values[2] <= 1_000_000)
        source_result = -1e300
        if valid:
            charge1_coulombs = values[0] / 1_000_000.0
            charge2_coulombs = values[1] / 1_000_000.0
            distance_meters = values[2] / 1000.0
            source_result = (8.9875517923e9 * abs(charge1_coulombs * charge2_coulombs)
                             / (distance_meters * distance_meters))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid coulombs_law inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("coulombs_law expected_result must match the bounded SI force magnitude")
    elif algorithm == "lens_formulae":
        valid = (len(values) == 3 and values[0] in (0, 1, 2)
                 and all(value != 0 and -1_000_000 <= value <= 1_000_000 for value in values[1:]))
        source_result = -1e300
        if valid:
            operation, first, second = values
            if operation in (0, 1) and first == second:
                valid = False
            elif operation == 2 and first == -second:
                valid = False
            elif operation == 0:
                source_result = 1 / ((1 / second) - (1 / first))
            elif operation == 1:
                source_result = 1 / ((1 / second) - (1 / first))
            else:
                source_result = 1 / ((1 / second) + (1 / first))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid lens_formulae inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("lens_formulae expected_result must match the selected source-ordered reciprocal expression")
    elif algorithm == "circular_arc":
        valid = (len(values) == 3 and values[0] in (0, 1)
                 and -1_000_000 <= values[1] <= 1_000_000
                 and -360_000 <= values[2] <= 360_000)
        source_result = -1e300
        if valid:
            mode, radius, degrees = values
            angle = degrees * (math.pi / 180.0)
            source_result = (radius * angle if mode == 0
                             else (radius * radius * angle) / 2.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid circular_arc inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("circular_arc expected_result must match the selected source formula")
    elif algorithm == "sphere":
        valid = (len(values) == 2 and values[0] in (0, 1)
                 and 0 <= values[1] <= 1_000_000)
        source_result = -1e300
        if valid:
            mode, radius = values
            if mode == 0:
                source_result = math.pow(radius, 3) * math.pi * 4.0 / 3.0
            else:
                source_result = math.pow(radius, 2) * math.pi * 4.0
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid sphere inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("sphere expected_result must match the source-ordered volume or surface-area formula")
    elif algorithm == "relativistic_kinetic_energy":
        speed_of_light = 299_792_458.0
        valid = (len(values) == 2 and 0 <= values[0] <= 1_000_000
                 and -299_792_457 <= values[1] <= 299_792_457)
        source_result = -1e300
        if valid:
            mass, velocity = values
            gamma = 1.0 / math.sqrt(1.0 - velocity**2 / speed_of_light**2)
            source_result = (gamma - 1.0) * mass * speed_of_light**2
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid relativistic_kinetic_energy inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("relativistic_kinetic_energy expected_result must match the source-ordered Lorentz formula")
    elif algorithm == "relativistic_velocity_summation":
        speed_of_light = 299_792_458
        valid = (len(values) == 2
                 and -speed_of_light <= values[0] <= speed_of_light
                 and -(speed_of_light - 1) <= values[1] <= speed_of_light - 1)
        source_result = -1e300
        if valid:
            object_velocity, frame_velocity = values
            numerator = object_velocity + frame_velocity
            denominator = 1 + object_velocity * frame_velocity / speed_of_light**2
            source_result = numerator / denominator
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid relativistic_velocity_summation inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("relativistic_velocity_summation expected_result must match the source-ordered velocity formula")
    elif algorithm == "linear_regression_sequential_gradient_descent":
        valid = (len(values) >= 3 and 2 <= values[0] <= 64
                 and 1 <= values[1] <= 1000 and 1 <= values[2] <= 10_000
                 and len(values) == 3 + 2 * values[0])
        source_result = -1e300
        if valid:
            observation_count, rate_microunits, epochs = values[:3]
            observations = list(zip(values[3::2], values[4::2]))
            valid = (all(-10 <= x_value <= 10 for x_value, _ in observations)
                     and all(-100 <= y_value <= 100 for _, y_value in observations))
            if valid:
                alpha = rate_microunits / 1_000_000.0
                scale = alpha / observation_count
                slope = 0.0
                intercept = 0.0
                for _ in range(epochs):
                    slope_gradient = 0.0
                    for x_value, y_value in observations:
                        slope_gradient += (slope * x_value + intercept - y_value) * x_value
                    slope -= scale * slope_gradient
                    intercept_gradient = 0.0
                    for x_value, y_value in observations:
                        intercept_gradient += slope * x_value + intercept - y_value
                    intercept -= scale * intercept_gradient
                    squared_error = 0.0
                    for x_value, y_value in observations:
                        residual = slope * x_value + intercept - y_value
                        squared_error += residual * residual
                    source_result = squared_error / (2.0 * observation_count)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid linear_regression_sequential_gradient_descent inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("linear_regression_sequential_gradient_descent expected_result must match the source-ordered final training cost")
    elif algorithm == "linear_regression_stochastic_gradient_descent":
        valid = (len(values) >= 5 and 2 <= values[0] <= 64
                 and 1 <= values[1] <= 200 and 1 <= values[2] <= 10_000
                 and len(values) == 5 + 2 * values[0])
        source_result = -1e300
        if valid:
            observation_count, epochs, rate_microunits = values[:3]
            initial_slope, initial_intercept = values[3:5]
            observations_raw = list(zip(values[5::2], values[6::2]))
            valid = (-10_000_000 <= initial_slope <= 10_000_000
                     and -10_000_000 <= initial_intercept <= 10_000_000
                     and all(-10_000_000 <= x_value <= 10_000_000 for x_value, _ in observations_raw)
                     and all(-100_000_000 <= y_value <= 100_000_000 for _, y_value in observations_raw))
            if valid:
                scale = 1_000_000.0
                learning_rate = rate_microunits / scale
                slope = initial_slope / scale
                intercept = initial_intercept / scale
                observations = [(x_value / scale, y_value / scale)
                                for x_value, y_value in observations_raw]
                for _ in range(epochs):
                    for x_value, y_value in observations:
                        error = slope * x_value + intercept - y_value
                        slope -= learning_rate * error * x_value / observation_count
                        intercept -= learning_rate * error / observation_count
                source_result = slope
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid linear_regression_stochastic_gradient_descent inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-10):
            raise ValueError("linear_regression_stochastic_gradient_descent expected_result must match ordered per-row updates")
    elif algorithm == "black_scholes_option_price":
        valid = (len(values) == 6 and values[0] in (0, 1)
                 and 10 <= values[1] <= 1_000_000_000
                 and 10 <= values[2] <= 1_000_000_000
                 and 1 <= values[3] <= 100_000
                 and 1 <= values[4] <= 5_000
                 and -1_000 <= values[5] <= 1_000)
        source_result = -1e300
        if valid:
            option_kind, spot_milli, strike_milli, maturity_milli, volatility_milli, rate_milli = values
            spot = spot_milli / 1000.0
            strike = strike_milli / 1000.0
            maturity = maturity_milli / 1000.0
            volatility = volatility_milli / 1000.0
            rate = rate_milli / 1000.0
            sigma_sqrt_time = volatility * math.sqrt(maturity)
            d1 = (math.log(spot / strike) + (rate + volatility**2 / 2.0) * maturity) / sigma_sqrt_time
            d2 = d1 - sigma_sqrt_time
            discounted_strike = strike * math.exp(-rate * maturity)
            if option_kind == 0:
                normal_cdf_d1 = 0.5 * math.erfc(-d1 / math.sqrt(2.0))
                normal_cdf_d2 = 0.5 * math.erfc(-d2 / math.sqrt(2.0))
                source_result = spot * normal_cdf_d1 - discounted_strike * normal_cdf_d2
            else:
                normal_cdf_neg_d1 = 0.5 * math.erfc(d1 / math.sqrt(2.0))
                normal_cdf_neg_d2 = 0.5 * math.erfc(d2 / math.sqrt(2.0))
                source_result = discounted_strike * normal_cdf_neg_d2 - spot * normal_cdf_neg_d1
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid black_scholes_option_price inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("black_scholes_option_price expected_result must match the pinned European call/put formulas")
    elif algorithm == "reynolds_number":
        valid = (len(values) == 4
                 and 1 <= values[0] <= 1_000
                 and -1_000 <= values[1] <= 1_000
                 and 1 <= values[2] <= 1_000
                 and 1 <= values[3] <= 1_000)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid reynolds_number inputs must use the -1e300 result sentinel")
        else:
            density, velocity, diameter, viscosity = values
            source_result = (density * abs(velocity) * diameter) / viscosity
            if expected == -1e300 or not math.isclose(
                    expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
                raise ValueError("reynolds_number expected_result must match density * abs(velocity) * diameter / viscosity")
    elif algorithm == "rainfall_intensity":
        source_result = rainfall_intensity(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid rainfall_intensity inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("rainfall_intensity expected_result must match k * T**a / (D + b)**c")
    elif algorithm == "rotating_calipers":
        source_result = rotating_calipers(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid rotating_calipers inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("rotating_calipers expected_result must match the maximum pairwise Euclidean distance")
    elif algorithm == "grahams_law":
        source_result = grahams_law_result(values)
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid grahams_law inputs must use the -1e300 result sentinel")
        elif expected == -1e300 or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("grahams_law expected_result must match the selected pinned formula and six-decimal rounding")
    elif algorithm == "price_plus_tax":
        source_result = price_plus_tax_expected(values)
        if source_result == PRICE_PLUS_TAX_INVALID_RESULT:
            if expected != PRICE_PLUS_TAX_INVALID_RESULT:
                raise ValueError("invalid price_plus_tax inputs must use the -1e300 result sentinel")
        elif expected == PRICE_PLUS_TAX_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("price_plus_tax expected_result must match price * (1 + tax_rate)")
    elif algorithm == "macaulay_duration":
        source_result = macaulay_duration_expected(values)
        if source_result == MACAULAY_DURATION_INVALID_RESULT:
            if expected != MACAULAY_DURATION_INVALID_RESULT:
                raise ValueError("invalid macaulay_duration inputs must use the -1e300 result sentinel")
        elif expected == MACAULAY_DURATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("macaulay_duration expected_result must match the present-value weighted average annual cash-flow time")
    elif algorithm == "kelly_criterion":
        source_result = kelly_criterion_expected(values)
        if source_result == KELLY_CRITERION_INVALID_RESULT:
            if expected != KELLY_CRITERION_INVALID_RESULT:
                raise ValueError("invalid kelly_criterion inputs must use the -1e300 result sentinel")
        elif expected == KELLY_CRITERION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("kelly_criterion expected_result must match the source-ordered Kelly fraction")
    elif algorithm == "present_value":
        source_result = present_value_expected(values)
        if source_result == PRESENT_VALUE_INVALID_RESULT:
            if expected != PRESENT_VALUE_INVALID_RESULT:
                raise ValueError("invalid present_value inputs must use the -1e300 result sentinel")
        elif expected == PRESENT_VALUE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("present_value expected_result must match the source-ordered ties-to-even result")
    elif algorithm == "present_value_rust":
        source_result = present_value_rust_expected(values)
        if source_result == PRESENT_VALUE_RUST_INVALID_RESULT:
            if expected != PRESENT_VALUE_RUST_INVALID_RESULT:
                raise ValueError("invalid present_value_rust inputs must use the -1e300 result sentinel")
        elif expected == PRESENT_VALUE_RUST_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("present_value_rust expected_result must match the source-ordered ties-away result")
    elif algorithm == "resonant_frequency":
        source_result = resonant_frequency_expected(values)
        if source_result == RESONANT_FREQUENCY_INVALID_RESULT:
            if expected != RESONANT_FREQUENCY_INVALID_RESULT:
                raise ValueError("invalid resonant_frequency inputs must use the -1e300 result sentinel")
        elif expected == RESONANT_FREQUENCY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("resonant_frequency expected_result must match 1 / (2 * pi * sqrt(L * C))")
    elif algorithm == "rms_speed_of_molecule":
        source_result = rms_speed_of_molecule_expected(values)
        if source_result == RMS_SPEED_OF_MOLECULE_INVALID_RESULT:
            if expected != RMS_SPEED_OF_MOLECULE_INVALID_RESULT:
                raise ValueError("invalid rms_speed_of_molecule inputs must use the -1e300 result sentinel")
        elif expected == RMS_SPEED_OF_MOLECULE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("rms_speed_of_molecule expected_result must match the source-ordered RMS speed formula")
    elif algorithm == "newtons_second_law_of_motion":
        source_result = newtons_second_law_expected(values)
        if source_result == NEWTONS_SECOND_LAW_INVALID_RESULT:
            if expected != NEWTONS_SECOND_LAW_INVALID_RESULT:
                raise ValueError("invalid newtons_second_law_of_motion inputs must use the -1e300 result sentinel")
        elif expected == NEWTONS_SECOND_LAW_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("newtons_second_law_of_motion expected_result must match mass * acceleration")
    elif algorithm == "speed_of_sound":
        source_result = speed_of_sound_expected(values)
        if source_result == SPEED_OF_SOUND_INVALID_RESULT:
            if expected != SPEED_OF_SOUND_INVALID_RESULT:
                raise ValueError("invalid speed_of_sound inputs must use the -1e300 result sentinel")
        elif expected == SPEED_OF_SOUND_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("speed_of_sound expected_result must match (bulk_modulus / density) ** 0.5")
    elif algorithm == "terminal_velocity":
        source_result = terminal_velocity_expected(values)
        if source_result == TERMINAL_VELOCITY_INVALID_RESULT:
            if expected != TERMINAL_VELOCITY_INVALID_RESULT:
                raise ValueError("invalid terminal_velocity inputs must use the -1e300 result sentinel")
        elif expected == TERMINAL_VELOCITY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("terminal_velocity expected_result must match the source-ordered terminal-speed formula")
    elif algorithm == "newtons_law_of_gravitation":
        source_result = newtons_gravitation_expected(values)
        if source_result == NEWTONS_GRAVITATION_INVALID_RESULT:
            if expected != NEWTONS_GRAVITATION_INVALID_RESULT:
                raise ValueError("invalid newtons_law_of_gravitation inputs must use the -1e300 result sentinel")
        elif expected == NEWTONS_GRAVITATION_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("newtons_law_of_gravitation expected_result must match the selected gravitation formula")
    elif algorithm == "ideal_gas_law":
        source_result = ideal_gas_law_expected(values)
        if source_result == IDEAL_GAS_LAW_INVALID_RESULT:
            if expected != IDEAL_GAS_LAW_INVALID_RESULT:
                raise ValueError("invalid ideal_gas_law inputs must use the -1e300 result sentinel")
        elif expected == IDEAL_GAS_LAW_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("ideal_gas_law expected_result must match the selected source formula")
    elif algorithm == "poisson_dist":
        source_result = poisson_dist_expected(values)
        if source_result == POISSON_DIST_INVALID_RESULT:
            if expected != POISSON_DIST_INVALID_RESULT:
                raise ValueError("invalid poisson_dist inputs must use the -1e300 result sentinel")
        elif expected == POISSON_DIST_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=0.0):
            raise ValueError("poisson_dist expected_result must match the selected source helper")
    elif algorithm == "doppler_frequency":
        source_result = doppler_frequency_expected(values)
        if source_result == DOPPLER_FREQUENCY_INVALID_RESULT:
            if expected != DOPPLER_FREQUENCY_INVALID_RESULT:
                raise ValueError("invalid doppler_frequency inputs must use the -1e300 result sentinel")
        elif expected == DOPPLER_FREQUENCY_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("doppler_frequency expected_result must match the source-ordered Doppler formula")
    elif algorithm == "capacitor_equivalence":
        source_result = capacitor_equivalence_expected(values)
        if source_result == CAPACITOR_EQUIVALENCE_INVALID_RESULT:
            if expected != CAPACITOR_EQUIVALENCE_INVALID_RESULT:
                raise ValueError("invalid capacitor_equivalence inputs must use the -1e300 result sentinel")
        elif expected == CAPACITOR_EQUIVALENCE_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("capacitor_equivalence expected_result must match the selected equivalent-capacitance formula")
    elif algorithm == "secant_method":
        source_result = secant_method_expected(values)
        if source_result == SECANT_METHOD_INVALID_RESULT:
            if expected != SECANT_METHOD_INVALID_RESULT:
                raise ValueError("invalid secant_method inputs must use the -1e300 result sentinel")
        elif expected == SECANT_METHOD_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("secant_method expected_result must match the selected pinned variant")
    elif algorithm == "newton_raphson_method":
        source_result = newton_raphson_method_expected(values)
        if source_result == NEWTON_RAPHSON_METHOD_INVALID_RESULT:
            if expected != NEWTON_RAPHSON_METHOD_INVALID_RESULT:
                raise ValueError("invalid newton_raphson_method inputs must use the -1e300 result sentinel")
        elif expected == NEWTON_RAPHSON_METHOD_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-10):
            raise ValueError("newton_raphson_method expected_result must match the bounded cubic iteration")
    elif algorithm == "newton_raphson":
        source_result = newton_raphson_expected(values)
        if source_result == NEWTON_RAPHSON_INVALID_RESULT:
            if expected != NEWTON_RAPHSON_INVALID_RESULT:
                raise ValueError("invalid newton_raphson inputs must use the -1e300 result sentinel")
        elif expected == NEWTON_RAPHSON_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=0.0, abs_tol=1e-8):
            raise ValueError("newton_raphson expected_result must match the bounded positive root")
    elif algorithm == "pythagoras":
        source_result = pythagoras_expected(values)
        if source_result == PYTHAGORAS_INVALID_RESULT:
            if expected != PYTHAGORAS_INVALID_RESULT:
                raise ValueError("invalid pythagoras inputs must use the -1e300 result sentinel")
        elif expected == PYTHAGORAS_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("pythagoras expected_result must match the pinned 3D Euclidean distance")
    elif algorithm == "pow":
        source_result = pow_expected(values)
        if source_result == POW_INVALID_RESULT:
            if expected != POW_INVALID_RESULT:
                raise ValueError("invalid pow inputs must use the -1e300 result sentinel")
        elif expected == POW_INVALID_RESULT or not math.isclose(
                expected, source_result, rel_tol=1e-12, abs_tol=1e-12):
            raise ValueError("pow expected_result must match the pinned repeated-multiplication loop")
    return values, float(expected)


def resolve_tolerances(workload: dict) -> tuple[float, float]:
    """Resolve finite nonnegative tolerances from output/measurement metadata.

    Results match when abs(observed - expected) <= absolute + relative * abs(expected).
    Missing tolerances default to zero, preserving exact comparison.
    """
    resolved = []
    for key in ("absolute_tolerance", "relative_tolerance"):
        declared = []
        for section in ("output", "measurement"):
            metadata = workload.get(section, {})
            if not isinstance(metadata, dict):
                raise ValueError(f"{section} metadata must be an object")
            if key not in metadata:
                continue
            value = metadata[key]
            if (isinstance(value, bool) or not isinstance(value, (int, float))
                    or value < 0):
                raise ValueError(f"{section}.{key} must be a finite nonnegative number")
            try:
                numeric_value = float(value)
            except OverflowError as error:
                raise ValueError(f"{section}.{key} must be a finite nonnegative number") from error
            if not math.isfinite(numeric_value):
                raise ValueError(f"{section}.{key} must be a finite nonnegative number")
            declared.append(numeric_value)
        if len(declared) == 2 and declared[0] != declared[1]:
            raise ValueError(f"output.{key} and measurement.{key} must agree")
        resolved.append(declared[0] if declared else 0.0)
    return resolved[0], resolved[1]


def result_matches(observed: float, expected: float, absolute_tolerance: float,
                   relative_tolerance: float) -> bool:
    return (math.isfinite(observed)
            and abs(observed - expected)
            <= absolute_tolerance + relative_tolerance * abs(expected))


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
    if manifest.get("family") != "i64_array_float64":
        parser.error("build manifest must declare the i64_array_float64 ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_array_float64_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_array_float64_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_float64_call"):
        parser.error("workload does not match the built i64-array float64 algorithm")
    timing = workload["measurement"]
    absolute_tolerance, relative_tolerance = resolve_tolerances(workload)
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
        values, expected = encode_case(case, algorithm)
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        if len(values) > 1024:
            command = [str(executable), "--stdin", str(len(values)), repr(expected),
                       repr(absolute_tolerance), repr(relative_tolerance),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = " ".join(map(str, values)) + "\n"
        else:
            command = [str(executable), str(len(values)), *map(str, values), repr(expected),
                       repr(absolute_tolerance), repr(relative_tolerance),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = None
        completed = subprocess.run(command, input=streamed_values, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"array-float64 runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        if (not result_matches(observed, expected, absolute_tolerance, relative_tolerance)
                or len(raw["samples_ns"]) != samples):
            raise ValueError(f"array-float64 runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_array_float64_call",
                                        "absolute_tolerance": absolute_tolerance,
                                        "relative_tolerance": relative_tolerance,
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"], "observed_result": observed,
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
