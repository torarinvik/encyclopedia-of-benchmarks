"""Oracle for the pinned C# PInv method on deterministic one-column inputs."""

from __future__ import annotations

import math
from collections.abc import Sequence


MAX_ROWS = 4
MAX_INPUT_LENGTH = 2 + MAX_ROWS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = 2 + MAX_ROWS
SINGULAR_VALUE_CUTOFF = 1e-4
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_float(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    try:
        result = float(value)
    except OverflowError:
        return None
    return result if math.isfinite(result) else None


def _integer(value: float, low: int, high: int) -> int | None:
    if value < low or value > high or value != math.trunc(value):
        return None
    return int(value)


def expected_output(
    values: Sequence[object] | None,
    *,
    input_length: int | None = None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, list[float]]:
    if not isinstance(input_is_null, bool) or not isinstance(output_is_null, bool):
        return INVALID_RESULT, []
    if input_is_null or values is None:
        return INVALID_RESULT, []
    if input_length is None:
        input_length = len(values)
    if (
        isinstance(input_length, bool)
        or not isinstance(input_length, int)
        or input_length < 0
        or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT, []
    if output_capacity is not None and (
        isinstance(output_capacity, bool)
        or not isinstance(output_capacity, int)
        or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length != len(values) or input_length < 3:
        return INVALID_RESULT, []

    parsed = [_finite_float(value) for value in values]
    if any(value is None for value in parsed):
        return INVALID_RESULT, []
    data = [float(value) for value in parsed]
    row_count = _integer(data[0], 1, MAX_ROWS)
    column_count = _integer(data[1], 1, 1)
    if row_count is None or column_count is None:
        return INVALID_RESULT, []
    if input_length != 2 + row_count * column_count or input_length > MAX_INPUT_LENGTH:
        return INVALID_RESULT, []

    column = data[2:]
    if any(value < -4.0 or value > 4.0 or value != math.trunc(value) for value in column):
        return INVALID_RESULT, []
    squared_norm = sum(value * value for value in column)
    singular_value = math.sqrt(squared_norm)
    if abs(singular_value) < SINGULAR_VALUE_CUTOFF:
        projected = [0.0] * row_count
    else:
        projected = [value / squared_norm for value in column]
    output = [1.0, float(row_count), *projected]
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output


def expected_result(values: Sequence[object] | None) -> tuple[int, list[float]]:
    """Return the ABI result and output for one complete input array."""
    return expected_output(values)
