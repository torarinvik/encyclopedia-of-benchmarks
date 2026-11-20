"""Independent stack oracle for every balanced-parenthesis mate position."""

from __future__ import annotations

import struct

MAX_PAIRS = 32
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_PAIRS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_PAIRS)
WORKSPACE_BYTES = 8192


def _parse(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not 1 <= values[0] <= MAX_PAIRS:
        return None
    count = 2 * values[0]
    if len(values) != count + 1:
        return None
    bits = list(values[1:])
    if any(value not in (0, 1) for value in bits):
        return None
    return bits


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    bits = _parse(values, input_is_null, input_length)
    if bits is None or type(output_is_null) is not bool:
        return -1, b""
    required = 8 * (1 + len(bits))
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < required)):
        return -2, b""
    stack = []
    mates = [-1] * len(bits)
    for position, bit in enumerate(bits):
        if bit == 1:
            stack.append(position)
        elif not stack:
            return -1, b""
        else:
            opening = stack.pop()
            mates[opening] = position
            mates[position] = opening
    if stack:
        return -1, b""
    words = [len(bits), *mates]
    return required, b"".join(struct.pack("<q", word) for word in words)


def expected_result(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return expected_output(values, output_capacity, output_is_null,
                          input_is_null, input_length)[0]
