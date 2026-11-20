"""DCT-I / Chebyshev-integral reference for the bounded profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_ELEMENTS = 1
WORKSPACE_ELEMENTS = 1
WORKSPACE_BYTES = 8


def _is_finite(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _input(values: Sequence[int | float], is_null: bool,
           length: int) -> tuple[int, tuple[float, ...]] | None:
    if (not isinstance(values, (tuple, list)) or type(is_null) is not bool or is_null
            or type(length) is not int or length != len(values)
            or length > MAX_PARSEABLE_INPUT_LENGTH or length < 4
            or any(not _is_finite(x) for x in values)):
        return None
    numeric_n = float(values[0])
    if not numeric_n.is_integer():
        return None
    n = int(numeric_n)
    if not 2 <= n <= 16 or n % 2 or length != n + 2:
        return None
    data = tuple(float(x) for x in values[1:])
    if len(data) != n + 1 or any(abs(x) > 1000.0 for x in data):
        return None
    return n, data


def _integrate_chebyshev_series(n: int, samples: tuple[float, ...]) -> float:
    coefficients = [0.0] * (n + 1)
    for degree in range(n + 1):
        projection = 0.5 * samples[0]
        for k in range(1, n):
            angle = (float(degree * k) * math.pi) / float(n)
            projection += samples[k] * math.cos(angle)
        endpoint_angle = float(degree) * math.pi
        projection += 0.5 * samples[n] * math.cos(endpoint_angle)
        coefficients[degree] = (2.0 / float(n)) * projection

    result = coefficients[0]
    for degree in range(2, n, 2):
        result += (2.0 * coefficients[degree]) / (1.0 - float(degree * degree))
    result += coefficients[n] / (1.0 - float(n * n))
    return result


def expected_output(values: Sequence[int | float], capacity: int | None = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    actual_length = (len(values) if input_length is None
                     and isinstance(values, (list, tuple)) else input_length)
    if actual_length is None:
        return INVALID_RESULT, ()
    parsed = _input(values, input_is_null, actual_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_ELEMENTS):
        return OUTPUT_ERROR, ()
    value = _integrate_chebyshev_series(*parsed)
    return (1, (value,)) if math.isfinite(value) else (INVALID_RESULT, ())
