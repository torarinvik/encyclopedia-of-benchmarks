"""Primary mobile-element simulation of Steinhaus–Johnson–Trotter."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 3
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 144


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return None
    return values[0]


def _payload(n: int) -> bytes:
    permutation = list(range(1, n + 1))
    direction = [-1] * (n + 1)  # -1 points left; +1 points right.
    rows: list[int] = []
    while True:
        rows.extend(permutation)
        mobile_value = 0
        mobile_position = -1
        for position, value in enumerate(permutation):
            neighbor = position + direction[value]
            if 0 <= neighbor < n and value > permutation[neighbor] and value > mobile_value:
                mobile_value, mobile_position = value, position
        if mobile_position < 0:
            break
        neighbor = mobile_position + direction[mobile_value]
        permutation[mobile_position], permutation[neighbor] = permutation[neighbor], permutation[mobile_position]
        for value in range(mobile_value + 1, n + 1):
            direction[value] *= -1
    return struct.pack("<" + "q" * len(rows), *rows)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    n = _decode(values)
    if n is None:
        return -1, b""
    payload = _payload(n)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
