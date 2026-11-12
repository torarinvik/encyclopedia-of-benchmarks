"""Rational-slope quadrant keys as an independent exact ordering oracle."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

try:
    from .primary_oracle import (
        COORD_LIMIT, I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, OUTPUT_ERROR,
    )
except ImportError:
    from primary_oracle import (
        COORD_LIMIT, I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, OUTPUT_ERROR,
    )


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    points = [(values[i], values[i + 1]) for i in range(1, len(values), 2)]
    if any(abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT for x, y in points):
        return None
    return points


def _key(point: tuple[int, int]):
    x, y = point
    if y < 0 and x < 0:
        sector, slope = 0, Fraction(y, x)
    elif y < 0 and x == 0:
        sector, slope = 1, Fraction(0, 1)
    elif y < 0:
        sector, slope = 2, Fraction(y, x)
    elif y == 0 and x >= 0:
        sector, slope = 3, Fraction(0, 1)
    elif y > 0 and x > 0:
        sector, slope = 4, Fraction(y, x)
    elif y > 0 and x == 0:
        sector, slope = 5, Fraction(0, 1)
    elif y > 0:
        sector, slope = 6, Fraction(y, x)
    else:
        sector, slope = 7, Fraction(0, 1)
    return sector, slope, x * x + y * y, x, y


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    required = 16 * len(points)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    flattened = (coordinate for point in sorted(points, key=_key) for coordinate in point)
    return required, b"".join(struct.pack("<q", value) for value in flattened)
