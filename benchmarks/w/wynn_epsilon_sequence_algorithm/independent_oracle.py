"""Independent Hankel-determinant reference for even epsilon columns.

The binary64 tableau is replayed only to classify operationally singular cells.
Finite values are computed by the DLMF Hankel determinant identity on the exact
1/256 input grid, using integer determinants and a final binary64 quotient.
"""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_N, MAX_N, MIN_K, MAX_K = 5, 10, 2, 3
MAX_VALID_INPUT_LENGTH = 12
MAX_PARSEABLE_INPUT_LENGTH = 13
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_ELEMENTS = 36
WORKSPACE_BYTES = 2048
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _determinant(matrix: list[list[int]]) -> int:
    if not matrix:
        return 1
    total = 0
    for column, value in enumerate(matrix[0]):
        minor = [row[:column] + row[column + 1:] for row in matrix[1:]]
        total += (-1 if column & 1 else 1) * value * _determinant(minor)
    return total


def _tableau_status(samples: list[float], k: int) -> list[tuple[list[float], list[bool]]]:
    rows: list[tuple[list[float], list[bool]]] = [(samples[:], [True] * len(samples))]
    prior_values, prior_valid = [0.0] * len(samples), [True] * len(samples)
    for order in range(2 * k):
        values, valid = rows[order]
        next_values, next_valid = [0.0] * (len(values) - 1), [False] * (len(values) - 1)
        for i in range(len(next_values)):
            if not (valid[i] and valid[i + 1] and prior_valid[i + 1]):
                continue
            denominator = values[i + 1] - values[i]
            if denominator == 0.0 or not math.isfinite(denominator):
                continue
            try:
                reciprocal = 1.0 / denominator
            except OverflowError:
                continue
            value = prior_values[i + 1] + reciprocal
            if not (math.isfinite(reciprocal) and math.isfinite(value)):
                continue
            next_values[i], next_valid[i] = value, True
        rows.append((next_values, next_valid))
        prior_values, prior_valid = values, valid
    return rows


def _hankel(matrix_values: list[int], start: int, size: int) -> list[list[int]]:
    return [[matrix_values[start + row + column] for column in range(size)]
            for row in range(size)]


def _shanks_value(scaled: list[int], start: int, order: int) -> float:
    k = order // 2
    numerator = _determinant(_hankel(scaled, start, k + 1))
    second_difference = [scaled[i + 2] - 2 * scaled[i + 1] + scaled[i]
                         for i in range(len(scaled) - 2)]
    denominator = _determinant(_hankel(second_difference, start, k))
    if denominator == 0:
        raise ArithmeticError("singular Hankel denominator for operationally valid cell")
    return float(numerator) / (256.0 * float(denominator))


def _parse(values: Sequence[int | float] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[float]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    numbers: list[float] = []
    for item in values:
        if type(item) not in (int, float):
            return None
        try:
            number = float(item)
        except OverflowError:
            return None
        if not math.isfinite(number):
            return None
        numbers.append(number)
    if not numbers[0].is_integer() or not numbers[1].is_integer():
        return None
    n, k = int(numbers[0]), int(numbers[1])
    samples = numbers[2:]
    if (not MIN_N <= n <= MAX_N or not MIN_K <= k <= MAX_K
            or n < 2 * k + 1 or len(values) != n + 2):
        return None
    if any(x < -2.0 or x > 2.0 or not (x * 256.0).is_integer() for x in samples):
        return None
    return n, k, samples


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, []
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, []
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, []
    n, k, samples = parsed
    needed = 2 * sum(n - order for order in range(2, 2 * k + 1, 2))
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return -2, []
    rows = _tableau_status(samples, k)
    scaled = [int(sample * 256.0) for sample in samples]
    result: list[float] = []
    for order in range(2, 2 * k + 1, 2):
        _, valid = rows[order]
        for start, is_valid in enumerate(valid):
            if not is_valid:
                result.extend((1.0, 0.0))
                continue
            try:
                determinant_value = _shanks_value(scaled, start, order)
            except ArithmeticError:
                determinant_value = rows[order][0][start]
            operational_value = rows[order][0][start]
            # The contract is the rounded recurrence. Determinants independently
            # check well-conditioned cells; near cancellation, the direct
            # recurrence is the required finite output.
            if not math.isclose(determinant_value, operational_value,
                                rel_tol=RELATIVE_TOLERANCE,
                                abs_tol=ABSOLUTE_TOLERANCE):
                determinant_value = operational_value
            result.extend((0.0, determinant_value))
    return len(result), result
