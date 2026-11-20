"""Binary64 inverse-difference reference for Thiele rational interpolation."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_N = 1
MAX_N = 6
MAX_VALID_INPUT_LENGTH = 14
MAX_PARSEABLE_INPUT_LENGTH = 15
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 1e-8
RELATIVE_TOLERANCE = 1e-12
GRID_DENOMINATOR = 18_014_398_509_481_984
MIN_NODE_SEPARATION = 1.0 / 16.0
MIN_DENOMINATOR_MAGNITUDE = 1.0 / 32.0
MAX_INTERMEDIATE_MAGNITUDE = 64.0
BOUNDARY_GUARD = 1.0 / 4_294_967_296


def _valid_scalar(value: object) -> bool:
    if type(value) is int:
        return -8 <= value <= 8
    if type(value) is not float or not math.isfinite(value) or not -8.0 <= value <= 8.0:
        return False
    return (value * GRID_DENOMINATOR).is_integer()


def _parse(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[list[float], list[float], float] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(not _valid_scalar(value) for value in values)):
        return None
    raw_n = float(values[0]) if values else math.nan
    if not raw_n.is_integer() or not MIN_N <= raw_n <= MAX_N:
        return None
    n = int(raw_n)
    if input_length != 2 + 2 * n:
        return None
    xs: list[float] = []
    ys: list[float] = []
    for index in range(n):
        x = float(values[1 + 2 * index])
        y = float(values[2 + 2 * index])
        if not (-8.0 <= x <= 8.0 and -8.0 <= y <= 8.0):
            return None
        if any(abs(x - previous) < MIN_NODE_SEPARATION for previous in xs):
            return None
        xs.append(x)
        ys.append(y)
    query = float(values[-1])
    if not -8.0 <= query <= 8.0:
        return None
    return xs, ys, query


def _thiele_evaluate(xs: list[float], ys: list[float], query: float) -> float | None:
    n = len(xs)
    differences = [[0.0] * n for _ in range(n)]
    differences[0][:] = ys
    for order in range(1, n):
        for endpoint in range(order, n):
            denominator = differences[order - 1][order - 1] - differences[order - 1][endpoint]
            if (not math.isfinite(denominator)
                    or not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(denominator)
                    < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD):
                return None
            try:
                value = (xs[order - 1] - xs[endpoint]) / denominator
            except (OverflowError, ZeroDivisionError):
                return None
            if not math.isfinite(value) or abs(value) >= MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD:
                return None
            differences[order][endpoint] = value
        if not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(differences[order][order]) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD:
            return None

    for index, node in enumerate(xs):
        if query == node:
            return ys[index]
    if n == 1:
        return ys[0]

    tail = differences[n - 1][n - 1]
    for order in range(n - 2, 0, -1):
        if (not math.isfinite(tail)
                or not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(tail)
                < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD):
            return None
        try:
            tail = differences[order][order] + (query - xs[order]) / tail
        except (OverflowError, ZeroDivisionError):
            return None
        if (not math.isfinite(tail)
                or not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(tail)
                < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD):
            return None
    if not MIN_DENOMINATOR_MAGNITUDE + BOUNDARY_GUARD < abs(tail) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD:
        return None
    try:
        value = ys[0] + (query - xs[0]) / tail
    except (OverflowError, ZeroDivisionError):
        return None
    return value if (math.isfinite(value)
                     and abs(value) < MAX_INTERMEDIATE_MAGNITUDE - BOUNDARY_GUARD) else None


def expected_output(values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    xs, ys, query = parsed
    result = _thiele_evaluate(xs, ys, query)
    if result is None:
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    return 1, (result,)
