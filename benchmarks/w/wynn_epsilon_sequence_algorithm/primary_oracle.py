"""Operational binary64 reference for the bounded Wynn epsilon tableau."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_N = 5
MAX_N = 10
MIN_K = 2
MAX_K = 3
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_ELEMENTS = 36
WORKSPACE_BYTES = 2048
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _parse(values: Sequence[int | float] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[float]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except OverflowError:
            return None
        if not math.isfinite(number):
            return None
        converted.append(number)
    n_value, k_value = converted[0], converted[1]
    if not n_value.is_integer() or not k_value.is_integer():
        return None
    n, k = int(n_value), int(k_value)
    if not MIN_N <= n <= MAX_N or not MIN_K <= k <= MAX_K:
        return None
    if n < 2 * k + 1 or len(values) != n + 2:
        return None
    samples = converted[2:]
    for sample in samples:
        scaled = sample * 256.0
        if sample < -2.0 or sample > 2.0 or not scaled.is_integer():
            return None
    return n, k, samples


def _tableau(samples: list[float], k: int) -> list[tuple[list[float], list[bool]]]:
    """Construct rows in increasing epsilon order, with explicit validity."""
    rows: list[tuple[list[float], list[bool]]] = [
        (samples[:], [True] * len(samples))
    ]
    previous_values = [0.0] * len(samples)  # epsilon_-1
    previous_valid = [True] * len(samples)
    for order in range(0, 2 * k):
        current_values, current_valid = rows[order]
        width = len(current_values) - 1
        next_values = [0.0] * width
        next_valid = [False] * width
        for index in range(width):
            if not (current_valid[index] and current_valid[index + 1]
                    and previous_valid[index + 1]):
                continue
            denominator = current_values[index + 1] - current_values[index]
            if denominator == 0.0 or not math.isfinite(denominator):  # includes signed zero
                continue
            try:
                reciprocal = 1.0 / denominator
            except OverflowError:
                continue
            value = previous_values[index + 1] + reciprocal
            if not (math.isfinite(reciprocal) and math.isfinite(value)):
                continue
            next_values[index] = value
            next_valid[index] = True
        rows.append((next_values, next_valid))
        previous_values, previous_valid = current_values, current_valid
    return rows


def _run(samples: list[float], k: int) -> list[float]:
    rows = _tableau(samples, k)
    result: list[float] = []
    for order in range(2, 2 * k + 1, 2):
        values, valid = rows[order]
        for value, is_valid in zip(values, valid):
            result.extend((0.0, value) if is_valid else (1.0, 0.0))
    return result


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, []
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return -1, []
    if input_length is not None and (
            type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, []
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, []
    n, k, samples = parsed
    needed = 2 * sum(n - order for order in range(2, 2 * k + 1, 2))
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return -2, []
    result = _run(samples, k)
    return len(result), result
