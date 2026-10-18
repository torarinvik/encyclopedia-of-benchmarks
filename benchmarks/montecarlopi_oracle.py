"""Oracle for the deterministic input-sample form of Go MonteCarloPi."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_RANDOM_POINTS = 1
MAX_RANDOM_POINTS = 64
SAMPLE_COORDINATE_LEVELS = frozenset((0.0, 0.25, 0.5, 0.75))
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_RANDOM_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
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
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    random_points = _exact_integer(values[0])
    if (random_points is None
            or not MIN_RANDOM_POINTS <= random_points <= MAX_RANDOM_POINTS
            or len(values) != 1 + 2 * random_points):
        return None

    samples: list[tuple[float, float]] = []
    for offset in range(1, len(values), 2):
        x = _finite_number(values[offset])
        y = _finite_number(values[offset + 1])
        if (x is None or y is None
                or x not in SAMPLE_COORDINATE_LEVELS
                or y not in SAMPLE_COORDINATE_LEVELS):
            return None
        samples.append((x, y))
    return random_points, samples


def _estimate(samples: Sequence[tuple[float, float]]) -> float:
    inside = 0
    for x, y in samples:
        if x * x + y * y <= 1.0:
            inside += 1
    return float(inside) / float(len(samples)) * 4.0


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return the sample-based estimate or the documented ABI error."""
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
    _, samples = decoded
    result = _estimate(samples)
    if not math.isfinite(result):
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < MAX_OUTPUT_ELEMENTS
    ):
        return OUTPUT_ERROR, []
    return MAX_OUTPUT_ELEMENTS, [result]
