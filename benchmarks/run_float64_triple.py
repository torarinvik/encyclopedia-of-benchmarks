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
from coordinate_converter_oracle import expected_result as coordinate_converter_expected
from rectangular_to_polar_oracle import expected_result as rectangular_to_polar_expected
from standard_score_oracle import INVALID_RESULT as STANDARD_SCORE_INVALID_RESULT
from standard_score_oracle import expected_result as standard_score_expected
from dual_number_automatic_differentiation_oracle import INVALID_RESULT as DUAL_NUMBER_AD_INVALID_RESULT
from dual_number_automatic_differentiation_oracle import expected_result as dual_number_ad_expected
from improved_perlin_noise_3d_oracle import expected_result as improved_perlin_noise_3d_expected

SUPPORTED_ALGORITHMS = {"lerp", "arc_length", "bayes_theorem", "affine_converter", "brent_method_extrema", "golden_search_extrema", "annuity_due_future_value", "ordinary_annuity_future_value", "count_numbers_divisible", "sum_of_geometric_progression", "sum_of_harmonic_series", "equated_monthly_installments", "pressure", "order_of_magnitude_conversion", "pressure_conversions", "addition_rule", "electric_power", "cartesian_to_polar", "coordinate_converter", "rectangular_to_polar", "ohms_law", "first_law_of_thermodynamics", "length_conversion", "weight_conversion", "weight", "prefix_conversions", "time_conversions", "mirror_formulae", "simple_interest", "temperature", "line_length", "energy_conversions", "binomial_dist", "orbital_capture_radii", "standard_score", "dual_number_automatic_differentiation", "improved_perlin_noise_3d"}
ENERGY_CONVERSION_FACTORS = (1.0, 1000.0, 1000000.0, 1000000000.0, 1.0,
                             3600.0, 3600000.0, 1.0, 4186.8, 4186800.0,
                             1.602176634e-19, 1055.05585, 1.355818)
