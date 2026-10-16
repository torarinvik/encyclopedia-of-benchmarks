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

ALGORITHMS = ("hubble_parameter", "light_aberration", "variance", "dice_coefficient", "density", "hinge_loss", "collaborative_filtering", "collaborative_filtering_pearson_similarity", "quadratic_equation_solver_complex_roots", "linear_regression_cost", "price_plus_tax", "macaulay_duration", "kelly_criterion", "ground_to_ground_projectile_motion", "huber_loss", "huber_loss_math", "exponential_dist", "expected_shortfall", "time_converter", "temperature_converter", "value_at_risk", "energy", "trapezoidal_integration", "cosine_similarity", "present_value", "present_value_rust", "resonant_frequency", "rms_speed_of_molecule", "newtons_second_law_of_motion", "speed_of_sound", "terminal_velocity")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(algorithm: str, values: list[int]) -> float:
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

    if algorithm == "hubble_parameter":
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
            (I64_MIN, 1, 1, 1), (1, I64_MAX, 1, 1),
        )
        for values in malformed:
            cases[values] = TERMINAL_VELOCITY_INVALID_RESULT
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
                    "trapezoidal_integration": 4,
                    "cosine_similarity": 2,
                    "present_value": 3,
                    "present_value_rust": 3,
                    "resonant_frequency": 0,
                    "rms_speed_of_molecule": 0,
                    "newtons_second_law_of_motion": 0,
                    "speed_of_sound": 0,
                    "terminal_velocity": 0}
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
                   PRICE_PLUS_TAX_INVALID_RESULT if algorithm == "price_plus_tax" else
                   INVALID_RESULT)
    null_cases = [((0,) * null_length, null_result)]
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
