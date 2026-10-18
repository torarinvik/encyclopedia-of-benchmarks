"""Oracle for the bounded TheAlgorithms C/C++ spirograph workload."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_POINTS = 1
MAX_POINTS = 32
MIN_MARKER_RATIO = 0.0
MAX_MARKER_RATIO = 1.0
MIN_INNER_RATIO = 0.25
MAX_INNER_RATIO = 0.75
MIN_ROTATIONS = 0.0
MAX_ROTATIONS = 10.0
MAX_VALID_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_OUTPUT_ELEMENTS = 2 * MAX_POINTS
ABSOLUTE_TOLERANCE = 1e-10
RELATIVE_TOLERANCE = 0.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: int | float) -> float | None:
    if type(value) not in (int, float):
        return None
    try:
        number = float(value)
    except OverflowError:
        return None
    return number if math.isfinite(number) else None


def _exact_integer(value: int | float) -> int | None:
    number = _finite_number(value)
    if number is None or not number.is_integer():
        return None
    return int(number)


def _decode_input(values: Sequence[float] | None):
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None

    point_count = _exact_integer(values[0])
    marker_ratio = _finite_number(values[1])
    inner_ratio = _finite_number(values[2])
    rotations = _finite_number(values[3])
    if (point_count is None or not MIN_POINTS <= point_count <= MAX_POINTS
            or marker_ratio is None
            or not MIN_MARKER_RATIO <= marker_ratio <= MAX_MARKER_RATIO
            or inner_ratio is None
            or not MIN_INNER_RATIO <= inner_ratio <= MAX_INNER_RATIO
            or rotations is None
            or not MIN_ROTATIONS <= rotations <= MAX_ROTATIONS):
        return None
    return point_count, marker_ratio, inner_ratio, rotations


def _points(
    point_count: int, marker_ratio: float, inner_ratio: float, rotations: float
) -> list[float] | None:
    delta = rotations * 2.0 * math.pi / point_count
    k1 = 1.0 - inner_ratio
    output: list[float] = []
    for index in range(point_count):
        # The C++ pins compute this product per index. The C pin accumulates
        # delta starting at zero; the workload tolerance admits that rounding
        # difference while keeping the shared mathematical operation fixed.
        t = delta * index
        inner_angle = k1 * t / inner_ratio
        x = k1 * math.cos(t) + marker_ratio * inner_ratio * math.cos(inner_angle)
        y = k1 * math.sin(t) - marker_ratio * inner_ratio * math.sin(inner_angle)
        if not math.isfinite(x) or not math.isfinite(y):
            return None
        output.extend((x, y))
    return output


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return interleaved coordinates or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    point_count, marker_ratio, inner_ratio, rotations = decoded
    output = _points(point_count, marker_ratio, inner_ratio, rotations)
    if output is None:
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, []
    return len(output), output