RUST_WEIGHT_FACTORS = (1e12, 1e9, 1000.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15,
                       1016.0469088, 907.18474, 50.80234544, 12.70058636,
                       6.35029318, 0.45359237, 0.028349523125, 0.0017718451953125,
                       0.00006479891, 0.3732417216, 0.0311034768, 0.00155517384,
                       0.0002, 1.66053906660e-27)


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
    elif algorithm == "golden_search_extrema":
        phi = 1.61803400516510009765625
        epsilon = 1e-7
        minimum_width = 2e-7
        pi = math.pi
        valid_objective = start in (0.0, 1.0)
        target = 2.0 if start == 0.0 else pi
        endpoint_range = ((0.0 <= end <= 4.0 and 0.0 <= t <= 4.0) if start == 0.0
                          else (2.0 <= end <= 4.0 and 2.0 <= t <= 4.0))
        low, high = sorted((end, t))
        valid = (valid_objective and endpoint_range and high - low >= minimum_width
                 and low < target < high)
        if not valid:
            if expected != -1.0:
                raise ValueError("invalid golden_search_extrema inputs must use the -1.0 result sentinel")
        else:
            a, b = low, high
            mean = math.inf
            previous_mean = math.inf
            for _ in range(128):
                if abs(b - a) <= epsilon:
                    break
                previous_mean = mean
                ratio = (b - a) / phi
                c, d = b - ratio, a + ratio
                fc = ((c - 2.0) * (c - 2.0) if start == 0.0 else math.cos(c))
                fd = ((d - 2.0) * (d - 2.0) if start == 0.0 else math.cos(d))
                if fc < fd:
                    b = d
                else:
                    a = c
                mean = (a + b) / 2.0
            if expected == -1.0 or abs(expected - previous_mean) > tolerance * max(
                    1.0, abs(end), abs(t)):
                raise ValueError("golden_search_extrema expected result must match the source's previous-midpoint recurrence")
    elif algorithm == "annuity_due_future_value":
        valid = (0.0 <= start <= 10000.0 and end.is_integer()
                 and 1.0 <= end <= 20.0 and 0.0 < t <= 0.5)
        if not valid:
            raise ValueError("annuity_due_future_value requires payment in [0, 10000], integral periods in [1, 20], and rate in (0, 0.5]")
    elif algorithm == "ordinary_annuity_future_value":
        valid = (0.0 <= start <= 10000.0 and end.is_integer()
                 and 1.0 <= end <= 20.0 and 0.01 <= t <= 0.5)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid ordinary_annuity_future_value inputs must use the -1e300 result sentinel")
        else:
            if expected == -1e300:
                raise ValueError("valid ordinary_annuity_future_value inputs cannot use the invalid-input sentinel")
            annuity_factor = (((1.0 + t) ** int(end)) - 1.0) / t
            expected_value = start * annuity_factor
            if abs(expected - expected_value) > tolerance * max(1.0, abs(start), abs(end)):
                raise ValueError("ordinary_annuity_future_value expected result must match the pinned factor-then-payment formula")
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
    elif algorithm == "coordinate_converter":
        source_result = coordinate_converter_expected([start, end, t])
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid coordinate_converter inputs must use the -1e300 result sentinel")
        else:
            if expected == -1e300 or abs(expected - source_result) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("coordinate_converter expected result must match the selected Java conversion")
    elif algorithm == "rectangular_to_polar":
        source_result = rectangular_to_polar_expected([start, end, t])
        if source_result == -1e300:
            if expected != -1e300:
                raise ValueError("invalid rectangular_to_polar inputs must use the -1e300 result sentinel")
        elif (expected == -1e300 or expected != source_result
              or (expected == 0.0 and math.copysign(1.0, expected) != math.copysign(1.0, source_result))):
            raise ValueError("rectangular_to_polar expected result must match Rust's two-decimal, ties-away conversion")
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
    elif algorithm == "weight_conversion":
        destination_factors = (1.0, 1000.0, 1_000_000.0, 0.001, 0.0009842073,
                               0.0011023122, 2.2046244202, 0.1574731728,
                               35.273990723, 5000.0, 6.022136652e26)
        source_factors = (1.0, 0.001, 0.000001, 1000.0, 1016.04608, 907.184,
                          0.453592, 6.35029, 0.0283495, 0.0002, 1.660540199e-27)
        valid = (-1_000_000.0 <= start <= 1_000_000.0
                 and end.is_integer() and t.is_integer()
                 and 0.0 <= end < len(destination_factors)
                 and 0.0 <= t < len(source_factors))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid weight_conversion inputs must use the -1e300 result sentinel")
        else:
            expected_value = (start * destination_factors[int(t)]) * source_factors[int(end)]
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("weight_conversion expected result must match the source-ordered factor tables")
    elif algorithm == "weight":
        valid = (-1_000_000.0 <= start <= 1_000_000.0
                 and end.is_integer() and t.is_integer()
                 and 0.0 <= end < len(RUST_WEIGHT_FACTORS)
                 and 0.0 <= t < len(RUST_WEIGHT_FACTORS))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid weight inputs must use the -1e300 result sentinel")
        else:
            expected_value = (start * RUST_WEIGHT_FACTORS[int(end)]) / RUST_WEIGHT_FACTORS[int(t)]
            if expected == -1e300 or not matches_output_relative(
                    expected, expected_value, tolerance):
                raise ValueError("weight expected result must match the pinned formula within output-relative tolerance")
    elif algorithm == "prefix_conversions":
        si_exponents = (24, 21, 18, 15, 12, 9, 6, 3, 2, 1,
                        -1, -2, -3, -6, -9, -12, -15, -18, -21, -24)
        binary_exponents = (8, 7, 6, 5, 4, 3, 2, 1)
        valid_codes = (end.is_integer() and t.is_integer()
                       and ((0.0 <= end < len(si_exponents)
                             and 0.0 <= t < len(si_exponents))
                            or (20.0 <= end < 20.0 + len(binary_exponents)
                                and 20.0 <= t < 20.0 + len(binary_exponents))))
        valid = -1_000_000.0 <= start <= 1_000_000.0 and valid_codes
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid prefix_conversions inputs must use the -1e300 result sentinel")
        else:
            known_code, unknown_code = int(end), int(t)
            if known_code < 20:
                exponent_delta = si_exponents[known_code] - si_exponents[unknown_code]
                expected_value = start * (10 ** exponent_delta)
            else:
                exponent_delta = (binary_exponents[known_code - 20]
                                  - binary_exponents[unknown_code - 20])
                expected_value = start * (2 ** (exponent_delta * 10))
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("prefix_conversions expected result must match the pinned SI or binary exponent formula")
    elif algorithm == "time_conversions":
        time_chart = (1.0, 60.0, 3600.0, 86400.0, 604800.0, 2629800.0, 31557600.0)
        time_chart_inverse = (1.0, 0.016666666666666666, 0.0002777777777777778,
                              1.1574074074074073e-05, 1.6534391534391535e-06,
                              3.802570537683474e-07, 3.168808781402895e-08)
        valid = (0.0 <= start <= 10_000.0 and end.is_integer() and t.is_integer()
                 and 0.0 <= end < len(time_chart) and 0.0 <= t < len(time_chart_inverse))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid time_conversions inputs must use the -1e300 result sentinel")
        else:
            expected_value = round((start * time_chart[int(end)]) * time_chart_inverse[int(t)], 3)
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(expected_value)):
                raise ValueError("time_conversions expected result must match the source's ordered factor and rounding formula")
    elif algorithm == "mirror_formulae":
        valid = (1e-6 <= abs(start) <= 1e6 and 1e-6 <= abs(end) <= 1e6
                 and t.is_integer() and 0.0 <= t <= 2.0)
        if valid:
            denominator = ((1.0 / start) + (1.0 / end) if t == 0.0 else
                           (1.0 / start) - (1.0 / end))
            valid = denominator != 0.0
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid or singular mirror_formulae inputs must use the -1e300 result sentinel")
        else:
            expected_value = 1.0 / denominator
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(expected_value)):
                raise ValueError("mirror_formulae expected result must match the selected reciprocal source formula")
    elif algorithm == "simple_interest":
        valid = (0.0 < start <= 1_000_000.0 and 0.0 <= end <= 1.0
                 and 0.0 < t <= 3_650.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid simple_interest inputs must use the -1e300 result sentinel")
        else:
            expected_value = (start * end) * t
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(expected_value)):
                raise ValueError("simple_interest expected result must match principal * daily_rate * days")
    elif algorithm == "energy_conversions":
        valid = (-1_000_000.0 <= start <= 1_000_000.0 and end.is_integer()
                 and t.is_integer() and 0.0 <= end < len(ENERGY_CONVERSION_FACTORS)
                 and 0.0 <= t < len(ENERGY_CONVERSION_FACTORS))
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid energy_conversions inputs must use the -1e300 result sentinel")
        else:
            expected_value = (start * ENERGY_CONVERSION_FACTORS[int(end)]) / ENERGY_CONVERSION_FACTORS[int(t)]
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("energy_conversions expected result must match the ordered source-factor formula")
    elif algorithm == "temperature":
        valid = (-1_000_000.0 <= start <= 1_000_000.0 and end.is_integer()
                 and t.is_integer() and 0.0 <= end <= 7.0 and 0.0 <= t <= 7.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid temperature inputs must use the -1e300 result sentinel")
        else:
            from_unit, to_unit = int(end), int(t)
            if from_unit == 0:
                kelvin = start
            elif from_unit == 1:
                kelvin = start + 273.15
            elif from_unit == 2:
                kelvin = (start + 459.67) * 5.0 / 9.0
            elif from_unit == 3:
                kelvin = start * 5.0 / 9.0
            elif from_unit == 4:
                kelvin = 373.15 - start * 2.0 / 3.0
            elif from_unit == 5:
                kelvin = start * 100.0 / 33.0 + 273.15
            elif from_unit == 6:
                kelvin = start * 5.0 / 4.0 + 273.15
            else:
                kelvin = (start - 7.5) * 40.0 / 21.0 + 273.15

            if to_unit == 0:
                expected_value = kelvin
            elif to_unit == 1:
                expected_value = kelvin - 273.15
            elif to_unit == 2:
                expected_value = kelvin * 9.0 / 5.0 - 459.67
            elif to_unit == 3:
                expected_value = kelvin * 9.0 / 5.0
            elif to_unit == 4:
                expected_value = (373.15 - kelvin) * 3.0 / 2.0
            elif to_unit == 5:
                expected_value = (kelvin - 273.15) * 33.0 / 100.0
            elif to_unit == 6:
                expected_value = (kelvin - 273.15) * 4.0 / 5.0
            else:
                expected_value = (kelvin - 273.15) * 21.0 / 40.0 + 7.5
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(expected_value)):
                raise ValueError("temperature expected result must match the pinned two-step conversion")
    elif algorithm == "line_length":
        valid = (-10.0 <= start <= end <= 10.0 and t.is_integer() and 1.0 <= t <= 10_000.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid line_length inputs must use the -1e300 result sentinel")
        else:
            steps = int(t)
            x1 = start
            fx1 = math.sin(10.0 * x1)
            expected_value = 0.0
            for _ in range(steps):
                x2 = (end - start) / steps + x1
                fx2 = math.sin(10.0 * x2)
                dx, dy = x2 - x1, fx2 - fx1
                expected_value += math.sqrt(dx * dx + dy * dy)
                x1, fx1 = x2, fx2
            if expected == -1e300 or abs(expected - expected_value) > tolerance * max(
                    1.0, abs(start), abs(end)):
                raise ValueError("line_length expected result must match the repeated-step sine polyline")
    elif algorithm == "binomial_dist":
        valid = (start.is_integer() and t.is_integer()
                 and 1.0 <= start <= 16.0 and 1.0 <= t <= start
                 and end in (0.25, 0.5, 0.75))
        if not valid:
            raise ValueError("binomial_dist requires integral 1 <= x <= n <= 16 and p in {0.25, 0.5, 0.75}")
        n, x = int(start), int(t)
        numerator = float(n)
        denominator = float(x)
        for factor in range(n - 1, n - x, -1):
            numerator *= factor
        for factor in range(1, x):
            denominator *= factor
        expected_probability = ((numerator / denominator) * math.pow(end, x)
                                * math.pow(1.0 - end, n - x))
        if abs(expected - expected_probability) > tolerance:
            raise ValueError("binomial_dist expected result must match the source nCr and exact-success formula")
    elif algorithm == "orbital_capture_radii":
        valid = (1.0e-6 <= start <= 1.0e10 and 0.0 <= end <= 2.0e30
                 and 1.0e6 <= t <= 299792458.0)
        if not valid:
            if expected != -1e300:
                raise ValueError("invalid orbital_capture_radii inputs must use the -1e300 result sentinel")
        else:
            escape_velocity_squared = (2.0 * 6.67430e-11 * end) / start
            source_result = float(round(start * math.sqrt(1.0 + escape_velocity_squared / (t * t)), 0))
            if abs(expected - source_result) > tolerance * max(1.0, abs(start), abs(end)):
                raise ValueError("orbital_capture_radii expected result must match the pinned capture-radius formula")
    elif algorithm == "standard_score":
        source_result = standard_score_expected(start, end, t)
        if source_result == STANDARD_SCORE_INVALID_RESULT:
            if expected != STANDARD_SCORE_INVALID_RESULT:
                raise ValueError("invalid standard_score inputs must use the -1e300 result sentinel")
        elif expected == STANDARD_SCORE_INVALID_RESULT or abs(expected - source_result) > tolerance * max(
                1.0, abs(start), abs(end)):
            raise ValueError("standard_score expected result must match (value - mean) / stdDev")
    elif algorithm == "dual_number_automatic_differentiation":
        valid = (-1.0 <= start <= 1.0 and end.is_integer() and 0.0 <= end <= 8.0
                 and t.is_integer() and 0.0 <= t <= end)
        source_result = dual_number_ad_expected(start, end, t)
        if not valid:
            if expected != DUAL_NUMBER_AD_INVALID_RESULT:
                raise ValueError("invalid dual-number inputs must use the -1e300 result sentinel")
        elif expected == DUAL_NUMBER_AD_INVALID_RESULT or abs(expected - source_result) > tolerance * max(
                1.0, abs(start), abs(end)):
            raise ValueError("dual-number expected result must match the bounded power derivative")
    elif algorithm == "improved_perlin_noise_3d":
        source_result = improved_perlin_noise_3d_expected([start, end, t])
        if (not -1_000_000.0 <= start <= 1_000_000.0
                or not -1_000_000.0 <= end <= 1_000_000.0
                or not -1_000_000.0 <= t <= 1_000_000.0):
            if expected != -1.0:
                raise ValueError("invalid improved_perlin_noise_3d inputs must use the -1 result sentinel")
        elif abs(expected - source_result) > tolerance * max(1.0, abs(start), abs(end), abs(t)):
            raise ValueError("improved_perlin_noise_3d expected result must match the pinned gradient-noise kernel")
    else:
        raise ValueError(f"unsupported float64_triple algorithm: {algorithm}")
    if not math.isfinite(tolerance) or tolerance <= 0.0:
        raise ValueError("relative tolerance must be positive and finite")
    return start, end, t, float(expected)


def matches(observed: float, expected: float, tolerance: float, start: float, end: float) -> bool:
    scale = max(1.0, abs(start), abs(end))
    return math.isfinite(observed) and abs(observed - expected) <= tolerance * scale


def matches_output_relative(observed: float, expected: float, tolerance: float) -> bool:
    if not math.isfinite(observed) or not math.isfinite(expected):
        return False
    if expected == -1e300:
        return observed == expected
    if expected == 0.0:
        return observed == 0.0
    return abs(observed - expected) <= tolerance * abs(expected)


def input_scaled_tolerance_for_output(tolerance: float, expected: float,
                                     start: float, end: float) -> float:
    """Encode output-relative tolerance for the shared input-scaled C harness."""
    if expected == -1e300 or expected == 0.0:
        return 0.0
    input_scale = max(1.0, abs(start), abs(end))
    return (tolerance * abs(expected)) / input_scale


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
    if algorithm == "ordinary_annuity_future_value":
        tolerance_metadata = workload.get("input", {})
        absolute_tolerance = float(tolerance_metadata.get("absolute_tolerance", 1e-12))
        relative_tolerance = float(tolerance_metadata.get("relative_tolerance", 1e-12))
        if (not math.isfinite(absolute_tolerance) or absolute_tolerance < 0.0
                or not math.isfinite(relative_tolerance) or relative_tolerance < 0.0):
            parser.error("ordinary_annuity_future_value tolerances must be finite and nonnegative")
        tolerance = None
    elif algorithm == "weight":
        tolerance = float(timing["output_relative_tolerance"])
    else:
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
        case_tolerance = tolerance
        if algorithm == "ordinary_annuity_future_value":
            case_values = case["input_values"]
            expected_value = float(case["expected_result"])
            input_scale = max(1.0, abs(float(case_values[0])), abs(float(case_values[1])))
            output_tolerance = (absolute_tolerance if expected_value == -1e300 else
                                absolute_tolerance + relative_tolerance * abs(expected_value))
            case_tolerance = output_tolerance / input_scale
        start, end, t, expected = encode_case(case, case_tolerance, algorithm)
        runner_tolerance = (input_scaled_tolerance_for_output(case_tolerance, expected, start, end)
                            if algorithm == "weight" else tolerance)
        command = [str(executable), *(format(value, ".17g") for value in
                                      (start, end, t, expected, runner_tolerance)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"float64 triple runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        observed = float(raw["observed_result"])
        result_matches = (matches_output_relative(observed, expected, case_tolerance)
                          if algorithm == "weight" else
                          matches(observed, expected, tolerance, start, end))
        if not result_matches or len(raw["samples_ns"]) != samples:
            raise ValueError(f"float64 triple runner returned an invalid result for {case['id']}")
        tolerance_record = ({"result_output_relative_tolerance": case_tolerance}
                            if algorithm == "weight" else
                            {"result_input_scaled_tolerance": case_tolerance})
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
                                        **tolerance_record}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
