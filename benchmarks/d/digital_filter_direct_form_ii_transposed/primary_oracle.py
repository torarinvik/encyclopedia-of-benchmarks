"""Transposed Direct Form II state-chain reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_SAMPLES = 32
MAX_ORDER = 4
MAX_VALID_INPUT_LENGTH = 44
MAX_PARSEABLE_INPUT_LENGTH = 45
MAX_OUTPUT_BYTES = MAX_SAMPLES * 8
WORKSPACE_BYTES = 256


def _parse(values: Sequence[int], input_is_null: bool, input_length: int):
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    sample_count, order = values[0], values[1]
    if not 0 <= sample_count <= MAX_SAMPLES or not 0 <= order <= MAX_ORDER:
        return None
    if input_length != sample_count + 2 * order + 4:
        return None
    denominator = tuple(values[2:order + 3])
    numerator = tuple(values[order + 3:2 * order + 4])
    samples = tuple(values[2 * order + 4:])
    if len(denominator) != order + 1 or len(numerator) != order + 1 or len(samples) != sample_count:
        return None
    if denominator[0] != 1:
        return None
    if any(not -1 <= coefficient <= 1 for coefficient in denominator[1:] + numerator):
        return None
    if any(not -16 <= sample <= 16 for sample in samples):
        return None
    return order, denominator, numerator, samples


def _filter(parsed) -> tuple[int, ...]:
    order, denominator, numerator, samples = parsed
    state = [0] * order
    output: list[int] = []
    for sample in samples:
        value = numerator[0] * sample + (state[0] if order else 0)
        output.append(value)
        # Ascending order reads each still-unmodified next state before replacing it.
        for stage in range(order):
            next_state = state[stage + 1] if stage + 1 < order else 0
            state[stage] = (next_state + numerator[stage + 1] * sample
                            - denominator[stage + 1] * value)
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
