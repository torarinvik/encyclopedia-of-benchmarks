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

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_INPUT_LENGTH = 4096


def encode_case(case: dict, algorithm: str) -> tuple[list[int], float]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(expected) not in (int, float) or not math.isfinite(expected)):
        raise ValueError("array-float64 cases require up to 4096 signed 64-bit values and a finite result")
    if algorithm == "treynor_ratio":
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
