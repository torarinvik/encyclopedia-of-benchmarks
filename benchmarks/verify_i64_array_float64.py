#!/usr/bin/env python3
"""Verify i64-array-to-float64 ports against bounded independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from hubble_parameter_oracle import INVALID_RESULT, expected_result as hubble_parameter_oracle
from light_aberration_oracle import INVALID_RESULT as LIGHT_ABERRATION_INVALID_RESULT
from light_aberration_oracle import expected_result as light_aberration_oracle
from run_i64_array_float64 import encode_case, resolve_tolerances, result_matches
from variance_oracle import INVALID_RESULT as VARIANCE_INVALID_RESULT
from variance_oracle import MAX_INPUT_LENGTH as MAX_VARIANCE_INPUT_LENGTH
from variance_oracle import MAX_VALUES as MAX_VARIANCE_VALUES
from variance_oracle import expected_result as variance_oracle
from dice_coefficient_oracle import INVALID_RESULT as DICE_COEFFICIENT_INVALID_RESULT
from dice_coefficient_oracle import MAX_INPUT_LENGTH as MAX_DICE_COEFFICIENT_INPUT_LENGTH
from dice_coefficient_oracle import MAX_STRING_LENGTH as MAX_DICE_COEFFICIENT_STRING_LENGTH
from dice_coefficient_oracle import expected_result as dice_coefficient_oracle
from density_oracle import INVALID_RESULT as DENSITY_INVALID_RESULT
from density_oracle import expected_result as density_oracle
from hinge_loss_oracle import INVALID_RESULT as HINGE_LOSS_INVALID_RESULT
from hinge_loss_oracle import MAX_COUNT as MAX_HINGE_LOSS_COUNT
from hinge_loss_oracle import MAX_INPUT_LENGTH as MAX_HINGE_LOSS_INPUT_LENGTH
from hinge_loss_oracle import PREDICTION_SCALE as HINGE_LOSS_PREDICTION_SCALE
from hinge_loss_oracle import expected_result as hinge_loss_oracle
from collaborative_filtering_oracle import MAX_NEIGHBORS as COLLABORATIVE_FILTERING_MAX_NEIGHBORS
from collaborative_filtering_oracle import MAX_PEARSON_INPUT_LENGTH as MAX_COLLABORATIVE_PEARSON_INPUT_LENGTH
from collaborative_filtering_oracle import MAX_PREDICTION_INPUT_LENGTH as MAX_COLLABORATIVE_PREDICTION_INPUT_LENGTH
from collaborative_filtering_oracle import MAX_PROFILE_ITEMS as COLLABORATIVE_FILTERING_MAX_PROFILE_ITEMS
from collaborative_filtering_oracle import MAX_ITEM_ID as COLLABORATIVE_FILTERING_MAX_ITEM_ID
from collaborative_filtering_oracle import MAX_RATING_MILLI as COLLABORATIVE_FILTERING_MAX_RATING_MILLI
from collaborative_filtering_oracle import SIMILARITY_SCALE as COLLABORATIVE_FILTERING_SIMILARITY_SCALE
from collaborative_filtering_oracle import PEARSON_INVALID_RESULT as COLLABORATIVE_PEARSON_INVALID_RESULT
from collaborative_filtering_oracle import PREDICTION_INVALID_RESULT as COLLABORATIVE_PREDICTION_INVALID_RESULT
from collaborative_filtering_oracle import expected_pearson_similarity as collaborative_filtering_pearson_oracle
from collaborative_filtering_oracle import expected_prediction as collaborative_filtering_oracle
from quadratic_equation_solver_oracle import INVALID_RESULT as QUADRATIC_EQUATION_SOLVER_INVALID_RESULT
from quadratic_equation_solver_oracle import MAX_COEFFICIENT as MAX_QUADRATIC_EQUATION_COEFFICIENT
from quadratic_equation_solver_oracle import expected_result as quadratic_equation_solver_oracle
from durand_kerner_roots_oracle import INVALID_RESULT as DURAND_KERNER_INVALID_RESULT
from durand_kerner_roots_oracle import expected_result as durand_kerner_oracle
from ground_to_ground_projectile_motion_oracle import INVALID_RESULT as GROUND_PROJECTILE_INVALID_RESULT
from ground_to_ground_projectile_motion_oracle import MAX_SPEED as MAX_GROUND_PROJECTILE_SPEED
from ground_to_ground_projectile_motion_oracle import MAX_ANGLE as MAX_GROUND_PROJECTILE_ANGLE
from ground_to_ground_projectile_motion_oracle import MIN_GRAVITY as MIN_GROUND_PROJECTILE_GRAVITY
from ground_to_ground_projectile_motion_oracle import MAX_GRAVITY as MAX_GROUND_PROJECTILE_GRAVITY
from ground_to_ground_projectile_motion_oracle import MAX_TIME as MAX_GROUND_PROJECTILE_TIME
from ground_to_ground_projectile_motion_oracle import expected_result as ground_projectile_oracle
from huber_loss_oracle import INVALID_RESULT as HUBER_LOSS_INVALID_RESULT
from huber_loss_oracle import MAX_DELTA as MAX_HUBER_LOSS_DELTA
from huber_loss_oracle import MAX_INPUT_LENGTH as MAX_HUBER_LOSS_INPUT_LENGTH
from huber_loss_oracle import MAX_PAIRS as MAX_HUBER_LOSS_PAIRS
from huber_loss_oracle import MAX_SAMPLE as MAX_HUBER_LOSS_SAMPLE
from huber_loss_oracle import expected_result as huber_loss_oracle
from huber_loss_math_oracle import INVALID_RESULT as HUBER_LOSS_MATH_INVALID_RESULT
from huber_loss_math_oracle import MAX_ARRAY_LENGTH as MAX_HUBER_LOSS_MATH_ARRAY_LENGTH
from huber_loss_math_oracle import MAX_DELTA as MAX_HUBER_LOSS_MATH_DELTA
from huber_loss_math_oracle import MAX_INPUT_LENGTH as MAX_HUBER_LOSS_MATH_INPUT_LENGTH
from huber_loss_math_oracle import MAX_SAMPLE as MAX_HUBER_LOSS_MATH_SAMPLE
from huber_loss_math_oracle import expected_result as huber_loss_math_oracle
from exponential_dist_oracle import INVALID_RESULT as EXPONENTIAL_DIST_INVALID_RESULT
from exponential_dist_oracle import MAX_INPUT_LENGTH as MAX_EXPONENTIAL_DIST_INPUT_LENGTH
from exponential_dist_oracle import MAX_RATE_MICRO as MAX_EXPONENTIAL_DIST_RATE_MICRO
from exponential_dist_oracle import expected_result as exponential_dist_oracle
from expected_shortfall_oracle import INVALID_RESULT as EXPECTED_SHORTFALL_INVALID_RESULT
from expected_shortfall_oracle import MAX_INPUT_LENGTH as MAX_EXPECTED_SHORTFALL_INPUT_LENGTH
from expected_shortfall_oracle import MAX_RETURNS as MAX_EXPECTED_SHORTFALL_RETURNS
from expected_shortfall_oracle import MAX_SAMPLE as MAX_EXPECTED_SHORTFALL_SAMPLE
from expected_shortfall_oracle import SCALE as EXPECTED_SHORTFALL_SCALE
from expected_shortfall_oracle import expected_result as expected_shortfall_oracle
from time_converter_oracle import INVALID_RESULT as TIME_CONVERTER_INVALID_RESULT
from time_converter_oracle import MAX_INPUT_LENGTH as MAX_TIME_CONVERTER_INPUT_LENGTH
from time_converter_oracle import MAX_TIME_MICRO as MAX_TIME_CONVERTER_TIME_MICRO
from time_converter_oracle import expected_result as time_converter_oracle
from temperature_converter_oracle import INVALID_RESULT as TEMPERATURE_CONVERTER_INVALID_RESULT
from temperature_converter_oracle import MAX_INPUT_LENGTH as MAX_TEMPERATURE_CONVERTER_INPUT_LENGTH
from temperature_converter_oracle import MAX_ABS_TEMPERATURE_MICRO as MAX_TEMPERATURE_CONVERTER_MICRO
from temperature_converter_oracle import expected_result as temperature_converter_oracle
from value_at_risk_oracle import INVALID_RESULT as VALUE_AT_RISK_INVALID_RESULT
from value_at_risk_oracle import MAX_INPUT_LENGTH as MAX_VALUE_AT_RISK_INPUT_LENGTH
from value_at_risk_oracle import MAX_RETURNS as MAX_VALUE_AT_RISK_RETURNS
from value_at_risk_oracle import MAX_SAMPLE as MAX_VALUE_AT_RISK_SAMPLE
from value_at_risk_oracle import SCALE as VALUE_AT_RISK_SCALE
from value_at_risk_oracle import expected_result as value_at_risk_oracle
from energy_oracle import INVALID_RESULT as ENERGY_INVALID_RESULT
from energy_oracle import MAX_INPUT_LENGTH as MAX_ENERGY_INPUT_LENGTH
from energy_oracle import MAX_UNIT_CODE as MAX_ENERGY_UNIT_CODE
from energy_oracle import MAX_VALUE_MICRO as MAX_ENERGY_VALUE_MICRO
from energy_oracle import expected_result as energy_oracle
from trapezoidal_integration_oracle import INVALID_RESULT as TRAPEZOIDAL_INTEGRATION_INVALID_RESULT
from trapezoidal_integration_oracle import MAX_ENDPOINT_MICRO as MAX_TRAPEZOIDAL_ENDPOINT_MICRO
from trapezoidal_integration_oracle import MAX_INPUT_LENGTH as MAX_TRAPEZOIDAL_INTEGRATION_INPUT_LENGTH
from trapezoidal_integration_oracle import MAX_STEPS as MAX_TRAPEZOIDAL_STEPS
from trapezoidal_integration_oracle import expected_result as trapezoidal_integration_oracle
from midpoint_integral_method_oracle import INVALID_RESULT as MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT
from midpoint_integral_method_oracle import MAX_INPUT_LENGTH as MAX_MIDPOINT_INTEGRAL_METHOD_INPUT_LENGTH
from midpoint_integral_method_oracle import expected_result as midpoint_integral_method_oracle
from weddles_rule_oracle import INVALID_RESULT as WEDDLES_RULE_INVALID_RESULT
from weddles_rule_oracle import MAX_INPUT_LENGTH as MAX_WEDDLES_RULE_INPUT_LENGTH
from weddles_rule_oracle import MAX_PANELS as WEDDLES_RULE_MAX_PANELS
from weddles_rule_oracle import MAX_STEP_NANOUNITS as WEDDLES_RULE_MAX_STEP_NANOUNITS
from weddles_rule_oracle import MAX_SAMPLE_MICRO as WEDDLES_RULE_MAX_SAMPLE_MICRO
from weddles_rule_oracle import expected_result as weddles_rule_oracle
from units_converter_oracle import INVALID_RESULT as UNITS_CONVERTER_INVALID_RESULT
from units_converter_oracle import MAX_EDGES as UNITS_CONVERTER_MAX_EDGES
from units_converter_oracle import MAX_INTERCEPT_MICRO as UNITS_CONVERTER_MAX_INTERCEPT_MICRO
from units_converter_oracle import MAX_INPUT_LENGTH as MAX_UNITS_CONVERTER_INPUT_LENGTH
from units_converter_oracle import MAX_SLOPE_PPM as UNITS_CONVERTER_MAX_SLOPE_PPM
from units_converter_oracle import MAX_UNITS as UNITS_CONVERTER_MAX_UNITS
from units_converter_oracle import MAX_VALUE_MICRO as UNITS_CONVERTER_MAX_VALUE_MICRO
from units_converter_oracle import expected_result as units_converter_oracle
from prefix_evaluation_oracle import INVALID_RESULT as PREFIX_EVALUATION_INVALID_RESULT
from prefix_evaluation_oracle import MAX_INPUT_LENGTH as MAX_PREFIX_EVALUATION_INPUT_LENGTH
from prefix_evaluation_oracle import MAX_TOKENS as PREFIX_EVALUATION_MAX_TOKENS
from prefix_evaluation_oracle import expected_result as prefix_evaluation_oracle
from ternary_search_min_max_recursive_oracle import INVALID_RESULT as TERNARY_SEARCH_MIN_MAX_INVALID_RESULT
from ternary_search_min_max_recursive_oracle import MAX_INPUT_LENGTH as MAX_TERNARY_SEARCH_MIN_MAX_INPUT_LENGTH
from ternary_search_min_max_recursive_oracle import expected_result as ternary_search_min_max_oracle
from cosine_similarity_oracle import INVALID_RESULT as COSINE_SIMILARITY_INVALID_RESULT
from cosine_similarity_oracle import MAX_INPUT_LENGTH as MAX_COSINE_SIMILARITY_INPUT_LENGTH
from cosine_similarity_oracle import MAX_STRING_LENGTH as MAX_COSINE_SIMILARITY_STRING_LENGTH
from cosine_similarity_oracle import MAX_PARSEABLE_STRING_LENGTH as MAX_COSINE_SIMILARITY_PARSEABLE_STRING_LENGTH
from cosine_similarity_oracle import MIN_PRINTABLE_ASCII as COSINE_SIMILARITY_MIN_ASCII
from cosine_similarity_oracle import MAX_PRINTABLE_ASCII as COSINE_SIMILARITY_MAX_ASCII
from cosine_similarity_oracle import expected_output as cosine_similarity_oracle
from linear_regression_cost_oracle import INVALID_RESULT as LINEAR_REGRESSION_COST_INVALID_RESULT
from linear_regression_cost_oracle import MAX_INPUT_LENGTH as MAX_LINEAR_REGRESSION_COST_INPUT_LENGTH
from linear_regression_cost_oracle import expected_result as linear_regression_cost_oracle
from price_plus_tax_oracle import INVALID_RESULT as PRICE_PLUS_TAX_INVALID_RESULT
from price_plus_tax_oracle import MAX_INPUT_LENGTH as MAX_PRICE_PLUS_TAX_INPUT_LENGTH
from price_plus_tax_oracle import MAX_PRICE_MICRO as MAX_PRICE_PLUS_TAX_PRICE_MICRO
from price_plus_tax_oracle import MAX_TAX_RATE_MICRO as MAX_PRICE_PLUS_TAX_TAX_RATE_MICRO
from price_plus_tax_oracle import expected_result as price_plus_tax_oracle
from macaulay_duration_oracle import INVALID_RESULT as MACAULAY_DURATION_INVALID_RESULT
from macaulay_duration_oracle import MAX_INPUT_LENGTH as MAX_MACAULAY_DURATION_INPUT_LENGTH
from macaulay_duration_oracle import MAX_FACE_VALUE_MICRO as MACAULAY_DURATION_MAX_FACE_MICRO
from macaulay_duration_oracle import MAX_RATE_MICRO as MACAULAY_DURATION_MAX_RATE_MICRO
from macaulay_duration_oracle import MAX_PERIODS as MACAULAY_DURATION_MAX_PERIODS
from macaulay_duration_oracle import expected_result as macaulay_duration_oracle
from kelly_criterion_oracle import INVALID_RESULT as KELLY_CRITERION_INVALID_RESULT
from kelly_criterion_oracle import MAX_INPUT_LENGTH as MAX_KELLY_CRITERION_INPUT_LENGTH
from kelly_criterion_oracle import MAX_PROBABILITY_MICRO as KELLY_CRITERION_MAX_PROBABILITY_MICRO
from kelly_criterion_oracle import MIN_PROBABILITY_MICRO as KELLY_CRITERION_MIN_PROBABILITY_MICRO
from kelly_criterion_oracle import MAX_RATIO_MICRO as KELLY_CRITERION_MAX_RATIO_MICRO
from kelly_criterion_oracle import MIN_RATIO_MICRO as KELLY_CRITERION_MIN_RATIO_MICRO
from kelly_criterion_oracle import expected_result as kelly_criterion_oracle
from present_value_oracle import INVALID_RESULT as PRESENT_VALUE_INVALID_RESULT
from present_value_oracle import MAX_FLOW_COUNT as PRESENT_VALUE_MAX_FLOW_COUNT
from present_value_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_PRESENT_VALUE_PARSEABLE_INPUT_LENGTH
from present_value_oracle import expected_result as present_value_oracle
from present_value_rust_oracle import INVALID_RESULT as PRESENT_VALUE_RUST_INVALID_RESULT
from present_value_rust_oracle import MAX_CASH_FLOWS as PRESENT_VALUE_RUST_MAX_FLOW_COUNT
from present_value_rust_oracle import MAX_INPUT_LENGTH as MAX_PRESENT_VALUE_RUST_PARSEABLE_INPUT_LENGTH
from present_value_rust_oracle import expected_result as present_value_rust_oracle
from resonant_frequency_oracle import INVALID_RESULT as RESONANT_FREQUENCY_INVALID_RESULT
from resonant_frequency_oracle import MAX_COMPONENT as RESONANT_FREQUENCY_MAX_COMPONENT
from resonant_frequency_oracle import MIN_COMPONENT as RESONANT_FREQUENCY_MIN_COMPONENT
from resonant_frequency_oracle import expected_result as resonant_frequency_oracle
from rms_speed_of_molecule_oracle import INVALID_RESULT as RMS_SPEED_OF_MOLECULE_INVALID_RESULT
from rms_speed_of_molecule_oracle import MAX_MOLAR_MASS as RMS_SPEED_MAX_MOLAR_MASS
from rms_speed_of_molecule_oracle import MAX_TEMPERATURE as RMS_SPEED_MAX_TEMPERATURE
from rms_speed_of_molecule_oracle import MIN_MOLAR_MASS as RMS_SPEED_MIN_MOLAR_MASS
from rms_speed_of_molecule_oracle import expected_result as rms_speed_of_molecule_oracle
from newtons_second_law_of_motion_oracle import INVALID_RESULT as NEWTONS_SECOND_LAW_INVALID_RESULT
from newtons_second_law_of_motion_oracle import MAX_INPUT_VALUE as NEWTONS_SECOND_LAW_MAX_VALUE
from newtons_second_law_of_motion_oracle import MIN_INPUT_VALUE as NEWTONS_SECOND_LAW_MIN_VALUE
from newtons_second_law_of_motion_oracle import expected_result as newtons_second_law_oracle
from speed_of_sound_oracle import INVALID_RESULT as SPEED_OF_SOUND_INVALID_RESULT
from speed_of_sound_oracle import MAX_BULK_MODULUS as SPEED_OF_SOUND_MAX_BULK_MODULUS
from speed_of_sound_oracle import MAX_DENSITY as SPEED_OF_SOUND_MAX_DENSITY
from speed_of_sound_oracle import MIN_BULK_MODULUS as SPEED_OF_SOUND_MIN_BULK_MODULUS
from speed_of_sound_oracle import MIN_DENSITY as SPEED_OF_SOUND_MIN_DENSITY
from speed_of_sound_oracle import expected_result as speed_of_sound_oracle
from terminal_velocity_oracle import INVALID_RESULT as TERMINAL_VELOCITY_INVALID_RESULT
from terminal_velocity_oracle import MAX_INPUT_VALUE as TERMINAL_VELOCITY_MAX_INPUT_VALUE
from terminal_velocity_oracle import MIN_INPUT_VALUE as TERMINAL_VELOCITY_MIN_INPUT_VALUE
from terminal_velocity_oracle import expected_result as terminal_velocity_oracle
from newtons_law_of_gravitation_oracle import INVALID_RESULT as NEWTONS_GRAVITATION_INVALID_RESULT
from newtons_law_of_gravitation_oracle import MAX_SUPPLIED_VALUE as NEWTONS_GRAVITATION_MAX_VALUE
from newtons_law_of_gravitation_oracle import MIN_SUPPLIED_VALUE as NEWTONS_GRAVITATION_MIN_VALUE
from newtons_law_of_gravitation_oracle import expected_result as newtons_gravitation_oracle
from ideal_gas_law_oracle import INVALID_RESULT as IDEAL_GAS_LAW_INVALID_RESULT
from ideal_gas_law_oracle import MAX_ARGUMENT as IDEAL_GAS_LAW_MAX_ARGUMENT
from ideal_gas_law_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_IDEAL_GAS_LAW_PARSEABLE_INPUT_LENGTH
from ideal_gas_law_oracle import MIN_ARGUMENT as IDEAL_GAS_LAW_MIN_ARGUMENT
from ideal_gas_law_oracle import expected_result as ideal_gas_law_oracle
from poisson_dist_oracle import INVALID_RESULT as POISSON_DIST_INVALID_RESULT
from poisson_dist_oracle import MAX_INPUT_LENGTH as MAX_POISSON_DIST_PARSEABLE_INPUT_LENGTH
from poisson_dist_oracle import MAX_MILLI_VALUE as POISSON_DIST_MAX_MILLI_VALUE
from poisson_dist_oracle import MAX_SUCCESS_COUNT as POISSON_DIST_MAX_SUCCESS_COUNT
from poisson_dist_oracle import expected_result as poisson_dist_oracle
from doppler_frequency_oracle import INVALID_RESULT as DOPPLER_FREQUENCY_INVALID_RESULT
from doppler_frequency_oracle import MAX_ORIGINAL_FREQUENCY as DOPPLER_FREQUENCY_MAX_ORIGINAL_FREQUENCY
from doppler_frequency_oracle import MAX_VELOCITY as DOPPLER_FREQUENCY_MAX_VELOCITY
from doppler_frequency_oracle import MAX_WAVE_SPEED as DOPPLER_FREQUENCY_MAX_WAVE_SPEED
from doppler_frequency_oracle import MIN_ORIGINAL_FREQUENCY as DOPPLER_FREQUENCY_MIN_ORIGINAL_FREQUENCY
from doppler_frequency_oracle import MIN_VELOCITY as DOPPLER_FREQUENCY_MIN_VELOCITY
from doppler_frequency_oracle import MIN_WAVE_SPEED as DOPPLER_FREQUENCY_MIN_WAVE_SPEED
from doppler_frequency_oracle import MAX_INPUT_LENGTH as MAX_DOPPLER_FREQUENCY_PARSEABLE_INPUT_LENGTH
from doppler_frequency_oracle import expected_result as doppler_frequency_oracle
from capacitor_equivalence_oracle import INVALID_RESULT as CAPACITOR_EQUIVALENCE_INVALID_RESULT
from capacitor_equivalence_oracle import MAX_CAPACITANCE as CAPACITOR_EQUIVALENCE_MAX_CAPACITANCE
from capacitor_equivalence_oracle import MAX_CAPACITOR_COUNT as CAPACITOR_EQUIVALENCE_MAX_COUNT
from capacitor_equivalence_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_CAPACITOR_EQUIVALENCE_PARSEABLE_INPUT_LENGTH
from capacitor_equivalence_oracle import MIN_CAPACITANCE as CAPACITOR_EQUIVALENCE_MIN_CAPACITANCE
from capacitor_equivalence_oracle import expected_result as capacitor_equivalence_oracle
from secant_method_oracle import INVALID_RESULT as SECANT_METHOD_INVALID_RESULT
from secant_method_oracle import MAX_INPUT_LENGTH as MAX_SECANT_METHOD_INPUT_LENGTH
from secant_method_oracle import expected_result as secant_method_oracle
from newton_raphson_method_oracle import INVALID_RESULT as NEWTON_RAPHSON_METHOD_INVALID_RESULT
from newton_raphson_method_oracle import MAX_INPUT_LENGTH as MAX_NEWTON_RAPHSON_METHOD_INPUT_LENGTH
from newton_raphson_method_oracle import expected_result as newton_raphson_method_oracle
from newton_raphson_oracle import INVALID_RESULT as NEWTON_RAPHSON_INVALID_RESULT
from newton_raphson_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_NEWTON_RAPHSON_PARSEABLE_INPUT_LENGTH
from newton_raphson_oracle import expected_result as newton_raphson_oracle
from reynolds_number_oracle import INVALID_RESULT as REYNOLDS_NUMBER_INVALID_RESULT
from reynolds_number_oracle import reynolds_number as reynolds_number_oracle
from interquartile_range_oracle import INVALID_RESULT as INTERQUARTILE_RANGE_INVALID_RESULT
from interquartile_range_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_INTERQUARTILE_RANGE_PARSEABLE_INPUT_LENGTH
from interquartile_range_oracle import expected_result as interquartile_range_oracle
from apparent_power_oracle import INVALID_RESULT as APPARENT_POWER_INVALID_RESULT
from apparent_power_oracle import expected_result as apparent_power_oracle
from archimedes_principle_of_buoyant_force_oracle import (
    INVALID_RESULT as ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT,
    expected_result as archimedes_principle_of_buoyant_force_oracle,
)
from automatic_differentiation_oracle import INVALID_RESULT as AUTOMATIC_DIFFERENTIATION_INVALID_RESULT
from automatic_differentiation_oracle import automatic_differentiation as automatic_differentiation_oracle
from boyles_law_oracle import INVALID_RESULT as BOYLES_LAW_INVALID_RESULT
from boyles_law_oracle import expected_result as boyles_law_oracle
from butterworth_filter_oracle import INVALID_RESULT as BUTTERWORTH_FILTER_INVALID_RESULT
from butterworth_filter_oracle import MAX_FREQUENCY as BUTTERWORTH_FILTER_MAX_FREQUENCY
from butterworth_filter_oracle import MAX_GAIN_MILLI_DB as BUTTERWORTH_FILTER_MAX_GAIN_MILLI_DB
from butterworth_filter_oracle import MAX_Q_MICRO as BUTTERWORTH_FILTER_MAX_Q_MICRO
from butterworth_filter_oracle import MAX_SAMPLE_RATE as BUTTERWORTH_FILTER_MAX_SAMPLE_RATE
from butterworth_filter_oracle import expected_result as butterworth_filter_oracle
from center_of_mass_oracle import INVALID_RESULT as CENTER_OF_MASS_INVALID_RESULT
from center_of_mass_oracle import MAX_COORDINATE_UNITS as CENTER_OF_MASS_MAX_COORDINATE_UNITS
from center_of_mass_oracle import MAX_INPUT_LENGTH as MAX_CENTER_OF_MASS_INPUT_LENGTH
from center_of_mass_oracle import MAX_MASS_UNITS as CENTER_OF_MASS_MAX_MASS_UNITS
from center_of_mass_oracle import MAX_PARTICLES as CENTER_OF_MASS_MAX_PARTICLES
from center_of_mass_oracle import expected_result as center_of_mass_oracle
from centripetal_force_oracle import INVALID_RESULT as CENTRIPETAL_FORCE_INVALID_RESULT
from centripetal_force_oracle import MAX_ABSOLUTE_VELOCITY as CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY
from centripetal_force_oracle import MAX_MASS as CENTRIPETAL_FORCE_MAX_MASS
from centripetal_force_oracle import MAX_RADIUS as CENTRIPETAL_FORCE_MAX_RADIUS
from centripetal_force_oracle import expected_result as centripetal_force_oracle
from cohen_sutherland_oracle import INVALID_RESULT as COHEN_SUTHERLAND_INVALID_RESULT
from cohen_sutherland_oracle import MAX_COORDINATE_MICRO as COHEN_SUTHERLAND_MAX_COORDINATE_MICRO
from cohen_sutherland_oracle import expected_result as cohen_sutherland_oracle
from laplacian_filter_oracle import INVALID_RESULT as LAPLACIAN_FILTER_INVALID_RESULT
from laplacian_filter_oracle import MAX_INPUT_LENGTH as MAX_LAPLACIAN_FILTER_INPUT_LENGTH
from laplacian_filter_oracle import expected_result as laplacian_filter_oracle
from line_sweep_oracle import INVALID_RESULT as LINE_SWEEP_INVALID_RESULT
from line_sweep_oracle import MAX_INPUT_LENGTH as MAX_LINE_SWEEP_INPUT_LENGTH
from line_sweep_oracle import expected_result as line_sweep_oracle
from lorentz_transformation_four_vector_oracle import INVALID_RESULT as LORENTZ_TRANSFORMATION_FOUR_VECTOR_INVALID_RESULT
from lorentz_transformation_four_vector_oracle import MAX_INPUT_LENGTH as MAX_LORENTZ_TRANSFORMATION_FOUR_VECTOR_INPUT_LENGTH
from lorentz_transformation_four_vector_oracle import expected_result as lorentz_transformation_four_vector_oracle
from peak_signal_to_noise_ratio_oracle import INVALID_RESULT as PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT
from peak_signal_to_noise_ratio_oracle import MAX_INPUT_LENGTH as MAX_PEAK_SIGNAL_TO_NOISE_RATIO_INPUT_LENGTH
from peak_signal_to_noise_ratio_oracle import MAX_ABSOLUTE_PIXEL_DIFFERENCE as PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE
from peak_signal_to_noise_ratio_oracle import MAX_PIXELS as PEAK_SIGNAL_TO_NOISE_RATIO_MAX_PIXELS
from peak_signal_to_noise_ratio_oracle import expected_result as peak_signal_to_noise_ratio_oracle
from reverse_polish_notation_oracle import INVALID_RESULT as REVERSE_POLISH_NOTATION_INVALID_RESULT
from reverse_polish_notation_oracle import MAX_INPUT_LENGTH as MAX_REVERSE_POLISH_NOTATION_INPUT_LENGTH
from reverse_polish_notation_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_REVERSE_POLISH_NOTATION_PARSEABLE_INPUT_LENGTH
from reverse_polish_notation_oracle import MAX_TOKEN_COUNT as REVERSE_POLISH_NOTATION_MAX_TOKEN_COUNT
from reverse_polish_notation_oracle import expected_result as reverse_polish_notation_oracle
from extended_kalman_filter_oracle import INVALID_RESULT as EXTENDED_KALMAN_FILTER_INVALID_RESULT
from extended_kalman_filter_oracle import MAX_INPUT_LENGTH as MAX_EXTENDED_KALMAN_FILTER_INPUT_LENGTH
from extended_kalman_filter_oracle import expected_result as extended_kalman_filter_oracle
from symmetric_derivative_oracle import INVALID_RESULT as SYMMETRIC_DERIVATIVE_INVALID_RESULT
from symmetric_derivative_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_SYMMETRIC_DERIVATIVE_PARSEABLE_INPUT_LENGTH
from symmetric_derivative_oracle import MAX_X_NANOUNITS as SYMMETRIC_DERIVATIVE_MAX_X_NANOUNITS
from symmetric_derivative_oracle import MIN_X_NANOUNITS as SYMMETRIC_DERIVATIVE_MIN_X_NANOUNITS
from symmetric_derivative_oracle import expected_result as symmetric_derivative_oracle
from fractional_differentiation_oracle import MAX_INPUT_LENGTH as MAX_FRACTIONAL_DIFFERENTIATION_INPUT_LENGTH
from fractional_differentiation_oracle import INVALID_RESULT as FRACTIONAL_DIFFERENTIATION_INVALID_RESULT
from fractional_differentiation_oracle import expected_result as fractional_differentiation_oracle
from finance_ratios_oracle import INVALID_RESULT as FINANCE_RATIOS_INVALID_RESULT
from finance_ratios_oracle import expected_result as finance_ratios_oracle
from gaussian_legendre_oracle import INVALID_RESULT as GAUSSIAN_LEGENDRE_INVALID_RESULT
from gaussian_legendre_oracle import expected_result as gaussian_legendre_oracle
from gradient_boosting_regressor_oracle import INVALID_RESULT as GRADIENT_BOOSTING_REGRESSOR_INVALID_RESULT
from gradient_boosting_regressor_oracle import MAX_INPUT_LENGTH as MAX_GRADIENT_BOOSTING_REGRESSOR_INPUT_LENGTH
from gradient_boosting_regressor_oracle import expected_result as gradient_boosting_regressor_oracle

ALGORITHMS = ("hubble_parameter", "light_aberration", "variance", "dice_coefficient", "density", "hinge_loss", "collaborative_filtering", "collaborative_filtering_pearson_similarity", "quadratic_equation_solver_complex_roots", "durand_kerner_roots", "linear_regression_cost", "price_plus_tax", "macaulay_duration", "kelly_criterion", "ground_to_ground_projectile_motion", "huber_loss", "huber_loss_math", "exponential_dist", "expected_shortfall", "time_converter", "temperature_converter", "value_at_risk", "energy", "trapezoidal_integration", "midpoint_integral_method", "weddles_rule", "ternary_search_min_max_recursive", "cosine_similarity", "present_value", "present_value_rust", "resonant_frequency", "rms_speed_of_molecule", "newtons_second_law_of_motion", "speed_of_sound", "terminal_velocity", "newtons_law_of_gravitation", "ideal_gas_law", "capacitor_equivalence", "poisson_dist", "doppler_frequency", "secant_method", "newton_raphson_method", "newton_raphson", "reynolds_number", "interquartile_range", "apparent_power", "archimedes_principle_of_buoyant_force", "automatic_differentiation", "boyles_law", "butterworth_filter", "center_of_mass", "centripetal_force", "cohen_sutherland")
ALGORITHMS += ("reverse_polish_notation",)
ALGORITHMS += ("units_converter",)
ALGORITHMS += ("prefix_evaluation",)
ALGORITHMS += ("peak_signal_to_noise_ratio",)
ALGORITHMS += ("laplacian_filter",)
ALGORITHMS += ("line_sweep", "lorentz_transformation_four_vector", "extended_kalman_filter")
ALGORITHMS += ("symmetric_derivative",)
ALGORITHMS += ("return_on_investment", "debt_to_equity", "gross_profit_margin", "earnings_per_sale")
ALGORITHMS += ("gaussian_legendre",)
ALGORITHMS += ("gradient_boosting_regressor",)
ALGORITHMS += ("fractional_differentiation",)
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_MIDPOINT_INTEGRAL_INTERVALS = 64
MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI = 10_000
MAX_TERNARY_ENDPOINT_MILLI = 100_000
MAX_TERNARY_PRECISION_MILLI = 8


def oracle(algorithm: str, values: list[int]) -> float:
    if algorithm in {"return_on_investment", "debt_to_equity", "gross_profit_margin", "earnings_per_sale"}:
        return finance_ratios_oracle(values, algorithm)
    elif algorithm == "extended_kalman_filter":
        return extended_kalman_filter_oracle(values)
    if algorithm == "symmetric_derivative":
        return symmetric_derivative_oracle(values)
    if algorithm == "fractional_differentiation":
        return fractional_differentiation_oracle(values)
    if algorithm == "gradient_boosting_regressor":
        return gradient_boosting_regressor_oracle(values)
    if algorithm == "gaussian_legendre":
        return gaussian_legendre_oracle(values)
    if algorithm == "hubble_parameter":
        return hubble_parameter_oracle(values)
    if algorithm == "light_aberration":
        return light_aberration_oracle(values)
    if algorithm == "variance":
        return variance_oracle(values)
    if algorithm == "dice_coefficient":
        return dice_coefficient_oracle(values)
    if algorithm == "density":
        return density_oracle(values)
    if algorithm == "hinge_loss":
        return hinge_loss_oracle(values)
    if algorithm == "collaborative_filtering":
        return collaborative_filtering_oracle(values)
    if algorithm == "collaborative_filtering_pearson_similarity":
        return collaborative_filtering_pearson_oracle(values)
    if algorithm == "quadratic_equation_solver_complex_roots":
        return quadratic_equation_solver_oracle(values)
    if algorithm == "durand_kerner_roots":
        return durand_kerner_oracle(values)
    if algorithm == "ground_to_ground_projectile_motion":
        return ground_projectile_oracle(values)
    if algorithm == "huber_loss":
        return huber_loss_oracle(values)
    if algorithm == "huber_loss_math":
        return huber_loss_math_oracle(values)
    if algorithm == "exponential_dist":
        return exponential_dist_oracle(values)
    if algorithm == "expected_shortfall":
        return expected_shortfall_oracle(values)
    if algorithm == "time_converter":
        return time_converter_oracle(values)
    if algorithm == "temperature_converter":
        return temperature_converter_oracle(values)
    if algorithm == "value_at_risk":
        return value_at_risk_oracle(values)
    if algorithm == "energy":
        return energy_oracle(values)
    if algorithm == "trapezoidal_integration":
        return trapezoidal_integration_oracle(values)
    if algorithm == "midpoint_integral_method":
        return midpoint_integral_method_oracle(values)
    if algorithm == "weddles_rule":
        return weddles_rule_oracle(values)
    if algorithm == "units_converter":
        return units_converter_oracle(values)
    if algorithm == "prefix_evaluation":
        return prefix_evaluation_oracle(values)
    if algorithm == "ternary_search_min_max_recursive":
        return ternary_search_min_max_oracle(values)
    if algorithm == "cosine_similarity":
        return cosine_similarity_oracle(values)
    if algorithm == "linear_regression_cost":
        return linear_regression_cost_oracle(values)
    if algorithm == "price_plus_tax":
        return price_plus_tax_oracle(values)
    if algorithm == "macaulay_duration":
        return macaulay_duration_oracle(values)
    if algorithm == "kelly_criterion":
        return kelly_criterion_oracle(values)
    if algorithm == "present_value":
        return present_value_oracle(values)
    if algorithm == "present_value_rust":
        return present_value_rust_oracle(values)
    if algorithm == "resonant_frequency":
        return resonant_frequency_oracle(values)
    if algorithm == "rms_speed_of_molecule":
        return rms_speed_of_molecule_oracle(values)
    if algorithm == "newtons_second_law_of_motion":
        return newtons_second_law_oracle(values)
    if algorithm == "speed_of_sound":
        return speed_of_sound_oracle(values)
    if algorithm == "terminal_velocity":
        return terminal_velocity_oracle(values)
    if algorithm == "newtons_law_of_gravitation":
        return newtons_gravitation_oracle(values)
    if algorithm == "ideal_gas_law":
        return ideal_gas_law_oracle(values)
    if algorithm == "capacitor_equivalence":
        return capacitor_equivalence_oracle(values)
    if algorithm == "poisson_dist":
        return poisson_dist_oracle(values)
    if algorithm == "doppler_frequency":
        return doppler_frequency_oracle(values)
    if algorithm == "secant_method":
        return secant_method_oracle(values)
    if algorithm == "newton_raphson_method":
        return newton_raphson_method_oracle(values)
    if algorithm == "newton_raphson":
        return newton_raphson_oracle(values)
    if algorithm == "reynolds_number":
        return reynolds_number_oracle(values)
    if algorithm == "interquartile_range":
        return interquartile_range_oracle(values)
    if algorithm == "apparent_power":
        return apparent_power_oracle(values)
    if algorithm == "archimedes_principle_of_buoyant_force":
        return archimedes_principle_of_buoyant_force_oracle(values)
    if algorithm == "automatic_differentiation":
        return automatic_differentiation_oracle(values)
    if algorithm == "boyles_law":
        return boyles_law_oracle(values)
    if algorithm == "butterworth_filter":
        return butterworth_filter_oracle(values)
    if algorithm == "center_of_mass":
        return center_of_mass_oracle(values)
    if algorithm == "centripetal_force":
        return centripetal_force_oracle(values)
    if algorithm == "cohen_sutherland":
        return cohen_sutherland_oracle(values)
    if algorithm == "laplacian_filter":
        return laplacian_filter_oracle(values)
    if algorithm == "line_sweep":
        return line_sweep_oracle(values)
    if algorithm == "lorentz_transformation_four_vector":
        return lorentz_transformation_four_vector_oracle(values)
    if algorithm == "peak_signal_to_noise_ratio":
        return peak_signal_to_noise_ratio_oracle(values)
    if algorithm == "reverse_polish_notation":
        return reverse_polish_notation_oracle(values)
    raise ValueError(f"no oracle for {algorithm}")


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    absolute_tolerance, relative_tolerance = resolve_tolerances(workload)
    if (not math.isfinite(absolute_tolerance) or absolute_tolerance < 0.0
            or not math.isfinite(relative_tolerance) or relative_tolerance < 0.0):
        raise ValueError("workload tolerances must be finite and nonnegative")

    cases: dict[tuple[int, ...], float] = {}
    for case in workload["cases"]:
        values, expected = encode_case(case, algorithm)
        source_result = oracle(algorithm, values)
        if not result_matches(expected, source_result, absolute_tolerance, relative_tolerance):
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
        cases[tuple(values)] = source_result

    if algorithm in {"return_on_investment", "debt_to_equity", "gross_profit_margin", "earnings_per_sale"}:
        rng = random.Random(20261016)
        for _ in range(256):
            if algorithm == "return_on_investment":
                values = (rng.randint(-1_000_000, 1_000_000), rng.randint(1, 1_000_000))
            elif algorithm == "debt_to_equity":
                values = (rng.randint(0, 1_000_000), rng.randint(1, 1_000_000))
            elif algorithm == "gross_profit_margin":
                values = (rng.randint(1, 1_000_000), rng.randint(0, 1_000_000))
            else:
                values = (rng.randint(-1_000_000, 1_000_000), rng.randint(0, 1_000_000),
                          rng.randint(1, 1_000_000))
            cases[values] = oracle(algorithm, list(values))
        malformed = {
            "return_on_investment": ((), (1,), (1, 0), (-1_000_001, 1), (1_000_001, 1), (0, 1_000_001), (I64_MIN, 1), (I64_MAX, 1)),
            "debt_to_equity": ((), (1,), (1, 0), (-1, 1), (1_000_001, 1), (0, 1_000_001), (I64_MIN, 1), (I64_MAX, 1)),
            "gross_profit_margin": ((), (1,), (0, 0), (0, 1), (1_000_001, 0), (1, 1_000_001), (I64_MIN, 1), (I64_MAX, 1)),
            "earnings_per_sale": ((), (1, 1), (1, 0, 0), (1, -1, 1), (-1_000_001, 0, 1), (1_000_001, 0, 1), (0, 0, 0), (0, 0, 1_000_001), (I64_MIN, 0, 1), (I64_MAX, 0, 1)),
        }[algorithm]
        for values in malformed:
            cases[values] = FINANCE_RATIOS_INVALID_RESULT
    elif algorithm == "extended_kalman_filter":
        # Keep traces small and deterministic while varying nonlinear state, covariance, noise, and observations.
        for values in ((1, 100, -200, 700, 20, 900, 5, 7, 120, 500),
                       (2, -800, 100, 2000, -100, 1500, 20, 25, 300, -1000, 800),
                       (8, 0, 0, 1000, 0, 1000, 1, 1, 100, *([500, -300, 200, 0, 900, -700, 100, 300]))):
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (0,), (9, 0, 0, 1000, 0, 1000, 10, 10, 100, *([0] * 9)),
                          (1, 3000, 0, 1000, 0, 1000, 0, 0, 100, 0),
                          (1, 0, 0, 100, 200, 100, 0, 0, 100, 0),
                          (1, 0, 0, 100, 0, 100, 0, 0, 0, 0)):
            cases[malformed] = EXTENDED_KALMAN_FILTER_INVALID_RESULT
    elif algorithm == "hubble_parameter":
        h0_values = (-2000, -1999, -683, -1, 0, 1, 683, 1999, 2000)
        density_cases = (
            (0, 0, 0), (1_000_000, 0, 0), (0, 1_000_000, 0),
            (0, 0, 1_000_000), (100, 300_000, 699_900),
            (333_333, 333_333, 333_334), (250_000, 250_000, 250_000),
        )
        redshifts = (0, 1, 999, 1_000, 9_999, 10_000)
        for h0 in h0_values:
            for densities in density_cases:
                for redshift in redshifts:
                    values = (h0, *densities, redshift)
                    cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(128):
            radiation = rng.randint(0, 1_000_000)
            matter = rng.randint(0, 1_000_000 - radiation)
            dark_energy = rng.randint(0, 1_000_000 - radiation - matter)
            values = (rng.randint(-2000, 2000), radiation, matter, dark_energy,
                      rng.randint(0, 10_000))
            cases[values] = oracle(algorithm, list(values))

        invalid_inputs = (
            (-2001, 0, 0, 0, 0), (2001, 0, 0, 0, 0),
            (0, -1, 0, 0, 0), (0, 1_000_001, 0, 0, 0),
            (0, 0, 600_000, 400_001, 0),
            (0, 0, 0, 0, -1), (0, 0, 0, 0, 10_001),
            (I64_MIN, 0, 0, 0, 0), (I64_MAX, 0, 0, 0, 0),
        )
        for values in invalid_inputs:
            cases[values] = INVALID_RESULT
        for values in ((683, 100, 300_000, 699_900),
                       (683, 100, 300_000, 699_900, 0, 0), ()):
            cases[values] = INVALID_RESULT
    elif algorithm == "light_aberration":
        theta_values = (-3_141_592, -3_141_591, -1_000_000, -1, 0, 1,
                        1_000_000, 3_141_591, 3_141_592)
        beta_values = (0, 1, 500_000, 999_000, 999_999)
        for theta in theta_values:
            for beta in beta_values:
                values = (theta, beta)
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            values = (rng.randint(-3_141_592, 3_141_592), rng.randint(0, 999_999))
            cases[values] = oracle(algorithm, list(values))
        for values in ((3_141_593, 0), (-3_141_593, 0), (0, -1), (0, 1_000_000), (), (0,)):
            cases[values] = LIGHT_ABERRATION_INVALID_RESULT
    elif algorithm == "variance":
        patterns = (lambda n: tuple(0 for _ in range(n)),
                    lambda n: tuple(range(n)),
                    lambda n: tuple((-1) ** index * 1_000_000 for index in range(n)))
        for length in (2, 3, 4, 16, MAX_VARIANCE_VALUES):
            for pattern in patterns:
                values = pattern(length)
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            length = rng.randint(2, MAX_VARIANCE_VALUES)
            values = tuple(rng.randint(-1_000_000, 1_000_000) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        for values in ((), (7,), tuple([0] * MAX_VARIANCE_INPUT_LENGTH),
                       (-1_000_001, 0), (0, 1_000_001), (I64_MIN, 0), (I64_MAX, 0)):
            cases[values] = VARIANCE_INVALID_RESULT
    elif algorithm == "dice_coefficient":
        rng = random.Random(20261016)
        for _ in range(256):
            length_a = rng.randint(0, MAX_DICE_COEFFICIENT_STRING_LENGTH)
            length_b = rng.randint(0, MAX_DICE_COEFFICIENT_STRING_LENGTH)
            string_a = tuple(rng.randint(32, 126) for _ in range(length_a))
            string_b = tuple(rng.randint(32, 126) for _ in range(length_b))
            values = (length_a, length_b, *string_a, *string_b)
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (0,), (-1, 0), (129, 0), (2, 2, 97, 98),
                          (1, 1, 31, 31), (1, 1, 127, 127),
                          tuple([0] * (MAX_DICE_COEFFICIENT_INPUT_LENGTH + 1))):
            cases[malformed] = DICE_COEFFICIENT_INVALID_RESULT
    elif algorithm == "density":
        for node_count in (2, 3, 4, 100_000):
            for directed in (0, 1):
                maximum = node_count * (node_count - 1)
                if directed == 0:
                    maximum //= 2
                for edge_count in (0, 1, maximum // 2, maximum):
                    values = (node_count, edge_count, directed)
                    cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            node_count = rng.randint(2, 100_000)
            directed = rng.randint(0, 1)
            maximum = node_count * (node_count - 1)
            if directed == 0:
                maximum //= 2
            values = (node_count, rng.randint(0, maximum), directed)
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (2,), (2, 0), (1, 0, 0), (100_001, 0, 0),
                          (4, -1, 0), (4, 7, 0), (4, 13, 1), (4, 0, 2),
                          (I64_MIN, 0, 0), (I64_MAX, 0, 1), (2, 0, 0, 0)):
            cases[malformed] = DENSITY_INVALID_RESULT
    elif algorithm == "hinge_loss":
        for count in (1, 2, 3, 16, MAX_HINGE_LOSS_COUNT):
            labels = tuple((-1, 1)[index % 2] for index in range(count))
            for score in (-HINGE_LOSS_PREDICTION_SCALE, 0, HINGE_LOSS_PREDICTION_SCALE):
                predictions = tuple(score for _ in range(count))
                values = (count, *labels, *predictions)
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(1, MAX_HINGE_LOSS_COUNT)
            labels = tuple(rng.choice((-1, 1)) for _ in range(count))
            predictions = tuple(rng.randint(-HINGE_LOSS_PREDICTION_SCALE,
                                             HINGE_LOSS_PREDICTION_SCALE)
                                for _ in range(count))
            values = (count, *labels, *predictions)
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (0,), (1, 1), (1, 0, 0), (1, 1, 1, 0),
                          (1, 1, HINGE_LOSS_PREDICTION_SCALE + 1),
                          (1, -1, -HINGE_LOSS_PREDICTION_SCALE - 1),
                          (MAX_HINGE_LOSS_COUNT + 1,),
                          tuple([1] + [1] * MAX_HINGE_LOSS_INPUT_LENGTH)):
            cases[malformed] = HINGE_LOSS_INVALID_RESULT
    elif algorithm == "collaborative_filtering":
        rng = random.Random(20261016)
        for neighbor_count in (0, 1, 2, 16, COLLABORATIVE_FILTERING_MAX_NEIGHBORS):
            user_count = neighbor_count + 1
            for target_index in {0, user_count - 1}:
                records = []
                for index in range(user_count):
                    records.extend((int(index == target_index), rng.randint(0, 1),
                                    rng.randint(-COLLABORATIVE_FILTERING_SIMILARITY_SCALE,
                                                COLLABORATIVE_FILTERING_SIMILARITY_SCALE),
                                    rng.randint(-COLLABORATIVE_FILTERING_MAX_RATING_MILLI,
                                                COLLABORATIVE_FILTERING_MAX_RATING_MILLI)))
                values = (user_count, *records)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            user_count = rng.randint(1, COLLABORATIVE_FILTERING_MAX_NEIGHBORS + 1)
            target_index = rng.randrange(user_count)
            records = []
            for index in range(user_count):
                records.extend((int(index == target_index), rng.randint(0, 1),
                                rng.randint(-COLLABORATIVE_FILTERING_SIMILARITY_SCALE,
                                            COLLABORATIVE_FILTERING_SIMILARITY_SCALE),
                                rng.randint(-COLLABORATIVE_FILTERING_MAX_RATING_MILLI,
                                            COLLABORATIVE_FILTERING_MAX_RATING_MILLI)))
            values = (user_count, *records)
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (0,), (1,), (1, 0, 1, 0, 0),
                          (2, 1, 0, 0, 0, 1, 0, 0, 0),
                          (1, 0, 0, 0, 0, 1, 0, 0, 0),
                          (1, 1, 1, COLLABORATIVE_FILTERING_SIMILARITY_SCALE + 1, 0),
                          (1, 1, 1, 0, COLLABORATIVE_FILTERING_MAX_RATING_MILLI + 1),
                          tuple([0] * (MAX_COLLABORATIVE_PREDICTION_INPUT_LENGTH + 1))):
            cases[malformed] = COLLABORATIVE_PREDICTION_INVALID_RESULT
    elif algorithm == "collaborative_filtering_pearson_similarity":
        rng = random.Random(20261016)
        for first_count, second_count in ((0, 0), (1, 1), (3, 3), (16, 16),
                                          (COLLABORATIVE_FILTERING_MAX_PROFILE_ITEMS,
                                           COLLABORATIVE_FILTERING_MAX_PROFILE_ITEMS)):
            first_ids = rng.sample(range(COLLABORATIVE_FILTERING_MAX_ITEM_ID + 1), first_count)
            second_ids = rng.sample(range(COLLABORATIVE_FILTERING_MAX_ITEM_ID + 1), second_count)
            first = tuple(value for item_id in first_ids
                          for value in (item_id, rng.randint(-COLLABORATIVE_FILTERING_MAX_RATING_MILLI,
                                                             COLLABORATIVE_FILTERING_MAX_RATING_MILLI)))
            second = tuple(value for item_id in second_ids
                           for value in (item_id, rng.randint(-COLLABORATIVE_FILTERING_MAX_RATING_MILLI,
                                                              COLLABORATIVE_FILTERING_MAX_RATING_MILLI)))
            values = (first_count, *first, second_count, *second)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            first_count = rng.randint(0, COLLABORATIVE_FILTERING_MAX_PROFILE_ITEMS)
            second_count = rng.randint(0, COLLABORATIVE_FILTERING_MAX_PROFILE_ITEMS)
            first_ids = rng.sample(range(COLLABORATIVE_FILTERING_MAX_ITEM_ID + 1), first_count)
            second_ids = rng.sample(range(COLLABORATIVE_FILTERING_MAX_ITEM_ID + 1), second_count)
            first = tuple(value for item_id in first_ids
                          for value in (item_id, rng.randint(-COLLABORATIVE_FILTERING_MAX_RATING_MILLI,
                                                             COLLABORATIVE_FILTERING_MAX_RATING_MILLI)))
            second = tuple(value for item_id in second_ids
                           for value in (item_id, rng.randint(-COLLABORATIVE_FILTERING_MAX_RATING_MILLI,
                                                              COLLABORATIVE_FILTERING_MAX_RATING_MILLI)))
            values = (first_count, *first, second_count, *second)
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (0,), (0, 0, 1), (1, 0, 1000, 1, 2000),
                          (1, 128, 1000, 0),
                          (1, 0, COLLABORATIVE_FILTERING_MAX_RATING_MILLI + 1, 0),
                          (2, 1, 1000, 2, 2000),
                          tuple([0] * (MAX_COLLABORATIVE_PEARSON_INPUT_LENGTH + 1))):
            cases[malformed] = COLLABORATIVE_PEARSON_INVALID_RESULT
    elif algorithm == "linear_regression_cost":
        rng = random.Random(20261016)
        for _ in range(256):
            observations = rng.randint(1, 16)
            features = rng.randint(1, 8)
            matrix = tuple(rng.randint(-1000, 1000)
                           for _ in range(observations * features))
            weights = tuple(rng.randint(-1000, 1000) for _ in range(features))
            targets = tuple(rng.randint(-1000, 1000) for _ in range(observations))
            values = (observations, features, *matrix, *weights, *targets)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (0, 1), (1, 0), (65, 1), (1, 17),
            (2, 2, 1, 2, 3, 4, 5, 6), (1, 1, 3, 4),
            (1, 1, 3, 4, 5, 6), (1, 1, 1001, 0, 0),
            (1, 1, 0, 1001, 0), (1, 1, 0, 0, -1001),
            (-(2**63), 1), (1, 1, 0, 2**63 - 1, 0),
            tuple([0] * (MAX_LINEAR_REGRESSION_COST_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            cases[values] = LINEAR_REGRESSION_COST_INVALID_RESULT
    elif algorithm == "quadratic_equation_solver_complex_roots":
        rng = random.Random(20261016)
        for _ in range(256):
            a = rng.randint(-MAX_QUADRATIC_EQUATION_COEFFICIENT,
                            MAX_QUADRATIC_EQUATION_COEFFICIENT)
            while a == 0:
                a = rng.randint(-MAX_QUADRATIC_EQUATION_COEFFICIENT,
                                MAX_QUADRATIC_EQUATION_COEFFICIENT)
            b = rng.randint(-MAX_QUADRATIC_EQUATION_COEFFICIENT,
                            MAX_QUADRATIC_EQUATION_COEFFICIENT)
            c = rng.randint(-MAX_QUADRATIC_EQUATION_COEFFICIENT,
                            MAX_QUADRATIC_EQUATION_COEFFICIENT)
            component = rng.randrange(4)
            values = (a, b, c, component)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 2), (1, 2, 3), (1, 2, 3, 0, 0),
            (0, 0, 0, 0), (1, 0, 0, -1), (1, 0, 0, 4),
            (MAX_QUADRATIC_EQUATION_COEFFICIENT + 1, 0, 0, 0),
            (1, -MAX_QUADRATIC_EQUATION_COEFFICIENT - 1, 0, 0),
            (1, 0, MAX_QUADRATIC_EQUATION_COEFFICIENT + 1, 0),
            (-(2**63), 0, 0, 0), (1, 2**63 - 1, 0, 0),
        )
        for values in malformed:
            cases[values] = QUADRATIC_EQUATION_SOLVER_INVALID_RESULT
    elif algorithm == "durand_kerner_roots":
        for d in range(-4, 5):
            for root_index in range(3):
                for component in range(2):
                    values = (d, root_index, component)
                    cases[values] = oracle(algorithm, list(values))
        for values in ((), (1,), (1, 0), (1, 0, 0, 0),
                       (0, 0, 0), (-5, 0, 0), (5, 0, 0),
                       (1, -1, 0), (1, 3, 0), (1, 0, -1), (1, 0, 2),
                       (I64_MIN, 0, 0), (I64_MAX, 0, 0)):
            cases[values] = DURAND_KERNER_INVALID_RESULT
    elif algorithm == "ground_to_ground_projectile_motion":
        rng = random.Random(20261016)
        for _ in range(256):
            operation = rng.randrange(3)
            speed = rng.randint(0, MAX_GROUND_PROJECTILE_SPEED)
            angle = rng.randint(-MAX_GROUND_PROJECTILE_ANGLE,
                                MAX_GROUND_PROJECTILE_ANGLE)
            auxiliary = (rng.randint(0, MAX_GROUND_PROJECTILE_TIME)
                         if operation == 1 else
                         rng.randint(MIN_GROUND_PROJECTILE_GRAVITY,
                                     MAX_GROUND_PROJECTILE_GRAVITY))
            values = (operation, speed, angle, auxiliary)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 1), (0, 1, 2), (0, 0, 0, 0, 0),
            (-1, 100_000_000, 0, 9_806_650),
            (3, 100_000_000, 0, 9_806_650),
            (0, -1, 0, 9_806_650),
            (0, MAX_GROUND_PROJECTILE_SPEED + 1, 0, 9_806_650),
            (0, 100_000_000, MAX_GROUND_PROJECTILE_ANGLE + 1, 9_806_650),
            (0, 100_000_000, 0, MIN_GROUND_PROJECTILE_GRAVITY - 1),
            (2, 100_000_000, 0, MAX_GROUND_PROJECTILE_GRAVITY + 1),
            (1, 100_000_000, 0, -1),
            (1, 100_000_000, 0, MAX_GROUND_PROJECTILE_TIME + 1),
            (I64_MIN, 0, 0, 0), (I64_MAX, 0, 0, 0),
        )
        for values in malformed:
            cases[values] = GROUND_PROJECTILE_INVALID_RESULT
    elif algorithm == "huber_loss":
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(1, MAX_HUBER_LOSS_PAIRS)
            delta = rng.randint(0, MAX_HUBER_LOSS_DELTA)
            true_values = tuple(rng.randint(-MAX_HUBER_LOSS_SAMPLE,
                                            MAX_HUBER_LOSS_SAMPLE)
                                for _ in range(count))
            predicted_values = tuple(rng.randint(-MAX_HUBER_LOSS_SAMPLE,
                                                 MAX_HUBER_LOSS_SAMPLE)
                                     for _ in range(count))
            values = (delta, count, count, *true_values, *predicted_values)
            cases[values] = oracle(algorithm, list(values))
        over_bound = (MAX_HUBER_LOSS_DELTA, MAX_HUBER_LOSS_PAIRS + 1,
                      MAX_HUBER_LOSS_PAIRS + 1,
                      *([0] * (2 * (MAX_HUBER_LOSS_PAIRS + 1))))
        malformed = (
            (), (0,), (0, 1), (0, 1, 1), (0, 1, 1, 0),
            (0, 0, 0), (0, 0, 1, 0), (0, 1, 0),
            (MAX_HUBER_LOSS_DELTA + 1, 1, 1, 0, 0),
            (1, 1, 1, MAX_HUBER_LOSS_SAMPLE + 1, 0),
            (1, 1, 1, 0, -MAX_HUBER_LOSS_SAMPLE - 1),
            (0, MAX_HUBER_LOSS_PAIRS + 1, MAX_HUBER_LOSS_PAIRS + 1),
            (0, MAX_HUBER_LOSS_PAIRS, MAX_HUBER_LOSS_PAIRS, 0),
            (0, 1, 1, 0, 0, 0),
            (-(2**63), 1, 1, 0, 0),
            (0, 1, 1, 0, 2**63 - 1),
            tuple([0] * (MAX_HUBER_LOSS_INPUT_LENGTH + 1)),
            over_bound,
        )
        for values in malformed:
            if len(values) <= MAX_HUBER_LOSS_INPUT_LENGTH:
                cases[values] = HUBER_LOSS_INVALID_RESULT
    elif algorithm == "huber_loss_math":
        rng = random.Random(20261017)
        for actual_count in range(MAX_HUBER_LOSS_MATH_ARRAY_LENGTH + 1):
            predicted_count = MAX_HUBER_LOSS_MATH_ARRAY_LENGTH - actual_count
            actual = tuple((index - actual_count // 2) * 1_000_000
                           for index in range(actual_count))
            predicted = tuple((index - predicted_count // 2) * 500_000
                              for index in range(predicted_count))
            values = (MAX_HUBER_LOSS_MATH_DELTA, actual_count, predicted_count,
                      *actual, *predicted)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            actual_count = rng.randint(0, MAX_HUBER_LOSS_MATH_ARRAY_LENGTH)
            predicted_count = rng.randint(0, MAX_HUBER_LOSS_MATH_ARRAY_LENGTH)
            delta = rng.randint(0, MAX_HUBER_LOSS_MATH_DELTA)
            actual = tuple(rng.randint(-MAX_HUBER_LOSS_MATH_SAMPLE,
                                       MAX_HUBER_LOSS_MATH_SAMPLE)
                           for _ in range(actual_count))
            predicted = tuple(rng.randint(-MAX_HUBER_LOSS_MATH_SAMPLE,
                                          MAX_HUBER_LOSS_MATH_SAMPLE)
                              for _ in range(predicted_count))
            values = (delta, actual_count, predicted_count, *actual, *predicted)
            cases[values] = oracle(algorithm, list(values))
        over_bound = (MAX_HUBER_LOSS_MATH_DELTA,
                      MAX_HUBER_LOSS_MATH_ARRAY_LENGTH + 1,
                      MAX_HUBER_LOSS_MATH_ARRAY_LENGTH + 1,
                      *([0] * (2 * (MAX_HUBER_LOSS_MATH_ARRAY_LENGTH + 1))))
        malformed = (
            (), (0,), (0, 0), (0, 1, 1), (0, 1, 1, 0),
            (-1, 0, 0), (MAX_HUBER_LOSS_MATH_DELTA + 1, 0, 0),
            (0, -1, 0), (0, 0, -1),
            (0, 1, 0, MAX_HUBER_LOSS_MATH_SAMPLE + 1),
            (0, 0, 1, -MAX_HUBER_LOSS_MATH_SAMPLE - 1),
            (0, 1, 1, 0, 0, 0), over_bound,
            tuple([0] * (MAX_HUBER_LOSS_MATH_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_HUBER_LOSS_MATH_INPUT_LENGTH:
                cases[values] = HUBER_LOSS_MATH_INVALID_RESULT
    elif algorithm == "exponential_dist":
        rng = random.Random(20261017)
        for _ in range(256):
            values = (rng.randrange(3), rng.randint(1, MAX_EXPONENTIAL_DIST_RATE_MICRO))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (0, -1), (3, 1), (-1, 1),
            (0, MAX_EXPONENTIAL_DIST_RATE_MICRO + 1),
            (0, 1, 17), (I64_MIN, 1), (I64_MAX, 1),
            tuple([0] * (MAX_EXPONENTIAL_DIST_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_EXPONENTIAL_DIST_INPUT_LENGTH:
                cases[values] = EXPONENTIAL_DIST_INVALID_RESULT
    elif algorithm == "expected_shortfall":
        rng = random.Random(20261018)
        for count in range(1, MAX_EXPECTED_SHORTFALL_RETURNS + 1):
            values = (rng.randint(1, EXPECTED_SHORTFALL_SCALE - 1), count,
                      *(rng.randint(-MAX_EXPECTED_SHORTFALL_SAMPLE,
                                    MAX_EXPECTED_SHORTFALL_SAMPLE)
                        for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(1, MAX_EXPECTED_SHORTFALL_RETURNS)
            values = (rng.randint(1, EXPECTED_SHORTFALL_SCALE - 1), count,
                      *(rng.randint(-MAX_EXPECTED_SHORTFALL_SAMPLE,
                                    MAX_EXPECTED_SHORTFALL_SAMPLE)
                        for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (0, 1), (0, 1, 1),
            (-1, 1, 0), (EXPECTED_SHORTFALL_SCALE, 1, 0),
            (1, 0), (1, -1), (1, 2, 0), (1, 1, 0, 0),
            (1, MAX_EXPECTED_SHORTFALL_RETURNS + 1,
             *([0] * (MAX_EXPECTED_SHORTFALL_RETURNS + 1))),
            (1, 1, MAX_EXPECTED_SHORTFALL_SAMPLE + 1),
            (1, 1, -MAX_EXPECTED_SHORTFALL_SAMPLE - 1),
            tuple([0] * (MAX_EXPECTED_SHORTFALL_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_EXPECTED_SHORTFALL_INPUT_LENGTH:
                cases[values] = EXPECTED_SHORTFALL_INVALID_RESULT
    elif algorithm == "time_converter":
        rng = random.Random(20261019)
        time_values = (0, 1, 500_000, 123_456_789, MAX_TIME_CONVERTER_TIME_MICRO)
        for time_micro in time_values:
            for from_unit in range(7):
                for to_unit in range(7):
                    values = (time_micro, from_unit, to_unit)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            values = (rng.randint(0, MAX_TIME_CONVERTER_TIME_MICRO),
                      rng.randrange(7), rng.randrange(7))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (-1, 0, 0),
            (MAX_TIME_CONVERTER_TIME_MICRO + 1, 0, 0),
            (0, -1, 0), (0, 7, 0), (0, 0, -1), (0, 0, 7),
            (0, 0, 0, 99), (I64_MIN, 0, 0), (I64_MAX, 0, 0),
            tuple([0] * (MAX_TIME_CONVERTER_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_TIME_CONVERTER_INPUT_LENGTH:
                cases[values] = TIME_CONVERTER_INVALID_RESULT
    elif algorithm == "temperature_converter":
        rng = random.Random(20261021)
        boundary_values = (-MAX_TEMPERATURE_CONVERTER_MICRO, -273_150_000, -40_000_000,
                           0, 36_600_000, 100_000_000, MAX_TEMPERATURE_CONVERTER_MICRO)
        for operation in range(6):
            for temperature_micro in boundary_values:
                values = (operation, temperature_micro)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            values = (rng.randrange(6), rng.randint(-MAX_TEMPERATURE_CONVERTER_MICRO,
                                                   MAX_TEMPERATURE_CONVERTER_MICRO))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0, 0), (-1, 0), (6, 0), (0, -MAX_TEMPERATURE_CONVERTER_MICRO - 1),
            (0, MAX_TEMPERATURE_CONVERTER_MICRO + 1), (I64_MIN, 0), (0, I64_MIN), (0, I64_MAX),
            tuple([0] * MAX_TEMPERATURE_CONVERTER_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = TEMPERATURE_CONVERTER_INVALID_RESULT
    elif algorithm == "value_at_risk":
        rng = random.Random(20261020)
        for count in range(1, MAX_VALUE_AT_RISK_RETURNS + 1):
            values = (rng.randint(1, VALUE_AT_RISK_SCALE - 1), count,
                      *(rng.randint(-MAX_VALUE_AT_RISK_SAMPLE,
                                    MAX_VALUE_AT_RISK_SAMPLE)
                        for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(1, MAX_VALUE_AT_RISK_RETURNS)
            values = (rng.randint(1, VALUE_AT_RISK_SCALE - 1), count,
                      *(rng.randint(-MAX_VALUE_AT_RISK_SAMPLE,
                                    MAX_VALUE_AT_RISK_SAMPLE)
                        for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (0, 1), (0, 1, 1),
            (-1, 1, 0), (VALUE_AT_RISK_SCALE, 1, 0),
            (1, 0), (1, -1), (1, 2, 0), (1, 1, 0, 0),
            (1, MAX_VALUE_AT_RISK_RETURNS + 1,
             *([0] * (MAX_VALUE_AT_RISK_RETURNS + 1))),
            (1, 1, MAX_VALUE_AT_RISK_SAMPLE + 1),
            (1, 1, -MAX_VALUE_AT_RISK_SAMPLE - 1),
            tuple([0] * (MAX_VALUE_AT_RISK_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_VALUE_AT_RISK_INPUT_LENGTH:
                cases[values] = VALUE_AT_RISK_INVALID_RESULT
    elif algorithm == "energy":
        rng = random.Random(20261021)
        for unit in range(MAX_ENERGY_UNIT_CODE + 1):
            for value_micro in (1_000_000, -1_000_000, 1, -1,
                                MAX_ENERGY_VALUE_MICRO, -MAX_ENERGY_VALUE_MICRO):
                cases[(value_micro, unit, 0)] = oracle(algorithm, [value_micro, unit, 0])
                cases[(value_micro, 0, unit)] = oracle(algorithm, [value_micro, 0, unit])
            cases[(42_000_000, unit, unit)] = oracle(algorithm, [42_000_000, unit, unit])
        for _ in range(256):
            values = (rng.randint(-MAX_ENERGY_VALUE_MICRO, MAX_ENERGY_VALUE_MICRO),
                      rng.randrange(MAX_ENERGY_UNIT_CODE + 1),
                      rng.randrange(MAX_ENERGY_UNIT_CODE + 1))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (0, 0, 0, 99),
            (MAX_ENERGY_VALUE_MICRO + 1, 0, 0),
            (-MAX_ENERGY_VALUE_MICRO - 1, 0, 0),
            (0, -1, 0), (0, MAX_ENERGY_UNIT_CODE + 1, 0),
            (0, 0, -1), (0, 0, MAX_ENERGY_UNIT_CODE + 1),
            (I64_MIN, 0, 0), (I64_MAX, 0, 0),
            tuple([0] * (MAX_ENERGY_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_ENERGY_INPUT_LENGTH:
                cases[values] = ENERGY_INVALID_RESULT
    elif algorithm == "trapezoidal_integration":
        rng = random.Random(20261022)
        for function_id in (0, 1):
            for start, end in ((0, MAX_TRAPEZOIDAL_ENDPOINT_MICRO),
                               (-MAX_TRAPEZOIDAL_ENDPOINT_MICRO, 0),
                               (-MAX_TRAPEZOIDAL_ENDPOINT_MICRO, MAX_TRAPEZOIDAL_ENDPOINT_MICRO),
                               (MAX_TRAPEZOIDAL_ENDPOINT_MICRO, -MAX_TRAPEZOIDAL_ENDPOINT_MICRO),
                               (123_456, 123_456)):
                for steps in (1, 2, MAX_TRAPEZOIDAL_STEPS):
                    values = (start, end, steps, function_id)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            values = (rng.randint(-MAX_TRAPEZOIDAL_ENDPOINT_MICRO,
                                  MAX_TRAPEZOIDAL_ENDPOINT_MICRO),
                      rng.randint(-MAX_TRAPEZOIDAL_ENDPOINT_MICRO,
                                  MAX_TRAPEZOIDAL_ENDPOINT_MICRO),
                      rng.randint(1, MAX_TRAPEZOIDAL_STEPS), rng.randrange(2))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (0, 0, 1),
            (0, 100_000, 1, 0, 7), (0, 100_000, 0, 0),
            (0, 100_000, -1, 1), (0, 100_000, MAX_TRAPEZOIDAL_STEPS + 1, 1),
            (0, 100_000, 1, -1), (0, 100_000, 1, 2),
            (MAX_TRAPEZOIDAL_ENDPOINT_MICRO + 1, 0, 1, 1),
            (0, -MAX_TRAPEZOIDAL_ENDPOINT_MICRO - 1, 1, 0),
            (I64_MIN, 0, 1, 0), (0, I64_MAX, 1, 1),
            tuple([0] * (MAX_TRAPEZOIDAL_INTEGRATION_INPUT_LENGTH + 1)),
        )
        for values in malformed:
            if len(values) <= MAX_TRAPEZOIDAL_INTEGRATION_INPUT_LENGTH:
                cases[values] = TRAPEZOIDAL_INTEGRATION_INVALID_RESULT
    elif algorithm == "midpoint_integral_method":
        rng = random.Random(20261016)
        interval_counts = (2, 4, 16, MAX_MIDPOINT_INTEGRAL_INTERVALS)
        endpoint_pairs = ((0, 1), (0, 1_000), (1_000, 3_000),
                          (0, MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI),
                          (MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI - 1,
                           MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI))
        for function_id in range(4):
            for intervals in interval_counts:
                for a_milli, b_milli in endpoint_pairs:
                    values = (function_id, intervals, a_milli, b_milli)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(128):
            a_milli = rng.randrange(MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI)
            b_milli = rng.randint(a_milli + 1, MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI)
            values = (rng.randrange(4), rng.choice(range(2, MAX_MIDPOINT_INTEGRAL_INTERVALS + 1, 2)),
                      a_milli, b_milli)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 16, 1_000), (0, 16, 1_000, 3_000, 0),
            (-1, 16, 1_000, 3_000), (4, 16, 1_000, 3_000),
            (0, 0, 1_000, 3_000), (0, 1, 1_000, 3_000),
            (0, MAX_MIDPOINT_INTEGRAL_INTERVALS + 2, 1_000, 3_000),
            (0, 16, -1, 1_000),
            (0, 16, 1_000, MAX_MIDPOINT_INTEGRAL_ENDPOINT_MILLI + 1),
            (0, 16, 3_000, 1_000), (0, 16, 1_000, 1_000),
            (I64_MIN, 16, 0, 1), (0, I64_MAX, 0, 1),
        )
        for values in malformed:
            if len(values) <= MAX_MIDPOINT_INTEGRAL_METHOD_INPUT_LENGTH:
                cases[values] = MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT
    elif algorithm == "weddles_rule":
        rng = random.Random(20261016)
        for panels in (1, 2, 3, 7, WEDDLES_RULE_MAX_PANELS):
            samples = [((index * 104_729) % (2 * WEDDLES_RULE_MAX_SAMPLE_MICRO + 1))
                       - WEDDLES_RULE_MAX_SAMPLE_MICRO
                       for index in range(6 * panels + 1)]
            for step_nanounits in (0, 1, -1, WEDDLES_RULE_MAX_STEP_NANOUNITS,
                                   -WEDDLES_RULE_MAX_STEP_NANOUNITS):
                values = (panels, step_nanounits, *samples)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            panels = rng.randint(1, WEDDLES_RULE_MAX_PANELS)
            values = (panels, rng.randint(-WEDDLES_RULE_MAX_STEP_NANOUNITS,
                                          WEDDLES_RULE_MAX_STEP_NANOUNITS),
                      *(rng.randint(-WEDDLES_RULE_MAX_SAMPLE_MICRO,
                                    WEDDLES_RULE_MAX_SAMPLE_MICRO)
                        for _ in range(6 * panels + 1)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (1,), (0, 0, *([0] * 7)),
            (WEDDLES_RULE_MAX_PANELS + 1, 0, *([0] * 7)),
            (1, 0, *([0] * 6)), (1, 0, *([0] * 8)),
            (1, WEDDLES_RULE_MAX_STEP_NANOUNITS + 1, *([0] * 7)),
            (1, -WEDDLES_RULE_MAX_STEP_NANOUNITS - 1, *([0] * 7)),
            (1, 0, WEDDLES_RULE_MAX_SAMPLE_MICRO + 1, *([0] * 6)),
            (1, 0, 0, WEDDLES_RULE_MAX_SAMPLE_MICRO + 1, *([0] * 5)),
            (1, 0, *([0] * 6), -WEDDLES_RULE_MAX_SAMPLE_MICRO - 1),
            (1, 0, *([0] * (MAX_WEDDLES_RULE_INPUT_LENGTH - 2))),
        )
        for values in malformed:
            if len(values) <= MAX_WEDDLES_RULE_INPUT_LENGTH:
                cases[values] = WEDDLES_RULE_INVALID_RESULT
    elif algorithm == "units_converter":
        for source in range(6):
            for target in range(6):
                if source == target:
                    continue
                for value_micro in (-UNITS_CONVERTER_MAX_VALUE_MICRO, 0,
                                    UNITS_CONVERTER_MAX_VALUE_MICRO):
                    values = (0, source, target, value_micro)
                    cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(128):
            unit_count = rng.randint(2, UNITS_CONVERTER_MAX_UNITS)
            edges = []
            for target in range(1, unit_count):
                source = rng.randrange(target)
                slope = rng.choice((-2_000_000, -1_500_000, -1_000_000, -500_000,
                                    500_000, 1_000_000, 1_500_000, 2_000_000))
                intercept = rng.randint(-100_000_000, 100_000_000)
                edges.extend((source, target, slope, intercept))
            source = rng.randrange(unit_count)
            target = rng.randrange(unit_count - 1)
            if target >= source:
                target += 1
            values = (1, unit_count, unit_count - 1, source, target,
                      rng.randint(-UNITS_CONVERTER_MAX_VALUE_MICRO,
                                  UNITS_CONVERTER_MAX_VALUE_MICRO), *edges)
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (0,), (2, 0, 0, 1), (0, 1, 1, 0), (0, -1, 2, 0),
            (0, 0, 6, 0), (0, 0, 1, UNITS_CONVERTER_MAX_VALUE_MICRO + 1),
            (1, 1, 0, 0, 0, 0),
            (1, UNITS_CONVERTER_MAX_UNITS + 1, 0, 0, 1, 0),
            (1, 2, UNITS_CONVERTER_MAX_EDGES + 1, 0, 1, 0),
            (1, 2, 1, 0, 1, 0, 0, 2, 1_000_000, 0),
            (1, 2, 1, 0, 1, 0, 0, 1, 1_000_000, 0),
            (1, 2, 1, 0, 1, 0, 0, 1, 0, 0),
            (1, 2, 1, 0, 1, 0, 0, 1, UNITS_CONVERTER_MAX_SLOPE_PPM + 1, 0),
            (1, 2, 1, 0, 1, 0, 0, 1, 1_000_000,
             UNITS_CONVERTER_MAX_INTERCEPT_MICRO + 1),
            (1, 3, 3, 0, 2, 0, 0, 1, 1_000_000, 0,
             1, 2, 1_000_000, 0, 2, 0, 1_000_000, 0),
            (I64_MIN,), (I64_MAX,), tuple([0] * MAX_UNITS_CONVERTER_INPUT_LENGTH),
        )
        for values in malformed:
            if len(values) <= MAX_UNITS_CONVERTER_INPUT_LENGTH:
                cases[values] = UNITS_CONVERTER_INVALID_RESULT
    elif algorithm == "prefix_evaluation":
        def encode_expression(expression: str) -> tuple[int, ...]:
            encoded = expression.encode("ascii")
            return (len(encoded), *encoded)

        for operator in "+-*/":
            for first in range(10):
                for second in range(10):
                    values = encode_expression(f"{operator} {first} {second}")
                    cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)

        def random_expression(depth: int) -> tuple[str, float]:
            if depth == 0 or rng.randrange(4) == 0:
                digit = rng.randrange(10)
                return str(digit), float(digit)
            operator = rng.choice("+-*/")
            left_text, left_value = random_expression(depth - 1)
            right_text, right_value = random_expression(depth - 1)
            if operator == "/" and right_value == 0.0:
                operator = rng.choice("+-*")
            if operator == "+":
                result = left_value + right_value
            elif operator == "-":
                result = left_value - right_value
            elif operator == "*":
                result = left_value * right_value
            else:
                result = left_value / right_value
            return f"{operator} {left_text} {right_text}", result

        for _ in range(256):
            expression, _expected = random_expression(4)
            values = encode_expression(expression)
            if len(values) <= MAX_PREFIX_EVALUATION_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))

        malformed_expressions = (
            b"", b"+ 1", b"1 2", b"+ 1 2 ", b" + 1 2", b"+  1 2",
            b"+\t1\t2", b"+ 10 2", b"/ 1 0", b"? 1 2",
            b"+ 1 -", b"+ 1 2 3", bytes([43, 32, 49, 32, 255]),
            b"1" * (MAX_PREFIX_EVALUATION_INPUT_LENGTH - 1),
        )
        malformed = [(len(expression), *expression) for expression in malformed_expressions]
        malformed.extend(((), (0,), (MAX_PREFIX_EVALUATION_INPUT_LENGTH + 1,)))
        for values in malformed:
            if len(values) <= MAX_PREFIX_EVALUATION_INPUT_LENGTH:
                cases[values] = PREFIX_EVALUATION_INVALID_RESULT
    elif algorithm == "ternary_search_min_max_recursive":
        rng = random.Random(20261016)
        interval_pairs = {}
        for mode, center in ((0, 1_000), (1, -1_000)):
            interval_pairs[mode] = (
                (-MAX_TERNARY_ENDPOINT_MILLI, MAX_TERNARY_ENDPOINT_MILLI),
                (center - 1, center + 1),
                (center - 1_000, center + 1_000),
                (-MAX_TERNARY_ENDPOINT_MILLI, center + 1),
                (center - 1, MAX_TERNARY_ENDPOINT_MILLI),
                (center - 8, center + 8),
            )
            for start_milli, end_milli in interval_pairs[mode]:
                for precision_milli in (1, MAX_TERNARY_PRECISION_MILLI):
                    values = (mode, start_milli, end_milli, precision_milli)
                    cases[values] = oracle(algorithm, list(values))
            for _ in range(64):
                start_milli = rng.randint(-MAX_TERNARY_ENDPOINT_MILLI, center - 1)
                end_milli = rng.randint(center + 1, MAX_TERNARY_ENDPOINT_MILLI)
                precision_milli = rng.randint(1, MAX_TERNARY_PRECISION_MILLI)
                values = (mode, start_milli, end_milli, precision_milli)
                cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, -100_000, 100_000), (0, -100_000, 100_000, 1, 0),
            (-1, -100_000, 100_000, 1), (2, -100_000, 100_000, 1),
            (0, 1_000, 2_000, 1), (0, -2_000, 1_000, 1),
            (1, -1_000, 2_000, 1), (1, -2_000, -1_000, 1),
            (0, -100_001, 2_000, 1), (1, -2_000, 100_001, 1),
            (0, -2_000, 2_000, 0), (1, -2_000, 2_000, MAX_TERNARY_PRECISION_MILLI + 1),
            (I64_MIN, -2_000, 2_000, 1), (1, -2_000, I64_MAX, 1),
            tuple([0] * MAX_TERNARY_SEARCH_MIN_MAX_INPUT_LENGTH),
        )
        for values in malformed:
            if len(values) <= MAX_TERNARY_SEARCH_MIN_MAX_INPUT_LENGTH:
                cases[values] = TERNARY_SEARCH_MIN_MAX_INVALID_RESULT
    elif algorithm == "cosine_similarity":
        rng = random.Random(20261016)

        def packed(left: tuple[int, ...], right: tuple[int, ...]) -> tuple[int, ...]:
            return (len(left), len(right), *left, *right)

        valid_strings = (
            ((), ()), ((), (32,)), ((32,), ()),
            ((65,), (97,)), ((72, 69, 76, 76, 79), (104, 101, 108, 108, 111)),
            ((97, 98, 99), (120, 121, 122)),
            ((32, 33, 126), (32, 63, 126)),
            ((97, 97, 97, 98), (97, 98, 98, 98)),
            ((32, 33, 126), (126, 33, 32)),
            (tuple([65] * MAX_COSINE_SIMILARITY_STRING_LENGTH),
             tuple([97] * MAX_COSINE_SIMILARITY_STRING_LENGTH)),
            (tuple(range(COSINE_SIMILARITY_MIN_ASCII,
                         COSINE_SIMILARITY_MIN_ASCII + MAX_COSINE_SIMILARITY_STRING_LENGTH)),
             tuple(range(COSINE_SIMILARITY_MAX_ASCII - MAX_COSINE_SIMILARITY_STRING_LENGTH + 1,
                         COSINE_SIMILARITY_MAX_ASCII + 1))),
        )
        for left, right in valid_strings:
            values = packed(left, right)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            left_length = rng.randint(0, MAX_COSINE_SIMILARITY_STRING_LENGTH)
            right_length = rng.randint(0, MAX_COSINE_SIMILARITY_STRING_LENGTH)
            left = tuple(rng.randint(COSINE_SIMILARITY_MIN_ASCII,
                                     COSINE_SIMILARITY_MAX_ASCII)
                         for _ in range(left_length))
            right = tuple(rng.randint(COSINE_SIMILARITY_MIN_ASCII,
                                      COSINE_SIMILARITY_MAX_ASCII)
                          for _ in range(right_length))
            values = packed(left, right)
            cases[values] = oracle(algorithm, list(values))
        too_many = tuple([0] * MAX_COSINE_SIMILARITY_INPUT_LENGTH)
        malformed = (
            (), (0,), (0, 0, 32), (1, 1, 65), (2, 1, 65, 97),
            (-1, 0), (0, -1),
            (MAX_COSINE_SIMILARITY_STRING_LENGTH + 1, 0,
             *([32] * MAX_COSINE_SIMILARITY_PARSEABLE_STRING_LENGTH)),
            (0, MAX_COSINE_SIMILARITY_STRING_LENGTH + 1,
             *([32] * MAX_COSINE_SIMILARITY_PARSEABLE_STRING_LENGTH)),
            (1, 0, 31), (1, 0, 127), (0, 1, I64_MIN), (1, 0, I64_MAX),
            tuple([0] * (MAX_COSINE_SIMILARITY_INPUT_LENGTH - 1)), too_many,
        )
        for values in malformed:
            if len(values) <= MAX_COSINE_SIMILARITY_INPUT_LENGTH:
                cases[values] = COSINE_SIMILARITY_INVALID_RESULT
    elif algorithm == "price_plus_tax":
        rng = random.Random(20261016)
        for price_micro, tax_rate_micro in (
                (0, 0), (0, MAX_PRICE_PLUS_TAX_TAX_RATE_MICRO),
                (MAX_PRICE_PLUS_TAX_PRICE_MICRO, 0),
                (MAX_PRICE_PLUS_TAX_PRICE_MICRO, MAX_PRICE_PLUS_TAX_TAX_RATE_MICRO),
                (MAX_PRICE_PLUS_TAX_PRICE_MICRO - 1, MAX_PRICE_PLUS_TAX_TAX_RATE_MICRO - 1)):
            values = (price_micro, tax_rate_micro)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(128):
            values = (rng.randint(0, MAX_PRICE_PLUS_TAX_PRICE_MICRO),
                      rng.randint(0, MAX_PRICE_PLUS_TAX_TAX_RATE_MICRO))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0, 0), (-1, 0),
            (MAX_PRICE_PLUS_TAX_PRICE_MICRO + 1, 0), (0, -1),
            (0, MAX_PRICE_PLUS_TAX_TAX_RATE_MICRO + 1),
            (I64_MIN, 0), (0, I64_MAX),
            tuple([0] * MAX_PRICE_PLUS_TAX_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = PRICE_PLUS_TAX_INVALID_RESULT
    elif algorithm == "macaulay_duration":
        rng = random.Random(20261016)
        valid_cases = (
            (1, 0, 1, 1),
            (MACAULAY_DURATION_MAX_FACE_MICRO, 0,
             MACAULAY_DURATION_MAX_PERIODS, 1),
            (MACAULAY_DURATION_MAX_FACE_MICRO, MACAULAY_DURATION_MAX_RATE_MICRO,
             MACAULAY_DURATION_MAX_PERIODS, MACAULAY_DURATION_MAX_RATE_MICRO),
            (1, 0, MACAULAY_DURATION_MAX_PERIODS, MACAULAY_DURATION_MAX_RATE_MICRO),
            (500_000_000, 40_000, 12, 40_000),
        )
        for values in valid_cases:
            cases[values] = oracle(algorithm, list(values))
        for _ in range(128):
            values = (rng.randint(1, MACAULAY_DURATION_MAX_FACE_MICRO),
                      rng.randint(0, MACAULAY_DURATION_MAX_RATE_MICRO),
                      rng.randint(1, MACAULAY_DURATION_MAX_PERIODS),
                      rng.randint(1, MACAULAY_DURATION_MAX_RATE_MICRO))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 0, 1), (1, 0, 1, 1, 0),
            (0, 0, 1, 1), (-1, 0, 1, 1),
            (MACAULAY_DURATION_MAX_FACE_MICRO + 1, 0, 1, 1),
            (1, -1, 1, 1), (1, MACAULAY_DURATION_MAX_RATE_MICRO + 1, 1, 1),
            (1, 0, 0, 1), (1, 0, MACAULAY_DURATION_MAX_PERIODS + 1, 1),
            (1, 0, 1, 0), (1, 0, 1, MACAULAY_DURATION_MAX_RATE_MICRO + 1),
            (I64_MIN, 0, 1, 1), (1, 0, 1, I64_MAX),
            tuple([0] * MAX_MACAULAY_DURATION_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = MACAULAY_DURATION_INVALID_RESULT
    elif algorithm == "kelly_criterion":
        rng = random.Random(20261016)
        valid_cases = (
            (KELLY_CRITERION_MIN_PROBABILITY_MICRO, KELLY_CRITERION_MIN_RATIO_MICRO),
            (KELLY_CRITERION_MAX_PROBABILITY_MICRO, KELLY_CRITERION_MAX_RATIO_MICRO),
            (500_000, 1_000), (500_000, 1_000_000),
            (600_000, 2_000_000), (300_000, 2_000_000),
        )
        for values in valid_cases:
            cases[values] = oracle(algorithm, list(values))
        for _ in range(128):
            values = (rng.randint(KELLY_CRITERION_MIN_PROBABILITY_MICRO,
                                  KELLY_CRITERION_MAX_PROBABILITY_MICRO),
                      rng.randint(KELLY_CRITERION_MIN_RATIO_MICRO,
                                  KELLY_CRITERION_MAX_RATIO_MICRO))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (500_000,), (500_000, 1_000_000, 0),
            (0, 1_000_000), (1_000_000, 1_000_000),
            (-1, 1_000_000), (KELLY_CRITERION_MAX_PROBABILITY_MICRO + 1, 1_000_000),
            (500_000, 0), (500_000, -1),
            (500_000, KELLY_CRITERION_MIN_RATIO_MICRO - 1),
            (500_000, KELLY_CRITERION_MAX_RATIO_MICRO + 1),
            (I64_MIN, 1_000_000), (500_000, I64_MAX),
            tuple([0] * MAX_KELLY_CRITERION_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = KELLY_CRITERION_INVALID_RESULT
    elif algorithm in ("present_value", "present_value_rust"):
        rng = random.Random(20261016)
        max_flow_count = (PRESENT_VALUE_MAX_FLOW_COUNT if algorithm == "present_value"
                          else PRESENT_VALUE_RUST_MAX_FLOW_COUNT)
        parseable_input_length = (MAX_PRESENT_VALUE_PARSEABLE_INPUT_LENGTH if algorithm == "present_value"
                                  else MAX_PRESENT_VALUE_RUST_PARSEABLE_INPUT_LENGTH)
        invalid_result = (PRESENT_VALUE_INVALID_RESULT if algorithm == "present_value"
                          else PRESENT_VALUE_RUST_INVALID_RESULT)
        for _ in range(128):
            count = rng.randint(1, max_flow_count)
            values = (count, rng.choice((0, 1_000_000)), *(
                rng.randint(-8_000, 8_000) * 125 for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (0, 0, 0), (1, 0),
            (2, 0, 1_000), (1, 500_000, 1_000), (1, 3_000_000, 1_000),
            (1, 0, 1_124), (1, 0, 1_000_125), (1, 0, -1_000_125),
            (max_flow_count + 1, 0, *([0] * (max_flow_count + 1))),
            (I64_MIN, 0, 0), (1, 0, I64_MAX),
            tuple([0] * parseable_input_length),
        )
        for values in malformed:
            cases[values] = invalid_result
    elif algorithm == "resonant_frequency":
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(RESONANT_FREQUENCY_MIN_COMPONENT,
                                  RESONANT_FREQUENCY_MAX_COMPONENT),
                      rng.randint(RESONANT_FREQUENCY_MIN_COMPONENT,
                                  RESONANT_FREQUENCY_MAX_COMPONENT))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 1, 1), (0, 1), (1, 0), (-1, 1), (1, -1),
            (RESONANT_FREQUENCY_MAX_COMPONENT + 1, 1),
            (1, RESONANT_FREQUENCY_MAX_COMPONENT + 1),
            (I64_MIN, 1), (1, I64_MAX),
        )
        for values in malformed:
            cases[values] = RESONANT_FREQUENCY_INVALID_RESULT
    elif algorithm == "rms_speed_of_molecule":
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(0, RMS_SPEED_MAX_TEMPERATURE),
                      rng.randint(RMS_SPEED_MIN_MOLAR_MASS, RMS_SPEED_MAX_MOLAR_MASS))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 1, 1), (-1, 12), (RMS_SPEED_MAX_TEMPERATURE + 1, 12),
            (273, 0), (273, -1), (273, RMS_SPEED_MAX_MOLAR_MASS + 1),
            (I64_MIN, 1), (1, I64_MAX),
        )
        for values in malformed:
            cases[values] = RMS_SPEED_OF_MOLECULE_INVALID_RESULT
    elif algorithm == "newtons_second_law_of_motion":
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(NEWTONS_SECOND_LAW_MIN_VALUE,
                                  NEWTONS_SECOND_LAW_MAX_VALUE),
                      rng.randint(NEWTONS_SECOND_LAW_MIN_VALUE,
                                  NEWTONS_SECOND_LAW_MAX_VALUE))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 2, 3),
            (NEWTONS_SECOND_LAW_MAX_VALUE + 1, 0),
            (NEWTONS_SECOND_LAW_MIN_VALUE - 1, 0),
            (0, NEWTONS_SECOND_LAW_MAX_VALUE + 1),
            (0, NEWTONS_SECOND_LAW_MIN_VALUE - 1),
            (I64_MIN, 0), (0, I64_MAX),
        )
        for values in malformed:
            cases[values] = NEWTONS_SECOND_LAW_INVALID_RESULT
    elif algorithm == "speed_of_sound":
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(SPEED_OF_SOUND_MIN_DENSITY, SPEED_OF_SOUND_MAX_DENSITY),
                      rng.randint(SPEED_OF_SOUND_MIN_BULK_MODULUS,
                                  SPEED_OF_SOUND_MAX_BULK_MODULUS))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 1, 1), (0, 1), (-1, 1),
            (SPEED_OF_SOUND_MAX_DENSITY + 1, 1),
            (1, 0), (1, -1),
            (1, SPEED_OF_SOUND_MAX_BULK_MODULUS + 1),
            (I64_MIN, 1), (1, I64_MAX),
        )
        for values in malformed:
            cases[values] = SPEED_OF_SOUND_INVALID_RESULT
    elif algorithm == "terminal_velocity":
        rng = random.Random(20261016)
        for _ in range(128):
            values = tuple(rng.randint(TERMINAL_VELOCITY_MIN_INPUT_VALUE,
                                       TERMINAL_VELOCITY_MAX_INPUT_VALUE)
                           for _ in range(4))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 1, 1), (1, 1, 1, 1, 1),
            (0, 1, 1, 1), (-1, 1, 1, 1),
            (1, 0, 1, 1), (1, 1, 0, 1), (1, 1, 1, 0),
            (TERMINAL_VELOCITY_MAX_INPUT_VALUE + 1, 1, 1, 1),
            (1, TERMINAL_VELOCITY_MAX_INPUT_VALUE + 1, 1, 1),
            (1, 1, TERMINAL_VELOCITY_MAX_INPUT_VALUE + 1, 1),
            (I64_MIN, 1, 1, 1), (1, I64_MAX, 1, 1),
        )
        for values in malformed:
            cases[values] = TERMINAL_VELOCITY_INVALID_RESULT
    elif algorithm == "newtons_law_of_gravitation":
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randrange(4), *(
                rng.randint(NEWTONS_GRAVITATION_MIN_VALUE,
                            NEWTONS_GRAVITATION_MAX_VALUE)
                for _ in range(3)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0, 1, 2), (0, 1, 2, 3, 4),
            (4, 1, 1, 1), (-1, 1, 1, 1),
            (0, 1, 0, 1), (0, 1, -1, 1), (0, 1, 1, 1_001),
            (I64_MIN, 1, 1, 1), (0, I64_MAX, 1, 1),
        )
        for values in malformed:
            cases[values] = NEWTONS_GRAVITATION_INVALID_RESULT
    elif algorithm == "ideal_gas_law":
        rng = random.Random(20261016)
        for _ in range(128):
            operation = rng.randrange(4)
            arguments = [rng.randint(IDEAL_GAS_LAW_MIN_ARGUMENT,
                                     IDEAL_GAS_LAW_MAX_ARGUMENT) for _ in range(3)]
            denominator_index = 2 if operation in (0, 1) else 0
            arguments[denominator_index] = rng.randint(1, IDEAL_GAS_LAW_MAX_ARGUMENT)
            values = (operation, *arguments)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0, 1, 2), (0, 1, 2, 3, 4),
            (-1, 1, 1, 1), (4, 1, 1, 1),
            (0, -1, 1, 1), (0, 1, 1, 1_001),
            (0, 1, 1, 0), (1, 1, 1, 0),
            (2, 0, 1, 1), (3, 0, 1, 1),
            (I64_MIN, 1, 1, 1), (0, I64_MAX, 1, 1),
            tuple([0] * MAX_IDEAL_GAS_LAW_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = IDEAL_GAS_LAW_INVALID_RESULT
    elif algorithm == "capacitor_equivalence":
        rng = random.Random(20261016)
        for _ in range(128):
            operation = rng.randrange(2)
            count = rng.randint(1, CAPACITOR_EQUIVALENCE_MAX_COUNT)
            minimum = (CAPACITOR_EQUIVALENCE_MIN_CAPACITANCE if operation == 0 else 1)
            capacitors = tuple(rng.randint(minimum, CAPACITOR_EQUIVALENCE_MAX_CAPACITANCE)
                               for _ in range(count))
            values = (operation, *capacitors)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (1,), (-1, 1), (2, 1),
            (0, -1), (0, CAPACITOR_EQUIVALENCE_MAX_CAPACITANCE + 1),
            (1, 0), (1, -1),
            (0, *([1] * (CAPACITOR_EQUIVALENCE_MAX_COUNT + 1))),
            (1, *([1] * (CAPACITOR_EQUIVALENCE_MAX_COUNT + 1))),
            (I64_MIN, 1), (0, I64_MAX),
            tuple([0] * MAX_CAPACITOR_EQUIVALENCE_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = CAPACITOR_EQUIVALENCE_INVALID_RESULT
    elif algorithm == "poisson_dist":
        rng = random.Random(20261016)
        for _ in range(128):
            operation = rng.randrange(4)
            first_milli = rng.randint(0, POISSON_DIST_MAX_MILLI_VALUE)
            if operation == 0:
                second_milli = rng.randint(1, POISSON_DIST_MAX_MILLI_VALUE)
                third = 0
            elif operation == 1:
                second_milli = rng.randint(0, POISSON_DIST_MAX_MILLI_VALUE)
                third = 0
            elif operation == 2:
                second_milli = rng.randint(0, POISSON_DIST_MAX_SUCCESS_COUNT)
                third = 0
            else:
                second_milli = rng.randint(0, POISSON_DIST_MAX_SUCCESS_COUNT)
                third = rng.randint(second_milli, POISSON_DIST_MAX_SUCCESS_COUNT)
            values = (operation, first_milli, second_milli, third)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0, 1000, 1000), (0, 1000, 1000, 0, 0),
            (-1, 1000, 1000, 0), (4, 1000, 1000, 0),
            (0, -1, 1000, 0), (0, 1000, 0, 0),
            (0, 1000, 1000, 1), (1, 1000, 1000, 1),
            (2, 100001, 1, 0), (2, 1000, -1, 0),
            (2, 1000, POISSON_DIST_MAX_SUCCESS_COUNT + 1, 0),
            (2, 1000, 1, 1), (3, 1000, 4, 3),
            (3, 1000, -1, 4), (3, 1000, 0, POISSON_DIST_MAX_SUCCESS_COUNT + 1),
            (I64_MIN, 1, 1, 1), (0, I64_MAX, 1, 1),
            tuple([0] * MAX_POISSON_DIST_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = POISSON_DIST_INVALID_RESULT
    elif algorithm == "doppler_frequency":
        rng = random.Random(20261016)
        for _ in range(128):
            values = (
                rng.randint(DOPPLER_FREQUENCY_MIN_ORIGINAL_FREQUENCY,
                            DOPPLER_FREQUENCY_MAX_ORIGINAL_FREQUENCY),
                rng.randint(DOPPLER_FREQUENCY_MIN_WAVE_SPEED,
                            DOPPLER_FREQUENCY_MAX_WAVE_SPEED),
                rng.randint(DOPPLER_FREQUENCY_MIN_VELOCITY,
                            DOPPLER_FREQUENCY_MAX_VELOCITY),
                rng.randint(DOPPLER_FREQUENCY_MIN_VELOCITY,
                            DOPPLER_FREQUENCY_MAX_VELOCITY),
            )
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (100, 330, 0), (100, 330, 0, 0, 0),
            (0, 330, 0, 0), (DOPPLER_FREQUENCY_MAX_ORIGINAL_FREQUENCY + 1, 330, 0, 0),
            (100, DOPPLER_FREQUENCY_MIN_WAVE_SPEED - 1, 0, 0),
            (100, DOPPLER_FREQUENCY_MAX_WAVE_SPEED + 1, 0, 0),
            (100, 330, DOPPLER_FREQUENCY_MIN_VELOCITY - 1, 0),
            (100, 330, DOPPLER_FREQUENCY_MAX_VELOCITY + 1, 0),
            (100, 330, 0, DOPPLER_FREQUENCY_MIN_VELOCITY - 1),
            (100, 330, 0, DOPPLER_FREQUENCY_MAX_VELOCITY + 1),
            (I64_MIN, 330, 0, 0), (100, I64_MAX, 0, 0),
            tuple([0] * MAX_DOPPLER_FREQUENCY_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = DOPPLER_FREQUENCY_INVALID_RESULT
    elif algorithm == "secant_method":
        for values in ((0, 100), (1, 0), (1, 1), (1, 2)):
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(128):
            values = ((0, 100) if rng.randrange(2) == 0
                      else (1, rng.randrange(3)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (1, 2, 0), (0, 100, 0), (0, 99), (0, 101),
            (1, -1), (1, 3), (2, 0), (-1, 100),
            (I64_MIN, 100), (I64_MAX, 2),
        )
        for values in malformed:
            cases[values] = SECANT_METHOD_INVALID_RESULT
    elif algorithm == "newton_raphson_method":
        for initial_milli in (2_000, 2_500, 3_000, 3_500, 4_000):
            for limit in (1, 2, 4, 8, 16, 32):
                values = (initial_milli, limit)
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(2_000, 4_000), rng.randint(1, 32))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (2_000,), (2_000, 1, 0), (1_999, 1), (4_001, 1),
            (2_000, 0), (2_000, 33), (I64_MIN, 1), (I64_MAX, 32),
        )
        for values in malformed:
            cases[values] = NEWTON_RAPHSON_METHOD_INVALID_RESULT
    elif algorithm == "newton_raphson":
        for radicand in range(2, 5):
            for start_quarters in range(4, 9):
                values = (radicand, start_quarters)
                cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (2,), (2, 4, 8), (1, 4), (5, 4),
            (2, 3), (2, 9), (I64_MIN, 4), (I64_MAX, 8),
            (2, I64_MIN), (2, I64_MAX),
            tuple([0] * MAX_NEWTON_RAPHSON_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = NEWTON_RAPHSON_INVALID_RESULT
    elif algorithm == "reynolds_number":
        for density in (1, 1_000):
            for velocity in (-1_000, 0, 1_000):
                for diameter in (1, 1_000):
                    for viscosity in (1, 1_000):
                        values = (density, velocity, diameter, viscosity)
                        cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(1, 1_000), rng.randint(-1_000, 1_000),
                      rng.randint(1, 1_000), rng.randint(1, 1_000))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1, 2, 3), (1, 2, 3, 4, 5),
            (0, 2, 5, 4), (1_001, 2, 5, 4),
            (900, -1_001, 5, 4), (900, 1_001, 5, 4),
            (900, 2, 0, 4), (900, 2, 1_001, 4),
            (900, 2, 5, 0), (900, 2, 5, 1_001),
            (I64_MIN, 2, 5, 4), (I64_MAX, 2, 5, 4),
        )
        for values in malformed:
            cases[values] = REYNOLDS_NUMBER_INVALID_RESULT
    elif algorithm == "interquartile_range":
        for length in (2, 3, 4, 5, 6, 8, 16, 64):
            cases[tuple(0 for _ in range(length))] = 0.0
            start = -(length // 2)
            values = tuple(range(start, start + length))
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            length = rng.randint(2, 64)
            values = tuple(rng.randint(-1_000_000, 1_000_000) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (5,), tuple([0] * 65),
            (-1_000_001, 0), (0, 1_000_001),
            (I64_MIN, 0), (0, I64_MAX),
            tuple([0] * MAX_INTERQUARTILE_RANGE_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = INTERQUARTILE_RANGE_INVALID_RESULT
    elif algorithm == "apparent_power":
        for selector in (0, 1):
            for voltage, current in ((0, 0), (0, 1_000), (1_000, 0), (1_000, 1_000)):
                for voltage_angle, current_angle in (
                        (-360, -360), (-90, 0), (0, 0), (90, 0), (360, 360)):
                    values = (selector, voltage, current, voltage_angle, current_angle)
                    cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(0, 1), rng.randint(0, 1_000),
                      rng.randint(0, 1_000), rng.randint(-360, 360),
                      rng.randint(-360, 360))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 100, 5, 0), (0, 100, 5, 0, 0, 0),
            (-1, 100, 5, 0, 0), (2, 100, 5, 0, 0),
            (I64_MIN, 100, 5, 0, 0), (I64_MAX, 100, 5, 0, 0),
            (0, -1, 5, 0, 0), (0, 1_001, 5, 0, 0),
            (0, 100, -1, 0, 0), (0, 100, 1_001, 0, 0),
            (0, 100, 5, -361, 0), (0, 100, 5, 361, 0),
            (0, 100, 5, 0, -361), (0, 100, 5, 0, 361),
            (0, 100, 5, I64_MIN, 0), (0, 100, 5, I64_MAX, 0),
            (0, 100, 5, 0, I64_MIN), (0, 100, 5, 0, I64_MAX),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = APPARENT_POWER_INVALID_RESULT
    elif algorithm == "archimedes_principle_of_buoyant_force":
        cases[(1, 1)] = oracle(algorithm, [1, 1])
        cases[(1, 1_000)] = oracle(algorithm, [1, 1_000])
        cases[(1_000, 1)] = oracle(algorithm, [1_000, 1])
        cases[(1_000, 1_000)] = oracle(algorithm, [1_000, 1_000])
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randint(1, 1_000), rng.randint(1, 1_000))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 1, 1), (0, 1), (-1, 1), (1_001, 1),
            (1, 0), (1, -1), (1, 1_001), (I64_MIN, 1), (1, I64_MAX),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT
    elif algorithm == "automatic_differentiation":
        # A full-size valid chain reaches the documented leaf and operation caps.
        leaves = [1] + [0] * 31
        operations = []
        left_node = 0
        for operation_index in range(64):
            operations.extend((0, left_node, 1))
            left_node = 32 + operation_index
        maximum_tape = tuple([32, 64, 95, 0] + leaves + operations)
        cases[maximum_tape] = oracle(algorithm, list(maximum_tape))

        rng = random.Random(20261016)
        accepted = 0
        attempts = 0
        while accepted < 128 and attempts < 10_000:
            attempts += 1
            leaf_count = rng.randint(1, 6)
            operation_count = rng.randint(1, 16)
            leaf_values = [rng.randint(-4, 4) for _ in range(leaf_count)]
            nodes = [float(value) for value in leaf_values]
            operations = []
            for operation_index in range(operation_count):
                output_node = leaf_count + operation_index
                opcode = rng.choice((0, 1, 2, 3, 5))
                left = rng.randrange(output_node)
                if opcode == 5:
                    right = rng.randint(1, 5)
                    result = nodes[left] ** right
                else:
                    available = [node for node in range(output_node)
                                 if opcode != 3 or nodes[node] != 0.0]
                    if not available:
                        opcode = 0
                        available = list(range(output_node))
                    right = rng.choice(available)
                    if opcode == 0:
                        result = nodes[left] + nodes[right]
                    elif opcode == 1:
                        result = nodes[left] - nodes[right]
                    elif opcode == 2:
                        result = nodes[left] * nodes[right]
                    else:
                        result = nodes[left] / nodes[right]
                if not math.isfinite(result) or abs(result) > 10_000_000_000:
                    break
                nodes.append(result)
                operations.extend((opcode, left, right))
            if len(operations) != 3 * operation_count:
                continue
            values = tuple([leaf_count, operation_count, leaf_count + operation_count - 1,
                            rng.randrange(leaf_count)] + leaf_values + operations)
            cases[values] = oracle(algorithm, list(values))
            accepted += 1

        oversized_operation_count = tuple([1, 65, 65, 0, 1] + [0, 0, 0] * 65)
        oversized_leaf_count = tuple([33, 1, 33, 0] + [0] * 33 + [0, 0, 0])
        malformed = (
            (), (1,), (1, 1), (1, 1, 1),
            (1, 1, 1, 0, 3, 5, 0),
            (0, 1, 1, 0, 3, 0, 0, 1),
            (1, 0, 1, 0, 3),
            (1, 1, 0, 0, 3, 0, 0, 1),
            (1, 1, 1, 1, 3, 5, 0, 1),
            (1, 1, 1, 0, 17, 5, 0, 1),
            (1, 1, 1, 0, 3, 4, 0, 1),
            (1, 1, 1, 0, 3, 6, 0, 1),
            (1, 1, 1, 0, 3, 2, 1, 0),
            (2, 1, 2, 0, 3, 0, 3, 0, 1),
            (1, 1, 1, 0, 3, 5, 0, 0),
            (1, 1, 1, 0, 3, 5, 0, 9),
            (1, 2, 2, 0, 16, 5, 0, 8, 2, 1, 0),
            (1, 1, 1, 0, I64_MIN, 5, 0, 1),
            (1, 1, 1, 0, I64_MAX, 5, 0, 1),
            oversized_leaf_count, oversized_operation_count,
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = AUTOMATIC_DIFFERENTIATION_INVALID_RESULT
    elif algorithm == "boyles_law":
        boundary_supplied = ((1, 1, 1), (1_000, 1_000, 1_000),
                             (1, 1_000, 1), (1_000, 1, 1_000))
        for missing_index in range(4):
            for supplied in boundary_supplied:
                values = (missing_index, *supplied)
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(128):
            values = (rng.randrange(4), rng.randint(1, 1_000),
                      rng.randint(1, 1_000), rng.randint(1, 1_000))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (3,), (3, 100, 120), (3, 100, 120, 150, 1),
            (-1, 100, 120, 150), (4, 100, 120, 150),
            (I64_MIN, 100, 120, 150), (I64_MAX, 100, 120, 150),
            (3, 0, 120, 150), (3, -1, 120, 150),
            (3, 100, 0, 150), (3, 100, 120, 1_001),
            (3, I64_MIN, 120, 150), (3, 100, I64_MAX, 150),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = BOYLES_LAW_INVALID_RESULT
    elif algorithm == "butterworth_filter":
        rng = random.Random(20261016)
        for _ in range(128):
            filter_kind = rng.randrange(9)
            frequency = rng.randint(1, BUTTERWORTH_FILTER_MAX_FREQUENCY)
            samplerate = rng.randint(2 * frequency + 1, BUTTERWORTH_FILTER_MAX_SAMPLE_RATE)
            gain = (rng.randint(-BUTTERWORTH_FILTER_MAX_GAIN_MILLI_DB,
                                BUTTERWORTH_FILTER_MAX_GAIN_MILLI_DB)
                    if filter_kind in (4, 5, 6) else 0)
            q_micro = (-1 if rng.randrange(4) == 0 else
                       rng.randint(1, BUTTERWORTH_FILTER_MAX_Q_MICRO))
            values = (filter_kind, rng.randrange(6), frequency, samplerate, gain, q_micro)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0), (0, 0, 1_000, 48_000, 0, -1, 0),
            (-1, 0, 1_000, 48_000, 0, -1), (9, 0, 1_000, 48_000, 0, -1),
            (0, -1, 1_000, 48_000, 0, -1), (0, 6, 1_000, 48_000, 0, -1),
            (0, 0, 0, 48_000, 0, -1),
            (0, 0, BUTTERWORTH_FILTER_MAX_FREQUENCY + 1, 192_000, 0, -1),
            (0, 0, 1_000, 0, 0, -1),
            (0, 0, 1_000, BUTTERWORTH_FILTER_MAX_SAMPLE_RATE + 1, 0, -1),
            (0, 0, 24_000, 48_000, 0, -1),
            (0, 0, 1_000, 2_000, 0, -1),
            (0, 0, 1_000, 48_000, 0, 0),
            (0, 0, 1_000, 48_000, 0, -2),
            (0, 0, 1_000, 48_000, 0, BUTTERWORTH_FILTER_MAX_Q_MICRO + 1),
            (0, 0, 1_000, 48_000, 1, -1),
            (4, 0, 1_000, 48_000, -BUTTERWORTH_FILTER_MAX_GAIN_MILLI_DB - 1, 1_000_000),
            (6, 0, 1_000, 48_000, BUTTERWORTH_FILTER_MAX_GAIN_MILLI_DB + 1, 1_000_000),
            (I64_MIN, 0, 1_000, 48_000, 0, -1),
            (0, I64_MAX, 1_000, 48_000, 0, -1),
            (0, 0, I64_MIN, 48_000, 0, -1),
            (0, 0, 1_000, I64_MAX, 0, -1),
            (0, 0, 1_000, 48_000, I64_MIN, -1),
            (0, 0, 1_000, 48_000, 0, I64_MAX),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = BUTTERWORTH_FILTER_INVALID_RESULT
    elif algorithm == "center_of_mass":
        for selector in range(3):
            values = (selector, 1, 1_125, -1_250, 875, 1_500)
            cases[values] = oracle(algorithm, list(values))
            values = (selector, 1, -CENTER_OF_MASS_MAX_COORDINATE_UNITS,
                      CENTER_OF_MASS_MAX_COORDINATE_UNITS, 0,
                      CENTER_OF_MASS_MAX_MASS_UNITS)
            cases[values] = oracle(algorithm, list(values))

        maximum_records = []
        for index in range(CENTER_OF_MASS_MAX_PARTICLES):
            maximum_records.extend((
                (-1 if index % 2 else 1) * CENTER_OF_MASS_MAX_COORDINATE_UNITS,
                index * 1_000 // (CENTER_OF_MASS_MAX_PARTICLES - 1),
                -index * 1_000,
                1 + (index * 7_919) % CENTER_OF_MASS_MAX_MASS_UNITS,
            ))
        maximum_input = (0, CENTER_OF_MASS_MAX_PARTICLES, *maximum_records)
        assert len(maximum_input) == MAX_CENTER_OF_MASS_INPUT_LENGTH
        cases[maximum_input] = oracle(algorithm, list(maximum_input))

        rng = random.Random(20261016)
        for _ in range(128):
            particle_count = rng.randint(1, CENTER_OF_MASS_MAX_PARTICLES)
            values = [rng.randrange(3), particle_count]
            for _ in range(particle_count):
                values.extend((
                    rng.randint(-CENTER_OF_MASS_MAX_COORDINATE_UNITS,
                                CENTER_OF_MASS_MAX_COORDINATE_UNITS),
                    rng.randint(-CENTER_OF_MASS_MAX_COORDINATE_UNITS,
                                CENTER_OF_MASS_MAX_COORDINATE_UNITS),
                    rng.randint(-CENTER_OF_MASS_MAX_COORDINATE_UNITS,
                                CENTER_OF_MASS_MAX_COORDINATE_UNITS),
                    rng.randint(1, CENTER_OF_MASS_MAX_MASS_UNITS),
                ))
            packed = tuple(values)
            cases[packed] = oracle(algorithm, values)

        malformed = (
            (), (0,), (0, 0), (0, 1),
            (-1, 1, 0, 0, 0, 1), (3, 1, 0, 0, 0, 1),
            (0, 0), (0, CENTER_OF_MASS_MAX_PARTICLES + 1),
            (0, 1, 0, 0, 0), (0, 1, 0, 0, 0, 1, 7),
            (0, 1, CENTER_OF_MASS_MAX_COORDINATE_UNITS + 1, 0, 0, 1),
            (0, 1, -CENTER_OF_MASS_MAX_COORDINATE_UNITS - 1, 0, 0, 1),
            (1, 1, 0, CENTER_OF_MASS_MAX_COORDINATE_UNITS + 1, 0, 1),
            (2, 1, 0, 0, -CENTER_OF_MASS_MAX_COORDINATE_UNITS - 1, 1),
            (0, 1, 0, 0, 0, 0),
            (0, 1, 0, 0, 0, CENTER_OF_MASS_MAX_MASS_UNITS + 1),
            (0, 1, I64_MIN, 0, 0, 1), (0, 1, I64_MAX, 0, 0, 1),
            (0, 1, 0, 0, 0, I64_MIN), (0, 1, 0, 0, 0, I64_MAX),
            (*maximum_input, 0),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = CENTER_OF_MASS_INVALID_RESULT
    elif algorithm == "centripetal_force":
        boundary_cases = (
            (0, 0, 1),
            (1, 1, 1),
            (CENTRIPETAL_FORCE_MAX_MASS, CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY, 1),
            (CENTRIPETAL_FORCE_MAX_MASS, -CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY,
             CENTRIPETAL_FORCE_MAX_RADIUS),
            (CENTRIPETAL_FORCE_MAX_MASS, 1, CENTRIPETAL_FORCE_MAX_RADIUS),
        )
        for values in boundary_cases:
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(128):
            values = (
                rng.randint(0, CENTRIPETAL_FORCE_MAX_MASS),
                rng.randint(-CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY,
                            CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY),
                rng.randint(1, CENTRIPETAL_FORCE_MAX_RADIUS),
            )
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (0,), (0, 0), (0, 0, 1, 0),
            (-1, 0, 1), (CENTRIPETAL_FORCE_MAX_MASS + 1, 0, 1),
            (0, -CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY - 1, 1),
            (0, CENTRIPETAL_FORCE_MAX_ABSOLUTE_VELOCITY + 1, 1),
            (0, 0, 0), (0, 0, -1),
            (0, 0, CENTRIPETAL_FORCE_MAX_RADIUS + 1),
            (I64_MIN, 0, 1), (I64_MAX, 0, 1),
            (0, I64_MIN, 1), (0, I64_MAX, 1),
            (0, 0, I64_MIN), (0, 0, I64_MAX),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = CENTRIPETAL_FORCE_INVALID_RESULT
    elif algorithm == "cohen_sutherland":
        base_line = (-1_000_000, -1_000_000, 1_000_000, 1_000_000,
                     -2_000_000, 0, 2_000_000, 0)
        for selector in range(5):
            values = (selector, *base_line)
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(128):
            x_min = rng.randint(-COHEN_SUTHERLAND_MAX_COORDINATE_MICRO,
                                COHEN_SUTHERLAND_MAX_COORDINATE_MICRO - 1)
            x_max = rng.randint(x_min + 1, COHEN_SUTHERLAND_MAX_COORDINATE_MICRO)
            y_min = rng.randint(-COHEN_SUTHERLAND_MAX_COORDINATE_MICRO,
                                COHEN_SUTHERLAND_MAX_COORDINATE_MICRO - 1)
            y_max = rng.randint(y_min + 1, COHEN_SUTHERLAND_MAX_COORDINATE_MICRO)
            values = (
                rng.randrange(5), x_min, y_min, x_max, y_max,
                rng.randint(-COHEN_SUTHERLAND_MAX_COORDINATE_MICRO,
                            COHEN_SUTHERLAND_MAX_COORDINATE_MICRO),
                rng.randint(-COHEN_SUTHERLAND_MAX_COORDINATE_MICRO,
                            COHEN_SUTHERLAND_MAX_COORDINATE_MICRO),
                rng.randint(-COHEN_SUTHERLAND_MAX_COORDINATE_MICRO,
                            COHEN_SUTHERLAND_MAX_COORDINATE_MICRO),
                rng.randint(-COHEN_SUTHERLAND_MAX_COORDINATE_MICRO,
                            COHEN_SUTHERLAND_MAX_COORDINATE_MICRO),
            )
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (0,), (0, 0, 0, 0, 0, 0, 0, 0),
            (0, *base_line, 0), (-1, *base_line), (5, *base_line),
            (0, -1_000_000, -1_000_000, -1_000_000, 1_000_000,
             -2_000_000, 0, 2_000_000, 0),
            (0, -1_000_000, 1_000_000, 1_000_000, -1_000_000,
             -2_000_000, 0, 2_000_000, 0),
            (0, -1_000_000, -1_000_000, 1_000_000, 1_000_000,
             COHEN_SUTHERLAND_MAX_COORDINATE_MICRO + 1, 0, 0, 0),
            (0, -1_000_000, -1_000_000, 1_000_000, 1_000_000,
             0, 0, 0, -COHEN_SUTHERLAND_MAX_COORDINATE_MICRO - 1),
            (0, -1_000_000, -1_000_000, 1_000_000, 1_000_000,
             I64_MIN, 0, 0, 0),
            (0, -1_000_000, -1_000_000, 1_000_000, 1_000_000,
             0, 0, 0, I64_MAX),
            tuple([0] * 4_096),
        )
        for values in malformed:
            cases[values] = COHEN_SUTHERLAND_INVALID_RESULT
    elif algorithm == "laplacian_filter":
        if not any(len(case["input_values"]) == MAX_LAPLACIAN_FILTER_INPUT_LENGTH
                   and case["expected_result"] != LAPLACIAN_FILTER_INVALID_RESULT
                   for case in workload["cases"]):
            raise ValueError("laplacian_filter workload is missing valid 3x3 coverage")
        if not any(case["expected_result"] == LAPLACIAN_FILTER_INVALID_RESULT
                   for case in workload["cases"]):
            raise ValueError("laplacian_filter workload is missing invalid-input coverage")

        boundary_cases = (
            (0,) * MAX_LAPLACIAN_FILTER_INPUT_LENGTH,
            (255,) * MAX_LAPLACIAN_FILTER_INPUT_LENGTH,
            (0, 0, 0, 0, 255, 0, 0, 0, 0),
            (255, 0, 0, 0, 0, 0, 0, 0, 0),
            (1, 255, 2, 255, 128, 255, 3, 255, 4),
        )
        for values in boundary_cases:
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(256):
            values = tuple(rng.randint(0, 255)
                           for _ in range(MAX_LAPLACIAN_FILTER_INPUT_LENGTH))
            cases[values] = oracle(algorithm, list(values))

        malformed = [(), (0,) * 8, (0,) * (MAX_LAPLACIAN_FILTER_INPUT_LENGTH + 1),
                     (I64_MIN,) + (0,) * 8, (I64_MAX,) + (0,) * 8]
        for index in range(MAX_LAPLACIAN_FILTER_INPUT_LENGTH):
            for invalid_pixel in (-1, 256):
                values = [0] * MAX_LAPLACIAN_FILTER_INPUT_LENGTH
                values[index] = invalid_pixel
                malformed.append(tuple(values))
        for values in malformed:
            cases[values] = LAPLACIAN_FILTER_INVALID_RESULT
    elif algorithm == "line_sweep":
        if not any(case["expected_result"] == LINE_SWEEP_INVALID_RESULT
                   for case in workload["cases"]):
            raise ValueError("line_sweep workload is missing invalid-input coverage")

        boundary_cases = (
            (0,), (1, 0, 0), (1, 20, 20),
            (2, 0, 2, 3, 5), (2, 0, 2, 2, 4),
            (8, *([0, 20] * 8)),
        )
        for values in boundary_cases:
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(0, 8)
            intervals = []
            for _ in range(count):
                start = rng.randint(0, 20)
                end = rng.randint(start, 20)
                intervals.extend((start, end))
            values = (count, *intervals)
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (0, 0), (-1,), (9,), (1,), (1, 0),
            (2, 0, 1), (1, 5, 3), (1, -1, 0), (1, 0, 21),
            (I64_MIN,), (I64_MAX,), (1, I64_MIN, 0), (1, 0, I64_MAX),
            (8, *([0, 20] * 8), 0),
        )
        for values in malformed:
            if len(values) <= MAX_LINE_SWEEP_INPUT_LENGTH + 1:
                cases[values] = LINE_SWEEP_INVALID_RESULT
    elif algorithm == "lorentz_transformation_four_vector":
        if (not any(len(case["input_values"]) == MAX_LORENTZ_TRANSFORMATION_FOUR_VECTOR_INPUT_LENGTH
                    and case["expected_result"] != LORENTZ_TRANSFORMATION_FOUR_VECTOR_INVALID_RESULT
                    for case in workload["cases"])
                or not any(case["expected_result"] == LORENTZ_TRANSFORMATION_FOUR_VECTOR_INVALID_RESULT
                           for case in workload["cases"])):
            raise ValueError("Lorentz workload must cover a valid vector and invalid input")

        boundary_vectors = (
            (1, 0, -1_000_000, -100_000_000, 100_000_000, -100_000_000),
            (200_000_000, 0, 1_000_000, 100_000_000, -100_000_000, 100_000_000),
            (200_000_000, 1, -1_000_000, -100_000_000, 100_000_000, -100_000_000),
        )
        for values in boundary_vectors:
            cases[values] = oracle(algorithm, list(values))
        for component in range(4):
            values = (200_000_000, component, 1_000_000,
                      100_000_000, -100_000_000, 100_000_000)
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(256):
            values = (rng.randint(1, 200_000_000), rng.randint(0, 3),
                      rng.randint(-1_000_000, 1_000_000),
                      *(rng.randint(-100_000_000, 100_000_000) for _ in range(3)))
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (1,), (1, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0),
            (0, 0, 0, 0, 0, 0), (200_000_001, 0, 0, 0, 0, 0),
            (1, -1, 0, 0, 0, 0), (1, 4, 0, 0, 0, 0),
            (1, 0, -1_000_001, 0, 0, 0), (1, 0, 1_000_001, 0, 0, 0),
            (1, 0, 0, -100_000_001, 0, 0), (1, 0, 0, 0, 100_000_001, 0),
            (I64_MIN, 0, 0, 0, 0, 0), (I64_MAX, 0, 0, 0, 0, 0),
            (1, I64_MIN, 0, 0, 0, 0), (1, 0, 0, I64_MAX, 0, 0),
        )
        for values in malformed:
            cases[values] = LORENTZ_TRANSFORMATION_FOUR_VECTOR_INVALID_RESULT
    elif algorithm == "peak_signal_to_noise_ratio":
        rng = random.Random(20261022)
        for count in (1, 2, 3, 16, PEAK_SIGNAL_TO_NOISE_RATIO_MAX_PIXELS):
            for difference in (1, -1, PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE,
                               -PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE):
                original = [15 + (index * 37) % 226 for index in range(count)]
                compressed = [pixel + difference for pixel in original]
                values = (count, *original, *compressed)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(1, PEAK_SIGNAL_TO_NOISE_RATIO_MAX_PIXELS)
            original = [rng.randrange(256) for _ in range(count)]
            compressed = [max(0, min(255, pixel + rng.randint(
                -PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE,
                PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE))) for pixel in original]
            if all(a == b for a, b in zip(original, compressed)):
                compressed[0] = original[0] + 1 if original[0] < 255 else 254
            values = (count, *original, *compressed)
            cases[values] = oracle(algorithm, list(values))

        identical = (2, 10, 20, 10, 20)
        malformed = (
            (), (0,), (1,), (1, 0), (2, 0, 0, 0),
            (PEAK_SIGNAL_TO_NOISE_RATIO_MAX_PIXELS + 1, *([0] * 128)),
            (1, -1, 0), (1, 256, 0),
            (1, 0, PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE + 1),
            (1, PEAK_SIGNAL_TO_NOISE_RATIO_MAX_DIFFERENCE + 1, 0),
            (1, I64_MIN, 0), (1, I64_MAX, 0),
            (1, 0, 0, 0), identical,
            tuple([64] + [0] * (2 * PEAK_SIGNAL_TO_NOISE_RATIO_MAX_PIXELS)),
        )
        for values in malformed:
            if len(values) <= MAX_PEAK_SIGNAL_TO_NOISE_RATIO_INPUT_LENGTH:
                cases[values] = PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT
    elif algorithm == "reverse_polish_notation":
        for expression in (
            b"42", b"3 4 +", b"5 2 -", b"3 4 *", b"3 4 /",
            b"1 2 /", b"-3 2 *", b"+3 4 +", b"003 004 +",
            b"8 2 / 5 +", b"2 3 4 - -",
        ):
            values = tuple(expression)
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        operators = (b"+", b"-", b"*")
        for _ in range(128):
            operand_count = rng.randint(2, REVERSE_POLISH_NOTATION_MAX_TOKEN_COUNT // 2 + 1)
            tokens = [str(rng.randint(-100, 100)).encode("ascii")
                      for _ in range(operand_count)]
            tokens.extend(rng.choice(operators) for _ in range(operand_count - 1))
            expression = b" ".join(tokens)
            if len(expression) <= MAX_REVERSE_POLISH_NOTATION_INPUT_LENGTH:
                values = tuple(expression)
                cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), tuple(b"1 2"), tuple(b"1 +"), tuple(b"1 0 /"),
            tuple(b"1 2 3 +"), tuple(b"1  2 +"), tuple(b"1 2 + "),
            tuple(b"1 2 q"), tuple(b"1.5 2 +"), tuple(b"1000001"),
            tuple(b"1 \x80"), (I64_MIN,), (I64_MAX,),
            tuple([49] * MAX_REVERSE_POLISH_NOTATION_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            if len(values) <= MAX_REVERSE_POLISH_NOTATION_PARSEABLE_INPUT_LENGTH:
                cases[values] = REVERSE_POLISH_NOTATION_INVALID_RESULT
    elif algorithm == "fractional_differentiation":
        rng = random.Random(20261016)
        for _ in range(256):
            window = rng.randint(1, 8)
            n = rng.randint(window + 1, 16)
            values = (rng.randint(0, 1_000_000), window,
                      *(rng.randint(-1_000_000, 1_000_000) for _ in range(n)))
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (0,), (0, 1), (0, 1, 2), (-1, 2, 0, 0),
                     (1_000_001, 1, 0, 1), (500_000, 0, 1, 2),
                     (500_000, 9, *([0] * 10)), (500_000, 3, 1, 2, 3),
                     (500_000, 1, *([0] * 17)), (500_000, 2, 0, 0, 1_000_001),
                     (I64_MIN, 2, 0, 1, 2), (I64_MAX, 2, 0, 1, 2),
                     tuple([0] * (MAX_FRACTIONAL_DIFFERENTIATION_INPUT_LENGTH + 1)))
        for values in malformed:
            cases[values] = FRACTIONAL_DIFFERENTIATION_INVALID_RESULT
    elif algorithm == "symmetric_derivative":
        for function_id in (0, 1):
            for x_nanounits in (
                    SYMMETRIC_DERIVATIVE_MIN_X_NANOUNITS,
                    SYMMETRIC_DERIVATIVE_MIN_X_NANOUNITS + 1,
                    -6_000_000_000, -3_141_592_654, -1_000_000_000,
                    -1, 0, 1, 1_000_000_000, 3_141_592_654,
                    6_000_000_000, SYMMETRIC_DERIVATIVE_MAX_X_NANOUNITS - 1,
                    SYMMETRIC_DERIVATIVE_MAX_X_NANOUNITS):
                values = (function_id, x_nanounits)
                cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(256):
            values = (rng.randrange(2), rng.randint(SYMMETRIC_DERIVATIVE_MIN_X_NANOUNITS,
                                                    SYMMETRIC_DERIVATIVE_MAX_X_NANOUNITS))
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (0,), (0, 0, 0), (-1, 0), (2, 0),
            (0, SYMMETRIC_DERIVATIVE_MIN_X_NANOUNITS - 1),
            (1, SYMMETRIC_DERIVATIVE_MAX_X_NANOUNITS + 1),
            (I64_MIN, 0), (I64_MAX, 0), (0, I64_MIN), (1, I64_MAX),
            tuple([0] * MAX_SYMMETRIC_DERIVATIVE_PARSEABLE_INPUT_LENGTH),
        )
        for values in malformed:
            cases[values] = SYMMETRIC_DERIVATIVE_INVALID_RESULT
    elif algorithm == "gradient_boosting_regressor":
        rng = random.Random(20261016)
        for _ in range(256):
            n = rng.randint(2, 10)
            xs = sorted(rng.sample(range(-1000, 1001), n))
            ys = [rng.randint(-1_000_000, 1_000_000) for _ in range(n)]
            values = (n, rng.randint(1, 8), rng.randint(1, 1_000_000),
                      rng.randint(-1000, 1000), *xs, *ys)
            cases[values] = oracle(algorithm, list(values))
        for case in workload["cases"]:
            values = tuple(case["input_values"])
            if case.get("input_length") != len(values):
                raise ValueError(f"gradient_boosting_regressor input length mismatch: {case['id']}")
            expected = oracle(algorithm, list(values))
            if not math.isclose(expected, case["expected_result"], rel_tol=1e-12, abs_tol=1e-9):
                raise ValueError(f"gradient_boosting_regressor workload mismatch: {case['id']}")
            cases[values] = expected
    elif algorithm == "gaussian_legendre":
        rng = random.Random(20261016)
        for _ in range(256):
            values = (rng.randint(1, 5), rng.randint(-5000, 5000), rng.randint(-5000, 5000),
                      *(rng.randint(-10000, 10000) for _ in range(4)))
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (1,), (0, 0, 0, 0, 0, 0, 0), (6, 0, 0, 0, 0, 0, 0),
                     (1, -5001, 0, 0, 0, 0, 0), (5, 0, 0, 0, 0, 0, 10001),
                     (1, 0, 0, 0, 0, 0, 0, 0))
        for values in malformed:
            cases[values] = GAUSSIAN_LEGENDRE_INVALID_RESULT
    else:
        raise ValueError(f"no corpus for {algorithm}")

    null_lengths = {"hubble_parameter": 5, "light_aberration": 2, "variance": 2,
                    "dice_coefficient": 2, "density": 3, "hinge_loss": 3,
                    "collaborative_filtering": 1,
                    "collaborative_filtering_pearson_similarity": 2,
                    "quadratic_equation_solver_complex_roots": 4,
                    "linear_regression_cost": 2,
                    "price_plus_tax": 2,
                    "macaulay_duration": 4,
                    "kelly_criterion": 2,
                    "ground_to_ground_projectile_motion": 4,
                    "huber_loss": 3, "huber_loss_math": 3,
                    "exponential_dist": 2, "expected_shortfall": 2,
                    "time_converter": 2, "temperature_converter": 2, "value_at_risk": 2,
                    "durand_kerner_roots": 0,
                    "trapezoidal_integration": 4,
                    "midpoint_integral_method": 4,
                    "weddles_rule": 9,
                    "units_converter": 6,
                    "ternary_search_min_max_recursive": 4,
                    "cosine_similarity": 2,
                    "present_value": 3,
                    "present_value_rust": 3,
                    "resonant_frequency": 0,
                    "rms_speed_of_molecule": 0,
                    "newtons_second_law_of_motion": 0,
                    "speed_of_sound": 0,
                    "terminal_velocity": 0,
                    "newtons_law_of_gravitation": 0,
                    "ideal_gas_law": 0,
                    "capacitor_equivalence": 0,
                    "poisson_dist": 0,
                    "doppler_frequency": 0,
                    "secant_method": 2,
                    "newton_raphson_method": 2,
                    "newton_raphson": 2,
                    "reynolds_number": 4,
                    "interquartile_range": 4,
                    "apparent_power": 5,
                    "archimedes_principle_of_buoyant_force": 2,
                    "automatic_differentiation": 0,
                    "boyles_law": 4,
                    "butterworth_filter": 6,
                    "center_of_mass": 2,
                    "centripetal_force": 3,
                    "cohen_sutherland": 9,
                    "laplacian_filter": MAX_LAPLACIAN_FILTER_INPUT_LENGTH,
                    "line_sweep": 1,
                    "lorentz_transformation_four_vector": MAX_LORENTZ_TRANSFORMATION_FOUR_VECTOR_INPUT_LENGTH,
                    "peak_signal_to_noise_ratio": 0,
                    "reverse_polish_notation": 1,
                    "symmetric_derivative": 2,
                    "fractional_differentiation": 4,
                    "gaussian_legendre": 7,
                    "gradient_boosting_regressor": MAX_GRADIENT_BOOSTING_REGRESSOR_INPUT_LENGTH,
                    "extended_kalman_filter": 0}
    null_lengths.update({"return_on_investment": 2, "debt_to_equity": 2,
                         "gross_profit_margin": 2, "earnings_per_sale": 3})
    null_lengths["prefix_evaluation"] = 1
    null_lengths["energy"] = 3
    null_length = null_lengths[algorithm]
    null_result = (COLLABORATIVE_PREDICTION_INVALID_RESULT if algorithm == "collaborative_filtering" else
                   COLLABORATIVE_PEARSON_INVALID_RESULT if algorithm == "collaborative_filtering_pearson_similarity" else
                   QUADRATIC_EQUATION_SOLVER_INVALID_RESULT
                   if algorithm == "quadratic_equation_solver_complex_roots" else
                   GROUND_PROJECTILE_INVALID_RESULT
                   if algorithm == "ground_to_ground_projectile_motion" else
                   HUBER_LOSS_INVALID_RESULT if algorithm == "huber_loss" else
                   HUBER_LOSS_MATH_INVALID_RESULT if algorithm == "huber_loss_math" else
                   EXPONENTIAL_DIST_INVALID_RESULT if algorithm == "exponential_dist" else
                   EXPECTED_SHORTFALL_INVALID_RESULT if algorithm == "expected_shortfall" else
                   TIME_CONVERTER_INVALID_RESULT if algorithm == "time_converter" else
                   TEMPERATURE_CONVERTER_INVALID_RESULT if algorithm == "temperature_converter" else
                   VALUE_AT_RISK_INVALID_RESULT if algorithm == "value_at_risk" else
                   ENERGY_INVALID_RESULT if algorithm == "energy" else
                   TRAPEZOIDAL_INTEGRATION_INVALID_RESULT if algorithm == "trapezoidal_integration" else
                   MIDPOINT_INTEGRAL_METHOD_INVALID_RESULT if algorithm == "midpoint_integral_method" else
                   WEDDLES_RULE_INVALID_RESULT if algorithm == "weddles_rule" else
                   UNITS_CONVERTER_INVALID_RESULT if algorithm == "units_converter" else
                   PREFIX_EVALUATION_INVALID_RESULT if algorithm == "prefix_evaluation" else
                   TERNARY_SEARCH_MIN_MAX_INVALID_RESULT if algorithm == "ternary_search_min_max_recursive" else
                   COSINE_SIMILARITY_INVALID_RESULT if algorithm == "cosine_similarity" else
                   MACAULAY_DURATION_INVALID_RESULT if algorithm == "macaulay_duration" else
                   KELLY_CRITERION_INVALID_RESULT if algorithm == "kelly_criterion" else
                   PRESENT_VALUE_INVALID_RESULT if algorithm == "present_value" else
                   PRESENT_VALUE_RUST_INVALID_RESULT if algorithm == "present_value_rust" else
                   RESONANT_FREQUENCY_INVALID_RESULT if algorithm == "resonant_frequency" else
                   RMS_SPEED_OF_MOLECULE_INVALID_RESULT if algorithm == "rms_speed_of_molecule" else
                   NEWTONS_SECOND_LAW_INVALID_RESULT if algorithm == "newtons_second_law_of_motion" else
                   SPEED_OF_SOUND_INVALID_RESULT if algorithm == "speed_of_sound" else
                   TERMINAL_VELOCITY_INVALID_RESULT if algorithm == "terminal_velocity" else
                   DURAND_KERNER_INVALID_RESULT if algorithm == "durand_kerner_roots" else
                   NEWTONS_GRAVITATION_INVALID_RESULT if algorithm == "newtons_law_of_gravitation" else
                   IDEAL_GAS_LAW_INVALID_RESULT if algorithm == "ideal_gas_law" else
                   CAPACITOR_EQUIVALENCE_INVALID_RESULT if algorithm == "capacitor_equivalence" else
                   POISSON_DIST_INVALID_RESULT if algorithm == "poisson_dist" else
                   DOPPLER_FREQUENCY_INVALID_RESULT if algorithm == "doppler_frequency" else
                   SECANT_METHOD_INVALID_RESULT if algorithm == "secant_method" else
                   NEWTON_RAPHSON_METHOD_INVALID_RESULT if algorithm == "newton_raphson_method" else
                   NEWTON_RAPHSON_INVALID_RESULT if algorithm == "newton_raphson" else
                   REYNOLDS_NUMBER_INVALID_RESULT if algorithm == "reynolds_number" else
                   INTERQUARTILE_RANGE_INVALID_RESULT if algorithm == "interquartile_range" else
                   APPARENT_POWER_INVALID_RESULT if algorithm == "apparent_power" else
                   ARCHIMEDES_PRINCIPLE_OF_BUOYANT_FORCE_INVALID_RESULT
                   if algorithm == "archimedes_principle_of_buoyant_force" else
                   AUTOMATIC_DIFFERENTIATION_INVALID_RESULT
                   if algorithm == "automatic_differentiation" else
                   BOYLES_LAW_INVALID_RESULT if algorithm == "boyles_law" else
                   BUTTERWORTH_FILTER_INVALID_RESULT if algorithm == "butterworth_filter" else
                   CENTER_OF_MASS_INVALID_RESULT if algorithm == "center_of_mass" else
                   CENTRIPETAL_FORCE_INVALID_RESULT if algorithm == "centripetal_force" else
                   COHEN_SUTHERLAND_INVALID_RESULT if algorithm == "cohen_sutherland" else
                   LAPLACIAN_FILTER_INVALID_RESULT if algorithm == "laplacian_filter" else
                   LINE_SWEEP_INVALID_RESULT if algorithm == "line_sweep" else
                   LORENTZ_TRANSFORMATION_FOUR_VECTOR_INVALID_RESULT
                   if algorithm == "lorentz_transformation_four_vector" else
                   PEAK_SIGNAL_TO_NOISE_RATIO_INVALID_RESULT
                   if algorithm == "peak_signal_to_noise_ratio" else
                   REVERSE_POLISH_NOTATION_INVALID_RESULT
                   if algorithm == "reverse_polish_notation" else
                   SYMMETRIC_DERIVATIVE_INVALID_RESULT
                   if algorithm == "symmetric_derivative" else
                   GRADIENT_BOOSTING_REGRESSOR_INVALID_RESULT if algorithm == "gradient_boosting_regressor" else
                   EXTENDED_KALMAN_FILTER_INVALID_RESULT if algorithm == "extended_kalman_filter" else
                   PRICE_PLUS_TAX_INVALID_RESULT if algorithm == "price_plus_tax" else
                   FINANCE_RATIOS_INVALID_RESULT if algorithm in {"return_on_investment", "debt_to_equity", "gross_profit_margin", "earnings_per_sale"} else
                   INVALID_RESULT)
    null_values = (
        (0, -1_000_000, -1_000_000, 1_000_000, 1_000_000,
         -2_000_000, 0, 2_000_000, 0)
        if algorithm == "cohen_sutherland" else (0,) * null_length
    )
    null_cases = [(null_values, null_result)]
    lines = [f"{len(cases) + len(null_cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} 0 {expected:.17g} {relative_tolerance:.17g} "
                     f"{absolute_tolerance:.17g}{suffix}\n")
    for values, expected in null_cases:
        lines.append(f"{len(values)} 1 {expected:.17g} {relative_tolerance:.17g} "
                     f"{absolute_tolerance:.17g}\n")
    return "".join(lines), len(cases) + len(null_cases)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_float64")
    checker = manifest["binaries"]["i64_array_float64_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"i64-array float64 C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_float64.py"),
         "--build-manifest", str(directory / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    absolute_tolerance, relative_tolerance = resolve_tolerances(workload)
    for case, record in zip(workload["cases"], records):
        values, expected = encode_case(case, algorithm)
        observed = float(record["measurement"]["observed_result"])
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "i64_array_float64_call"
                or not result_matches(observed, expected, absolute_tolerance, relative_tolerance)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, default="hubble_parameter")
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_float64")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    algorithm = args.algorithm
    workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload, algorithm)
    (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language,
                                directory / algorithm / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                results.append(job.result())
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            print(f"PASS {algorithm}/{language}: {case_count} oracle arrays, "
                  f"{len(workload['cases'])} workload records", flush=True)
    report = {"algorithms": [algorithm], "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / f"{algorithm}-verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
