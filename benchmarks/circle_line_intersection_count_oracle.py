"""Exact squared-distance oracle for circle-line intersection counts."""

from __future__ import annotations

import struct

MAX_Q = 32
MAX_COORD = 1000
MAX_RADIUS = 1000
MAX_NORMAL = 100
MAX_OFFSET = 200000
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _parse(values, input_length=None, input_is_null=False):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 4
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    center_x, center_y, radius, count = values[:4]
    if not (-MAX_COORD <= center_x <= MAX_COORD and -MAX_COORD <= center_y <= MAX_COORD
            and 0 <= radius <= MAX_RADIUS and 0 <= count <= MAX_Q):
        return None
    if input_length != 4 + 3 * count:
        return None
    lines = []
    cursor = 4
    for _ in range(count):
        a, b, c = values[cursor:cursor + 3]
        cursor += 3
        if (not -MAX_NORMAL <= a <= MAX_NORMAL or not -MAX_NORMAL <= b <= MAX_NORMAL
                or (a == 0 and b == 0) or not -MAX_OFFSET <= c <= MAX_OFFSET):
            return None
        lines.append((a, b, c))
    return center_x, center_y, radius, lines


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    center_x, center_y, radius, lines = parsed
    required = 8 * len(lines)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""

    answers = []
    for a, b, c in lines:
        translated_offset = a * center_x + b * center_y + c
        discriminant = radius * radius * (a * a + b * b) - translated_offset * translated_offset
        answers.append(2 if discriminant > 0 else 1 if discriminant == 0 else 0)
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
