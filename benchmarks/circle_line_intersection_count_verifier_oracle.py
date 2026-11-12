"""Independent line-parameter quadratic oracle for intersection counts."""

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


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 4
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return -1, b""
    center_x, center_y, radius, count = values[:4]
    if (not -MAX_COORD <= center_x <= MAX_COORD or not -MAX_COORD <= center_y <= MAX_COORD
            or not 0 <= radius <= MAX_RADIUS or not 0 <= count <= MAX_Q
            or len(values) != 4 + 3 * count):
        return -1, b""
    lines = []
    for query in range(count):
        a, b, c = values[4 + 3 * query:7 + 3 * query]
        if (not -MAX_NORMAL <= a <= MAX_NORMAL or not -MAX_NORMAL <= b <= MAX_NORMAL
                or (a == 0 and b == 0) or not -MAX_OFFSET <= c <= MAX_OFFSET):
            return -1, b""
        lines.append((a, b, c))

    required = 8 * count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""

    answers = []
    for a, b, c in lines:
        offset = a * center_x + b * center_y + c
        if b != 0:
            # Substitute v=-(a*u+offset)/b into u²+v²=r².
            quadratic_a = a * a + b * b
            quadratic_b = 2 * a * offset
            quadratic_c = offset * offset - b * b * radius * radius
            discriminant = quadratic_b * quadratic_b - 4 * quadratic_a * quadratic_c
            answers.append(2 if discriminant > 0 else 1 if discriminant == 0 else 0)
        else:
            # For a vertical line, u is fixed and the remaining equation is in v².
            vertical_slack = a * a * radius * radius - offset * offset
            answers.append(2 if vertical_slack > 0 else 1 if vertical_slack == 0 else 0)
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
