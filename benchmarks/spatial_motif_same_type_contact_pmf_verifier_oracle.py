"""Independent verifier oracle by enumerating fixed-cardinality position sets."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 3


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and len(values) != input_length:
        return -1, b""
    if len(values) != 3 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    length, x1, x2 = values
    if not 1 <= length <= 16 or not 0 <= x1 <= length or not 0 <= x2 <= length:
        return -1, b""

    first_positions = (1 << x1) - 1
    counts = [0] * (length + 1)
    denominator = 0
    for second_positions in range(1 << length):
        if second_positions.bit_count() == x2:
            denominator += 1
            contacts = (second_positions & first_positions).bit_count()
            counts[contacts] += 1
    low = max(0, x1 + x2 - length)
    high = min(x1, x2)
    expected_numerator, expected_denominator = x1 * x2, length
    divisor = math.gcd(expected_numerator, expected_denominator)
    expected_numerator //= divisor
    expected_denominator //= divisor
    words = [low, high, denominator, *counts[low:high + 1], expected_numerator, expected_denominator]
    payload = b"".join(struct.pack("<q", value) for value in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
