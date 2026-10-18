"""Bounded binary64 oracle for the pinned Julia SIR derivative function."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_OUTPUT_ELEMENTS = 3
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
MAX_POPULATION = 1_000_000.0
MAX_BETA = 0.001
MAX_K = 1.0
MAX_TIME = 140.0


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _parse_input(
    values: Sequence[int | float], input_is_null: bool, input_length: int
) -> tuple[float, float, float, float, float, float] | None:
    if (
        not isinstance(values, (list, tuple))
        or type(input_is_null) is not bool
        or type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or input_is_null and (values or input_length != 0)
        or not input_is_null and (input_length != len(values) or input_length == 0)
        or any(not _finite_number(value) for value in values)
    ):
        return None
    if input_is_null or input_length != INPUT_LENGTH:
        return None

    s, i, r, beta, k, time = (float(value) for value in values)
    if not (0.0 <= s <= MAX_POPULATION and 0.0 <= i <= MAX_POPULATION
            and 0.0 <= r <= MAX_POPULATION and 0.0 <= beta <= MAX_BETA
            and 0.0 <= k <= MAX_K and 0.0 <= time <= MAX_TIME):
        return None
    return s, i, r, beta, k, time


def _calculate(parsed: tuple[float, float, float, float, float, float]) -> tuple[float, float, float]:
    s, i, _r, beta, k, _time = parsed
    # The Julia source parses `-beta * s * i` as `((-beta) * s) * i`.
    d_s = ((-beta) * s) * i
    d_i_infection = (beta * s) * i
    d_i_recovery = k * i
    d_i = d_i_infection - d_i_recovery
    d_r = k * i
    return d_s, d_i, d_r


def expected_result(values: Sequence[int | float]) -> tuple[float, float, float] | None:
    """Return the three RHS derivatives, or None for invalid packed input."""
    if not isinstance(values, (list, tuple)):
        return None
    parsed = _parse_input(values, False, len(values))
    if parsed is None:
        return None
    return _calculate(parsed)


def expected_output(
    values: Sequence[int | float],
    output_capacity: int = MAX_OUTPUT_ELEMENTS,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Model input validation, output error precedence, and three-value result."""
    effective_length = (
        len(values)
        if input_length is None and isinstance(values, (list, tuple))
        else input_length
    )
    if (
        effective_length is None
        or type(output_capacity) is not int
        or output_capacity < 0
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
    ):
        return INVALID_RESULT, ()
    parsed = _parse_input(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if output_is_null or output_capacity < MAX_OUTPUT_ELEMENTS:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_ELEMENTS, _calculate(parsed)
