"""Independent flat-sequence oracle for the bounded VArray contract."""

from __future__ import annotations

import struct

BAD = -1
NO_OUTPUT = -2
N_LIMIT = 321
Q_LIMIT = 256
INPUT_LIMIT = 580
OUTPUT_LIMIT = 2056


def _simulate(data, input_length, input_null):
    if (type(input_null) is not bool or input_null
            or not isinstance(data, (list, tuple))
            or not 2 <= len(data) <= INPUT_LIMIT
            or any(type(item) is not int or item < -(1 << 63) or item >= 1 << 63
                   for item in data)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(data))):
        return None
    n, q = data[0], data[1]
    if not 0 <= n <= N_LIMIT or not 0 <= q <= Q_LIMIT:
        return None
    if len(data) != 2 + n + q or (n == 0 and q != 0):
        return None
    sequence = list(data[2:2 + n])
    answers = [q]
    for index in data[2 + n:]:
        if not 0 <= index < len(sequence):
            return None
        answers.append(sequence[index])
    return answers


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return BAD, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
