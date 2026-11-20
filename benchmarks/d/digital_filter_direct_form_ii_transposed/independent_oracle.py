"""Direct difference-equation reference with input/output histories."""

from __future__ import annotations

import struct
from collections.abc import Sequence

try:
    from .primary_oracle import INVALID_RESULT, OUTPUT_ERROR, MAX_ORDER, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_SAMPLES
except ImportError:
    from primary_oracle import INVALID_RESULT, OUTPUT_ERROR, MAX_ORDER, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_SAMPLES


def _parse(values: Sequence[int], input_is_null: bool, input_length: int):
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, order = values[:2]
    if type(n) is not int or type(order) is not int or not 0 <= n <= MAX_SAMPLES or not 0 <= order <= MAX_ORDER:
        return None
    if input_length != n + 2 * order + 4:
        return None
    split_a = 2 + order + 1
    split_b = split_a + order + 1
    a = tuple(values[2:split_a])
    b = tuple(values[split_a:split_b])
    x = tuple(values[split_b:])
    if len(a) != order + 1 or len(b) != order + 1 or len(x) != n or a[0] != 1:
        return None
    if any(not -1 <= item <= 1 for item in a[1:] + b) or any(not -16 <= item <= 16 for item in x):
        return None
    return order, a, b, x


def _filter(parsed) -> tuple[int, ...]:
    order, denominator, numerator, samples = parsed
    output: list[int] = []
    for index, sample in enumerate(samples):
        value = 0
        for lag in range(min(order, index) + 1):
            value += numerator[lag] * samples[index - lag]
        for lag in range(1, min(order, index) + 1):
            value -= denominator[lag] * output[index - lag]
        output.append(value)
    return tuple(output)


def expected_output(values: Sequence[int], capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_length = (len(values) if input_length is None and isinstance(values, (tuple, list))
                     else input_length)
    if actual_length is None:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, actual_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    required = len(parsed[3]) * 8
    if required > 0 and (output_is_null or (capacity is not None and capacity < required)):
        return OUTPUT_ERROR, b""
    return required, b"".join(struct.pack("<q", value) for value in _filter(parsed))
