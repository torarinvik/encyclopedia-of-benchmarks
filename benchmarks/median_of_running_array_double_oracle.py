"""Oracle for the bounded Java double-valued running median."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_SAMPLE = -1_000_000.0
MAX_SAMPLE = 1_000_000.0
MIN_SAMPLE_COUNT = 1
MAX_SAMPLE_COUNT = 64
MAX_VALID_INPUT_LENGTH = 1 + MAX_SAMPLE_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_ELEMENTS = MAX_SAMPLE_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _java_double_order_key(value: float) -> tuple[float, int]:
    """Order finite doubles like Java Double.compare, including signed zero."""
    if value == 0.0:
        return value, 0 if math.copysign(1.0, value) < 0.0 else 1
    return value, 0


def _median_of_prefix(samples: Sequence[float]) -> float:
    """Return one sorted-prefix median using the Java Double average expression."""
    ordered = sorted(samples, key=_java_double_order_key)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return (ordered[middle - 1] + ordered[middle]) / 2.0


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return each running median or the documented float64 slice-I/O error."""
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
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, []
    if any(type(value) not in (int, float) for value in values):
        return INVALID_RESULT, []
    numbers = [float(value) for value in values]
    if any(not math.isfinite(value) for value in numbers):
        return INVALID_RESULT, []

    raw_count = numbers[0]
    if not raw_count.is_integer():
        return INVALID_RESULT, []
    sample_count = int(raw_count)
    if not MIN_SAMPLE_COUNT <= sample_count <= MAX_SAMPLE_COUNT:
        return INVALID_RESULT, []
    if len(numbers) != 1 + sample_count:
        return INVALID_RESULT, []
    samples = numbers[1:]
    if any(not MIN_SAMPLE <= sample <= MAX_SAMPLE for sample in samples):
        return INVALID_RESULT, []

    prefix: list[float] = []
    output: list[float] = []
    for sample in samples:
        prefix.append(sample)
        output.append(_median_of_prefix(prefix))
    if output_is_null or (output_capacity is not None and output_capacity < sample_count):
        return OUTPUT_ERROR, []
    return sample_count, output
